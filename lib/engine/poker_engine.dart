import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'hand_eval.dart';

/// SFX hook names the engine emits; the UI/audio layer listens.
class Sfx {
  static const shuffle = 'shuffle';
  static const deal = 'deal';
  static const chips = 'chips';
  static const check = 'check';
  static const fold = 'fold';
  static const raise = 'raise';
  static const win = 'win';
  static const lose = 'lose';
  static const reveal = 'reveal';
  static const yourTurn = 'yourturn';
  static const click = 'click';
}

enum Phase { idle, dealingHole, betting, dealingBoard, showdown, handOver, gameOver }
enum Street { preflop, flop, turn, river }

enum ActionKind { fold, check, call, raise }

/// One seat at the table.
class Seat {
  String name;
  final bool isHuman;
  int difficulty; // 0 easy, 1 medium, 2 hard (bots only)
  int stack = 0;
  List<int> hole = [];
  bool folded = false;
  bool allIn = false;
  bool eliminated = false;
  int betStreet = 0; // chips committed on the current street
  int betHand = 0; // total chips committed this hand (for side pots)
  bool isDealer = false;
  String lastAction = '';
  int lastWin = 0;
  int bestScore = -1;

  Seat({required this.name, required this.isHuman, this.difficulty = 1});
}

class SeatConfig {
  final String name;
  final bool isHuman;
  final int difficulty;
  const SeatConfig({required this.name, required this.isHuman, this.difficulty = 1});
}

class GameConfig {
  final List<SeatConfig> seats;
  final bool tournament;
  final int startingStack;
  const GameConfig({
    required this.seats,
    this.tournament = false,
    this.startingStack = 500,
  });
}

class WinInfo {
  final int seat;
  final int amount;
  final String handName;
  final bool split;
  WinInfo(this.seat, this.amount, this.handName, this.split);
}

/// Texas Hold'em engine. Owns ALL turn state and phases.
///
/// Reliability design:
/// - Exactly one engine [Timer] is ever scheduled ([_schedule] cancels the
///   previous one). Engine-driven steps always set a watchdog deadline.
/// - A periodic watchdog re-drives the current phase if its deadline passes
///   without progress. Human turns are exempt (the human may think forever)
///   but the engine never waits on a dead timer.
/// - [pause]/[resume] integrate with the app lifecycle: timers are cancelled
///   on pause and the phase is re-driven on resume.
/// - Every AI decision is narrated and delayed ("X is thinking…") — turns are
///   never silently auto-played.
class PokerEngine extends ChangeNotifier {
  final _rand = Random();

  List<Seat> seats = [];
  List<int> community = [];
  List<int> _deck = [];

  Phase phase = Phase.idle;
  Street street = Street.preflop;
  int actorIndex = -1;
  int dealerIndex = -1;
  int handNumber = 0;
  int smallBlind = 5;
  int bigBlind = 10;
  int currentBet = 0;
  int minRaise = 10;

  /// Seats that still owe action this betting round.
  final Set<int> _needsToAct = {};

  /// Narration log for the table feed (newest last).
  final List<String> narration = [];

  /// Seats whose hole cards are face-up (showdown reveals + humans).
  final Set<int> revealed = {};

  List<WinInfo> lastWins = [];
  bool humanWonGame = false;
  bool humanLostGame = false;
  int biggestPot = 0;

  /// True while the engine is waiting on a human tap.
  bool awaitingHuman = false;

  /// Bump on every visible event so the UI can key animations.
  int animTick = 0;

  /// Audio hook wired by the UI layer.
  void Function(String sfx)? onSfx;

  // ------------------------------------------------------------ timers
  Timer? _timer;
  Timer? _watchdog;
  DateTime? _deadline;
  void Function()? _resumeStep;
  bool _disposed = false;

  int get pot => seats.fold(0, (p, s) => p + s.betHand);

  String streetName() {
    switch (street) {
      case Street.preflop:
        return 'Pre-flop';
      case Street.flop:
        return 'Flop';
      case Street.turn:
        return 'Turn';
      case Street.river:
        return 'River';
    }
  }

  void _schedule(Duration d, void Function() fn,
      {bool humanWait = false, void Function()? resume}) {
    _timer?.cancel();
    _timer = null;
    awaitingHuman = humanWait;
    if (humanWait) {
      _deadline = null;
      _resumeStep = null;
    } else {
      _deadline = DateTime.now().add(d + const Duration(seconds: 6));
      _resumeStep = resume ?? fn;
    }
    _timer = Timer(d, () {
      if (_disposed) return;
      _deadline = null;
      fn();
    });
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_disposed) return;
      final dl = _deadline;
      if (dl == null || awaitingHuman) return;
      if (DateTime.now().isAfter(dl)) {
        say('The dealer taps the table… (recovering)');
        final r = _resumeStep;
        _deadline = null;
        _resumeStep = null;
        if (r != null) r();
      }
    });
  }

  /// App went to background: freeze timers, keep state.
  void pause() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
  }

  /// App returned: re-drive whatever the engine was doing.
  void resume() {
    if (_disposed || phase == Phase.idle || phase == Phase.gameOver) return;
    if (awaitingHuman) {
      notifyListeners();
      return;
    }
    final r = _resumeStep;
    _resumeStep = null;
    if (r != null) {
      _schedule(const Duration(milliseconds: 400), r);
    } else if (phase == Phase.betting) {
      _driveBetting();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------ helpers
  void say(String msg) {
    narration.add(msg);
    if (narration.length > 40) narration.removeAt(0);
    notifyListeners();
  }

  void _bump() {
    animTick++;
    notifyListeners();
  }

  List<int> _activeSeats() => [
        for (int i = 0; i < seats.length; i++)
          if (!seats[i].eliminated) i
      ];

  int _nextActive(int from) {
    final n = seats.length;
    var i = from;
    for (int k = 0; k < n; k++) {
      i = (i + 1) % n;
      if (!seats[i].eliminated) return i;
    }
    return from;
  }

  int _playersInHand() =>
      seats.where((s) => !s.eliminated && !s.folded).length;

  int _playersWhoCanAct() => seats
      .where((s) => !s.eliminated && !s.folded && !s.allIn && s.stack > 0)
      .length;

  // ------------------------------------------------------------ game flow
  void newGame(GameConfig config) {
    pause();
    seats = [
      for (final c in config.seats)
        Seat(name: c.name, isHuman: c.isHuman, difficulty: c.difficulty)
          ..stack = config.startingStack
    ];
    _tournament = config.tournament;
    community = [];
    narration.clear();
    lastWins = [];
    revealed.clear();
    humanWonGame = false;
    humanLostGame = false;
    biggestPot = 0;
    handNumber = 0;
    dealerIndex = -1;
    smallBlind = 5;
    bigBlind = 10;
    phase = Phase.idle;
    _startWatchdog();
    say('Welcome to the Lone Star table, partners! 🤠');
    say('${seats.length} riders, $smallBlind/$bigBlind blinds. May the best hand win.');
    _schedule(const Duration(milliseconds: 600), _startHand);
  }

  bool _tournament = false;

  void _startHand() {
    // Eliminate broke seats.
    for (final s in seats) {
      if (!s.eliminated && s.stack <= 0) {
        s.eliminated = true;
        if (!s.isHuman) say('${s.name} rides off into the sunset… (broke)');
      }
    }
    final active = _activeSeats();
    final humansAlive = seats.any((s) => s.isHuman && !s.eliminated);
    if (!humansAlive) {
      _endGame(false);
      return;
    }
    if (active.length < 2) {
      _endGame(true);
      return;
    }
    handNumber++;
    if (_tournament && handNumber > 1 && (handNumber - 1) % 10 == 0) {
      smallBlind *= 2;
      bigBlind *= 2;
      say('📯 Blinds rise to $smallBlind/$bigBlind! Hold onto your hats!');
    }
    dealerIndex = _nextActive(dealerIndex);
    for (int i = 0; i < seats.length; i++) {
      final s = seats[i];
      s.hole = [];
      s.folded = false;
      s.allIn = false;
      s.betStreet = 0;
      s.betHand = 0;
      s.lastAction = '';
      s.lastWin = 0;
      s.bestScore = -1;
      s.isDealer = i == dealerIndex;
    }
    community = [];
    revealed.clear();
    lastWins = [];
    _deck = Card.newDeck()..shuffle(_rand);
    onSfx?.call(Sfx.shuffle);
    say('— Hand #$handNumber — ${seats[dealerIndex].name} deals.');
    phase = Phase.dealingHole;
    _dealHoleStep(0);
  }

  void _dealHoleStep(int step) {
    final order = <int>[];
    var i = dealerIndex;
    for (int k = 0; k < seats.length; k++) {
      i = _nextActive(i);
      order.add(i);
    }
    if (step >= order.length * 2) {
      _postBlinds();
      return;
    }
    final seatIdx = order[step % order.length];
    final s = seats[seatIdx];
    if (!s.eliminated) {
      s.hole.add(_deck.removeLast());
      onSfx?.call(Sfx.deal);
      _bump();
    }
    _schedule(const Duration(milliseconds: 220), () => _dealHoleStep(step + 1));
  }

  void _postBlinds() {
    int sbIdx, bbIdx;
    if (_activeSeats().length == 2) {
      sbIdx = dealerIndex; // heads-up: button is the small blind
      bbIdx = _nextActive(dealerIndex);
    } else {
      sbIdx = _nextActive(dealerIndex);
      bbIdx = _nextActive(sbIdx);
    }
    _postBlind(sbIdx, smallBlind, 'small blind');
    _postBlind(bbIdx, bigBlind, 'big blind');
    street = Street.preflop;
    _startBettingRound(keepBlinds: true);
  }

  void _postBlind(int idx, int amount, String label) {
    final s = seats[idx];
    final pay = amount.clamp(0, s.stack);
    s.stack -= pay;
    s.betStreet += pay;
    s.betHand += pay;
    if (s.stack == 0) s.allIn = true;
    s.lastAction = 'Blind $pay';
    say('${s.name} posts the $label ($pay).');
  }

  // ------------------------------------------------------------ betting
  void _startBettingRound({bool keepBlinds = false}) {
    for (final s in seats) {
      if (!keepBlinds) {
        s.betStreet = 0;
        s.lastAction = '';
      }
    }
    // Preflop the posted blinds stay live and set the current bet, so the
    // big blind still gets their option and nobody can "check" a blind.
    currentBet =
        keepBlinds ? seats.fold(0, (m, s) => max(m, s.betStreet)) : 0;
    minRaise = bigBlind;
    _needsToAct.clear();
    for (int i = 0; i < seats.length; i++) {
      final s = seats[i];
      if (!s.eliminated && !s.folded && !s.allIn && s.stack > 0) {
        _needsToAct.add(i);
      }
    }
    phase = Phase.betting;

    // Auto-runout: fewer than two players can still act.
    if (_playersWhoCanAct() < 2) {
      say('No more bets possible — dealing it out…');
      _schedule(const Duration(milliseconds: 900), _autoRunout);
      return;
    }
    if (_playersInHand() < 2) {
      _awardUncontested();
      return;
    }
    actorIndex = _firstToAct();
    _driveBetting();
  }

  int _firstToAct() {
    var i = dealerIndex;
    if (street == Street.preflop) {
      // Left of the big blind.
      i = _nextActive(_nextActive(_activeSeats().length == 2
          ? dealerIndex
          : _nextActive(dealerIndex)));
    } else {
      i = _nextActive(dealerIndex);
    }
    // Walk to someone who can act.
    for (int k = 0; k < seats.length; k++) {
      final s = seats[i];
      if (!s.eliminated && !s.folded && !s.allIn && s.stack > 0) return i;
      i = _nextActive(i);
    }
    return i;
  }

  void _driveBetting() {
    if (phase != Phase.betting) return;
    // Remove players who can no longer act.
    _needsToAct.removeWhere((i) {
      final s = seats[i];
      return s.eliminated || s.folded || s.allIn || s.stack <= 0;
    });
    if (_needsToAct.isEmpty || _playersInHand() < 2) {
      _endBettingRound();
      return;
    }
    // Advance actorIndex to the next seat that needs to act. The current
    // actor is checked FIRST so the first-to-act seat is never skipped.
    for (int k = 0; k < seats.length; k++) {
      if (_needsToAct.contains(actorIndex)) break;
      actorIndex = _nextActive(actorIndex);
    }
    final s = seats[actorIndex];
    if (s.isHuman) {
      say('👉 ${s.name}, your move.');
      onSfx?.call(Sfx.yourTurn);
      _schedule(Duration.zero, () {}, humanWait: true);
      notifyListeners();
    } else {
      say('${s.name} is thinking… 🤔');
      notifyListeners();
      final thinkMs = 800 + _rand.nextInt(700);
      _schedule(Duration(milliseconds: thinkMs), () => _botAct(actorIndex));
    }
  }

  // ------------------------------------------------------------ actions
  bool get canCheck =>
      actorIndex >= 0 && seats[actorIndex].betStreet >= currentBet;

  int callAmount() {
    if (actorIndex < 0) return 0;
    final s = seats[actorIndex];
    return (currentBet - s.betStreet).clamp(0, s.stack);
  }

  int minRaiseTo() {
    if (actorIndex < 0) return 0;
    if (currentBet == 0) return bigBlind;
    return currentBet + minRaise;
  }

  /// Maximum total street bet the actor can raise to (bet + remaining stack).
  int maxRaiseTo() =>
      actorIndex >= 0 ? seats[actorIndex].betStreet + seats[actorIndex].stack : 0;

  /// Human action from the UI. Returns false if illegal / not their turn.
  bool humanAct(ActionKind kind, {int raiseTo = 0}) {
    if (!awaitingHuman || phase != Phase.betting) return false;
    final s = seats[actorIndex];
    if (!s.isHuman) return false;
    switch (kind) {
      case ActionKind.fold:
        return _applyFold(actorIndex);
      case ActionKind.check:
        if (!canCheck) return false;
        return _applyCheck(actorIndex);
      case ActionKind.call:
        if (canCheck) return _applyCheck(actorIndex);
        return _applyCall(actorIndex);
      case ActionKind.raise:
        final lo = minRaiseTo();
        final hi = maxRaiseTo();
        if (hi < lo) return _applyCall(actorIndex); // can't raise: call/all-in
        final target = raiseTo.clamp(lo, hi);
        return _applyRaise(actorIndex, target);
    }
  }

  bool _applyFold(int idx) {
    final s = seats[idx];
    s.folded = true;
    s.lastAction = 'Fold';
    _needsToAct.remove(idx);
    onSfx?.call(Sfx.fold);
    say('${s.name} folds. 🃏');
    _afterAction();
    return true;
  }

  bool _applyCheck(int idx) {
    final s = seats[idx];
    s.lastAction = 'Check';
    _needsToAct.remove(idx);
    onSfx?.call(Sfx.check);
    say('${s.name} checks.');
    _afterAction();
    return true;
  }

  bool _applyCall(int idx) {
    final s = seats[idx];
    var amount = (currentBet - s.betStreet).clamp(0, s.stack);
    s.stack -= amount;
    s.betStreet += amount;
    s.betHand += amount;
    if (s.stack == 0) {
      s.allIn = true;
      s.lastAction = 'All-in $amount!';
      say('🔥 ${s.name} is ALL-IN with $amount!');
    } else {
      s.lastAction = 'Call $amount';
      say('${s.name} calls $amount.');
    }
    _needsToAct.remove(idx);
    onSfx?.call(Sfx.chips);
    _afterAction();
    return true;
  }

  bool _applyRaise(int idx, int raiseTo) {
    final s = seats[idx];
    // raiseTo = total bet this street for this player.
    final add = (raiseTo - s.betStreet).clamp(0, s.stack);
    final wasBet = currentBet;
    s.stack -= add;
    s.betStreet += add;
    s.betHand += add;
    minRaise = (s.betStreet - wasBet).clamp(bigBlind, 1 << 30);
    currentBet = s.betStreet;
    if (s.stack == 0) {
      s.allIn = true;
      s.lastAction = 'All-in $add!';
      say('🔥 ${s.name} raises ALL-IN to ${s.betStreet}!');
    } else {
      s.lastAction = 'Raise to ${s.betStreet}';
      say('${s.name} raises to ${s.betStreet}. 😤');
    }
    // Everyone else owes action again.
    _needsToAct.clear();
    for (int i = 0; i < seats.length; i++) {
      final o = seats[i];
      if (i != idx &&
          !o.eliminated &&
          !o.folded &&
          !o.allIn &&
          o.stack > 0) {
        _needsToAct.add(i);
      }
    }
    onSfx?.call(Sfx.raise);
    _afterAction();
    return true;
  }

  void _afterAction() {
    _bump();
    if (_playersInHand() < 2) {
      _schedule(const Duration(milliseconds: 700), _awardUncontested);
      return;
    }
    _schedule(const Duration(milliseconds: 550), _driveBetting);
  }

  void _endBettingRound() {
    if (pot > biggestPot) biggestPot = pot;
    if (_playersInHand() < 2) {
      _awardUncontested();
      return;
    }
    switch (street) {
      case Street.preflop:
        street = Street.flop;
        break;
      case Street.flop:
        street = Street.turn;
        break;
      case Street.turn:
        street = Street.river;
        break;
      case Street.river:
        _schedule(const Duration(milliseconds: 600), _showdown);
        return;
    }
    phase = Phase.dealingBoard;
    _dealBoardStep(0);
  }

  void _dealBoardStep(int step) {
    final target = street == Street.flop ? 3 : 1;
    if (step >= target) {
      final label = streetName();
      say('— The $label: ${community.map(Card.name).join(' ')}');
      onSfx?.call(Sfx.reveal);
      _bump();
      _schedule(const Duration(milliseconds: 900), _startBettingRound);
      return;
    }
    community.add(_deck.removeLast());
    onSfx?.call(Sfx.deal);
    _bump();
    _schedule(const Duration(milliseconds: 350), () => _dealBoardStep(step + 1));
  }

  void _autoRunout() {
    // Everyone left is all-in (or one can act): deal the rest, then showdown.
    if (street == Street.preflop) {
      street = Street.flop;
      for (int i = 0; i < 3; i++) {
        community.add(_deck.removeLast());
      }
      say('— The Flop: ${community.map(Card.name).join(' ')}');
    } else if (street == Street.flop) {
      street = Street.turn;
      community.add(_deck.removeLast());
      say('— The Turn: ${community.map(Card.name).join(' ')}');
    } else if (street == Street.turn) {
      street = Street.river;
      community.add(_deck.removeLast());
      say('— The River: ${community.map(Card.name).join(' ')}');
    } else {
      _schedule(const Duration(milliseconds: 600), _showdown);
      return;
    }
    onSfx?.call(Sfx.reveal);
    _bump();
    _schedule(const Duration(milliseconds: 1100), _autoRunout);
  }

  // ------------------------------------------------------------ showdown
  void _awardUncontested() {
    phase = Phase.showdown;
    int winner = -1;
    for (int i = 0; i < seats.length; i++) {
      if (!seats[i].eliminated && !seats[i].folded) winner = i;
    }
    if (winner < 0) {
      _startHand();
      return;
    }
    final s = seats[winner];
    final amount = pot;
    s.stack += amount;
    s.lastWin = amount;
    lastWins = [WinInfo(winner, amount, 'Everyone else folded', false)];
    say('🏆 ${s.name} takes the pot of $amount — everyone else folded!');
    if (s.isHuman) {
      onSfx?.call(Sfx.win);
    }
    _bump();
    _finishHand();
  }

  void _showdown() {
    phase = Phase.showdown;
    say('🃏 Showdown! ${community.map(Card.name).join(' ')} on the board.');
    // Score every live hand.
    for (int i = 0; i < seats.length; i++) {
      final s = seats[i];
      if (!s.eliminated && !s.folded) {
        s.bestScore = HandEval.evaluate7([...s.hole, ...community]);
      }
    }
    _revealStep(0);
  }

  void _revealStep(int orderIdx) {
    final live = [
      for (int i = 0; i < seats.length; i++)
        if (!seats[i].eliminated && !seats[i].folded) i
    ];
    // Reveal order: start left of the last aggressor — simplified: from button.
    if (orderIdx >= live.length) {
      _awardPots();
      return;
    }
    final idx = live[orderIdx];
    revealed.add(idx);
    final s = seats[idx];
    final handName = HandEval.categoryName(s.bestScore);
    say('${s.name} shows ${s.hole.map(Card.name).join(' ')} — $handName.');
    onSfx?.call(Sfx.reveal);
    _bump();
    _schedule(const Duration(milliseconds: 1100),
        () => _revealStep(orderIdx + 1));
  }

  void _awardPots() {
    if (pot > biggestPot) biggestPot = pot;
    // Side-pot algorithm: peel off levels of contribution.
    final contrib = <int, int>{
      for (int i = 0; i < seats.length; i++)
        if (!seats[i].eliminated && seats[i].betHand > 0) i: seats[i].betHand
    };
    final wins = <WinInfo>[];
    var safety = 0;
    while (contrib.values.any((c) => c > 0) && safety++ < 12) {
      final level = contrib.values.where((c) => c > 0).reduce(min);
      final inPot = contrib.entries.where((e) => e.value > 0).toList();
      final amount = level * inPot.length;
      final eligible =
          inPot.map((e) => e.key).where((i) => !seats[i].folded).toList();
      if (eligible.isNotEmpty && amount > 0) {
        var best = -1;
        for (final i in eligible) {
          if (seats[i].bestScore > best) best = seats[i].bestScore;
        }
        var tied = eligible.where((i) => seats[i].bestScore == best).toList();
        // Odd chip: earliest position left of the button.
        tied.sort((a, b) {
          final n = seats.length;
          final da = (a - dealerIndex + n) % n;
          final db = (b - dealerIndex + n) % n;
          return da.compareTo(db);
        });
        final share = amount ~/ tied.length;
        var remainder = amount % tied.length;
        for (final i in tied) {
          var award = share;
          if (remainder > 0) {
            award++;
            remainder--;
          }
          seats[i].stack += award;
          seats[i].lastWin += award;
          wins.add(WinInfo(i, award, HandEval.categoryName(best),
              tied.length > 1));
        }
      }
      for (final e in inPot) {
        contrib[e.key] = e.value - level;
      }
    }
    lastWins = wins;
    for (final w in wins) {
      final s = seats[w.seat];
      say(
          '🏆 ${s.name} wins ${w.amount} with ${w.handName}${w.split ? ' (split pot)' : ''}!');
    }
    final humanWon = wins.any((w) => seats[w.seat].isHuman);
    onSfx?.call(humanWon ? Sfx.win : Sfx.lose);
    _bump();
    _finishHand();
  }

  void _finishHand() {
    phase = Phase.handOver;
    final active = _activeSeats();
    final humansAlive = seats.any((s) => s.isHuman && !s.eliminated && s.stack > 0);
    final anyBots = seats.any((s) => !s.isHuman && !s.eliminated);
    if (!humansAlive) {
      _schedule(const Duration(milliseconds: 2500), () => _endGame(false));
      return;
    }
    if (!anyBots && seats.any((s) => !s.isHuman)) {
      _schedule(const Duration(milliseconds: 2500), () => _endGame(true));
      return;
    }
    if (active.length < 2) {
      _schedule(const Duration(milliseconds: 2500), () => _endGame(true));
      return;
    }
    _schedule(const Duration(milliseconds: 3500), _startHand,
        resume: _startHand);
  }

  void _endGame(bool won) {
    phase = Phase.gameOver;
    humanWonGame = won;
    humanLostGame = !won;
    if (won) {
      say('🎉 YOU cleaned out the table! Lone Star legend!');
      onSfx?.call(Sfx.win);
    } else {
      say('💸 Out of chips, partner. The saloon thanks you.');
      onSfx?.call(Sfx.lose);
    }
    _bump();
  }

  // ------------------------------------------------------------ bot AI
  void _botAct(int idx) {
    if (phase != Phase.betting || idx != actorIndex) {
      _driveBetting(); // state moved on; re-drive rather than stall
      return;
    }
    final s = seats[idx];
    if (s.eliminated || s.folded || s.allIn || s.stack <= 0) {
      _needsToAct.remove(idx);
      _driveBetting();
      return;
    }
    final toCall = (currentBet - s.betStreet).clamp(0, s.stack);
    final strength = _handStrength(s);
    final d = s.difficulty;
    final r = _rand.nextDouble();

    ActionKind kind;
    int raiseTo = 0;
    if (toCall == 0) {
      final raiseLine = d == 0 ? 0.80 : (d == 1 ? 0.68 : 0.60);
      final bluffLine = d == 2 && r < 0.10 && strength < 0.45;
      if (strength > raiseLine || (d == 0 && r < 0.08) || bluffLine) {
        kind = ActionKind.raise;
        raiseTo = _aiRaiseSize(s, bluff: bluffLine);
      } else {
        kind = ActionKind.check;
      }
    } else {
      final potOdds = toCall / (pot + toCall + 1);
      final foldLine = d == 0 ? 0.18 : (d == 1 ? 0.30 : 0.34);
      final raiseLine = d == 0 ? 0.90 : (d == 1 ? 0.74 : 0.66);
      final scared = toCall > s.stack * (d == 0 ? 0.5 : 0.3);
      if ((strength < foldLine && (potOdds > strength * 0.9 || scared)) ||
          (d == 0 && r < 0.04)) {
        kind = ActionKind.fold;
      } else if (strength > raiseLine && s.stack > toCall + bigBlind) {
        kind = ActionKind.raise;
        raiseTo = _aiRaiseSize(s, bluff: false);
      } else {
        kind = ActionKind.call;
      }
    }

    switch (kind) {
      case ActionKind.fold:
        _applyFold(idx);
        break;
      case ActionKind.check:
        _applyCheck(idx);
        break;
      case ActionKind.call:
        _applyCall(idx);
        break;
      case ActionKind.raise:
        final lo = minRaiseTo();
        final hi = maxRaiseTo();
        if (hi < lo) {
          _applyCall(idx);
        } else {
          _applyRaise(idx, raiseTo.clamp(lo, hi));
        }
        break;
    }
  }

  int _aiRaiseSize(Seat s, {required bool bluff}) {
    final base = currentBet == 0 ? bigBlind * 2 : currentBet + minRaise;
    final sized = bluff
        ? (pot * 0.6).round().clamp(bigBlind, 1 << 30)
        : (base + (pot * 0.35 * _rand.nextDouble()).round());
    return sized.clamp(0, s.stack + s.betStreet);
  }

  /// 0.0 (hopeless) … 1.0 (the immortal nuts), roughly.
  double _handStrength(Seat s) {
    if (community.isEmpty) return _preflopStrength(s.hole);
    // 5 cards on the flop, 6 on the turn — evaluate() handles any count.
    final score = HandEval.evaluate([...s.hole, ...community]);
    final cat = HandEval.categoryOf(score);
    var v = 0.12 + cat * 0.095; // pair ≈ 0.31 … straight flush ≈ 0.98
    // Kicker nudge from the top kicker bits.
    v += ((score >> 16) & 0xF) / 13 * 0.05;
    // Pocket-pair / suited texture bonus pre-draw.
    final r0 = Card.rankOf(s.hole[0]);
    final r1 = Card.rankOf(s.hole[1]);
    if (r0 == r1) v += 0.06;
    if (Card.suitOf(s.hole[0]) == Card.suitOf(s.hole[1])) v += 0.03;
    return v.clamp(0.0, 0.99);
  }

  double _preflopStrength(List<int> hole) {
    final r0 = Card.rankOf(hole[0]);
    final r1 = Card.rankOf(hole[1]);
    final hi = max(r0, r1);
    final lo = min(r0, r1);
    final suited = Card.suitOf(hole[0]) == Card.suitOf(hole[1]);
    var v = hi / 12 * 0.45; // high card weight
    if (r0 == r1) {
      v = 0.55 + hi / 12 * 0.4; // pair: 0.57 … 0.95
    } else {
      v += (12 - (hi - lo)) / 12 * 0.15; // connectedness
      if (suited) v += 0.06;
      if (hi >= 10) v += 0.08; // broadway
    }
    return v.clamp(0.05, 0.97);
  }
}
