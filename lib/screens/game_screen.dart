import 'dart:math';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/poker_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';

/// The poker table: animated deals, visible opponents with narration,
/// per-seat trays, betting controls, showdown reveals.
class GameScreen extends StatefulWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  final GameConfig config;
  final bool passPlay;
  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.config,
    required this.passPlay,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PokerEngine _engine;
  final ScrollController _feedController = ScrollController();
  int _lastNarration = 0;
  int _lastRecordedHand = 0;
  bool _recordedGameOver = false;
  bool _raiseMode = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _engine = PokerEngine();
    _engine.onSfx = widget.audio.playNamed;
    _engine.addListener(_onEngine);
    widget.audio.startGameMusic();
    _engine.newGame(widget.config);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.removeListener(_onEngine);
    _engine.dispose();
    _feedController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _engine.pause();
    } else if (state == AppLifecycleState.resumed) {
      _engine.resume();
    }
  }

  void _onEngine() {
    // Auto-scroll the narration feed.
    if (_engine.narration.length != _lastNarration) {
      _lastNarration = _engine.narration.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_feedController.hasClients) {
          _feedController.animateTo(
            _feedController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
    // Record per-hand stats once.
    if (_engine.phase == Phase.handOver &&
        _engine.handNumber != _lastRecordedHand &&
        _engine.handNumber > 0) {
      _lastRecordedHand = _engine.handNumber;
      final won =
          _engine.lastWins.any((w) => _engine.seats[w.seat].isHuman);
      widget.settings.recordHand(won: won, pot: _engine.pot);
    }
    // Game over: stats + one review nudge.
    if (_engine.phase == Phase.gameOver && !_recordedGameOver) {
      _recordedGameOver = true;
      if (_engine.humanWonGame) {
        widget.settings.recordGameWon();
      }
      _maybeAskReview();
    }
  }

  Future<void> _maybeAskReview() async {
    if (widget.settings.reviewAsked) return;
    await widget.settings.markReviewAsked();
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await Future.delayed(const Duration(seconds: 1));
        await review.requestReview();
      }
    } catch (_) {}
  }

  Future<void> _confirmLeave() async {
    widget.audio.click();
    _engine.pause();
    final theme = widget.settings.theme;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.railDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.accent, width: 2),
        ),
        title: Text('Take a break?',
            style: Saloon.title(20, theme: theme)),
        content: Text(
          'The hand is frozen and will resume right where you left off.',
          style: Saloon.body(14, theme: theme),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('resume'),
            child: Text('RESUME',
                style: TextStyle(
                    color: theme.accentLight, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('restart'),
            child: Text('RESTART',
                style: TextStyle(
                    color: theme.accentLight, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('quit'),
            child: const Text('QUIT TO MENU',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'quit') {
      widget.audio.startMenuMusic();
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else if (choice == 'restart') {
      _lastRecordedHand = 0;
      _recordedGameOver = false;
      _engine.newGame(widget.config);
    } else {
      _engine.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return ListenableBuilder(
      listenable: _engine,
      builder: (_, _) => Scaffold(
        body: FeltBackdrop(
          theme: theme,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topBar(theme),
                    Expanded(child: _table(theme)),
                    _feed(theme),
                    _actionBar(theme),
                  ],
                ),
                if (_engine.phase == Phase.handOver) _handOverBanner(theme),
                if (_engine.phase == Phase.gameOver) _gameOverOverlay(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ top bar
  Widget _topBar(PokerThemeDef theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 10, 2),
      child: Row(
        children: [
          Saloon.iconButton(
            theme: theme,
            icon: Icons.pause,
            size: 40,
            onTap: _confirmLeave,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'HAND #${_engine.handNumber} \u2022 ${_engine.streetName().toUpperCase()}',
              style: Saloon.label(12, theme: theme),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ChipWidget(
            theme: theme,
            style: ChipStyles.byId(widget.settings.chipStyleId),
            amount: _engine.pot,
            size: 40,
          ),
          const SizedBox(width: 6),
          Text('POT ${_engine.pot}',
              style: Saloon.title(15, theme: theme)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ table
  Widget _table(PokerThemeDef theme) {
    return LayoutBuilder(
      builder: (ctx, box) {
        final n = _engine.seats.length;
        final cx = box.maxWidth / 2;
        final cy = box.maxHeight / 2;
        final rx = (box.maxWidth / 2 - 62).clamp(60.0, 1000.0);
        final ry = (box.maxHeight / 2 - 78).clamp(60.0, 1000.0);
        final seats = <Widget>[
          _centerBoard(theme, box),
        ];
        for (int i = 0; i < n; i++) {
          final a = (pi / 2) + i * 2 * pi / n;
          final x = cx + rx * cos(a);
          final y = cy + ry * sin(a);
          seats.add(Positioned(
            left: x - 52,
            top: y - 56,
            child: _SeatWidget(
              key: ValueKey('seat$i-h${_engine.handNumber}'),
              engine: _engine,
              index: i,
              theme: theme,
              settings: widget.settings,
              passPlay: widget.passPlay,
              faceUp: _holeFaceUp(i),
              isActor: _engine.actorIndex == i &&
                  _engine.phase == Phase.betting &&
                  !_engine.seats[i].folded,
              pulse: _pulse,
            ),
          ));
        }
        return Stack(children: seats);
      },
    );
  }

  Widget _centerBoard(PokerThemeDef theme, BoxConstraints box) {
    final dealt = _engine.community;
    final cardW = (box.maxWidth / 7).clamp(40.0, 62.0);
    final cardStyle = CardStyles.byId(widget.settings.cardStyleId);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                  color: theme.accent.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Text(
              _engine.phase == Phase.dealingHole
                  ? 'DEALING\u2026'
                  : _engine.streetName().toUpperCase(),
              style: Saloon.label(12, theme: theme),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              if (i < dealt.length) {
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: DealPop(
                    key: ValueKey(
                        'c${dealt[i]}-h${_engine.handNumber}-$i'),
                    staggerMs: i * 90,
                    child: PlayingCardWidget(
                      card: dealt[i],
                      theme: theme,
                      cardStyle: cardStyle,
                      width: cardW,
                    ),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                child: Container(
                  width: cardW,
                  height: cardW * 1.42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardW * 0.12),
                    border: Border.all(
                      color: theme.accent.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _holeFaceUp(int i) {
    final e = _engine;
    if (e.revealed.contains(i)) return true;
    final s = e.seats[i];
    if (!s.isHuman || s.folded) return false;
    if (widget.passPlay) {
      // Pass-and-play: only the acting player sees their cards.
      return e.awaitingHuman &&
          e.actorIndex == i &&
          e.phase == Phase.betting;
    }
    return i == 0; // vs bots: your cards are always visible to you
  }

  // ------------------------------------------------------------ feed
  Widget _feed(PokerThemeDef theme) {
    final items = _engine.narration.length > 8
        ? _engine.narration.sublist(_engine.narration.length - 8)
        : _engine.narration;
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.45),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.35), width: 1),
      ),
      child: ListView.builder(
        controller: _feedController,
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(
            items[i],
            style: Saloon.body(12, theme: theme).copyWith(height: 1.25),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ actions
  Widget _actionBar(PokerThemeDef theme) {
    final e = _engine;
    final humanTurn = e.awaitingHuman &&
        e.phase == Phase.betting &&
        e.actorIndex >= 0 &&
        e.seats[e.actorIndex].isHuman;
    if (!humanTurn) {
      return const SizedBox(height: 86);
    }
    final me = e.seats[e.actorIndex];
    if (_raiseMode) {
      return _raiseControls(theme, me);
    }
    final canCheck = e.canCheck;
    final callAmt = e.callAmount();
    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.passPlay
                ? '\u{1F449} ${me.name} \u2014 your move! (pass the device)'
                : '\u{1F449} Your move, ${me.name}',
            style: Saloon.label(12, theme: theme),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                _actBtn(theme, 'Fold', Icons.close, Colors.redAccent.shade100,
                    () => _act(ActionKind.fold)),
                const SizedBox(width: 8),
                _actBtn(
                    theme,
                    canCheck ? 'Check' : 'Call $callAmt',
                    canCheck ? Icons.check : Icons.add,
                    null,
                    () => _act(
                        canCheck ? ActionKind.check : ActionKind.call)),
                const SizedBox(width: 8),
                _actBtn(theme, 'Raise', Icons.arrow_upward, null, () {
                  widget.audio.click();
                  if (e.maxRaiseTo() >= e.minRaiseTo()) {
                    setState(() => _raiseMode = true);
                  } else {
                    // Short stack: can't make a legal raise — all-in call.
                    _act(ActionKind.call);
                  }
                }),
                const SizedBox(width: 8),
                _actBtn(theme, 'All-in', Icons.local_fire_department,
                    Colors.orangeAccent, () {
                  final target = e.maxRaiseTo();
                  _act(ActionKind.raise, raiseTo: target);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actBtn(PokerThemeDef theme, String label, IconData icon,
      Color? tint, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.audio.click();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.railWood,
            border: Border.all(color: theme.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 3),
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: tint ?? theme.accentLight, size: 20),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: tint ?? theme.accentLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _raiseControls(PokerThemeDef theme, Seat me) {
    final e = _engine;
    final lo = e.minRaiseTo();
    final hi = e.maxRaiseTo();
    final start = lo.clamp(0, hi);
    return _RaiseSlider(
      theme: theme,
      min: lo.toDouble(),
      max: hi.toDouble(),
      initial: start.toDouble(),
      onCancel: () {
        widget.audio.click();
        setState(() => _raiseMode = false);
      },
      onConfirm: (v) {
        setState(() => _raiseMode = false);
        _act(ActionKind.raise, raiseTo: v.round());
      },
    );
  }

  void _act(ActionKind kind, {int raiseTo = 0}) {
    final ok = _engine.humanAct(kind, raiseTo: raiseTo);
    if (!ok) {
      widget.audio.invalid();
    }
  }

  // ------------------------------------------------------------ overlays
  Widget _handOverBanner(PokerThemeDef theme) {
    final wins = _engine.lastWins;
    final lines = wins.map((w) {
      final s = _engine.seats[w.seat];
      final hand =
          w.handName == 'Everyone else folded' ? '' : ' with ${w.handName}';
      return '${s.name} wins ${w.amount}$hand${w.split ? ' (split)' : ''}';
    }).toList();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.railDark.withValues(alpha: 0.94),
              border: Border.all(color: theme.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('\u{1F3C6} HAND OVER',
                    style: Saloon.display(20, theme: theme)),
                const SizedBox(height: 10),
                ...lines.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(l,
                          textAlign: TextAlign.center,
                          style: Saloon.body(14, theme: theme)),
                    )),
                const SizedBox(height: 8),
                Text('Next hand dealing\u2026',
                    style: Saloon.label(11, theme: theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay(PokerThemeDef theme) {
    final won = _engine.humanWonGame;
    final s = widget.settings;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.railDark,
              border: Border.all(color: theme.accent, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(won ? '\u{1F3C6}' : '\u{1F4B8}',
                    style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  won ? 'TABLE CLEARED!' : 'OUT OF CHIPS',
                  style: Saloon.display(24, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  won
                      ? 'You took every chip on the felt. Lone Star legend!'
                      : 'The saloon thanks you for your chips, partner.',
                  style: Saloon.body(14, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Hands played: ${s.handsPlayed}  \u2022  Biggest pot: ${s.biggestPot}',
                  style: Saloon.body(12, theme: theme),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Saloon.button(
                  theme: theme,
                  text: 'Play again',
                  icon: Icons.refresh,
                  onTap: () {
                    widget.audio.gameStart();
                    _lastRecordedHand = 0;
                    _recordedGameOver = false;
                    _engine.newGame(widget.config);
                  },
                ),
                const SizedBox(height: 12),
                Saloon.button(
                  theme: theme,
                  text: 'Menu',
                  icon: Icons.home,
                  primary: false,
                  onTap: () {
                    widget.audio.click();
                    widget.audio.startMenuMusic();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One seat at the table: avatar, name, stack, hole cards, bet, status.
class _SeatWidget extends StatelessWidget {
  final PokerEngine engine;
  final int index;
  final PokerThemeDef theme;
  final PokerSettings settings;
  final bool passPlay;
  final bool faceUp;
  final bool isActor;
  final AnimationController pulse;

  const _SeatWidget({
    super.key,
    required this.engine,
    required this.index,
    required this.theme,
    required this.settings,
    required this.passPlay,
    required this.faceUp,
    required this.isActor,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final seat = engine.seats[index];
    if (seat.eliminated) {
      return SizedBox(
        width: 104,
        child: Opacity(
          opacity: 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatar(theme, seat, false),
              Text(seat.name,
                  style: Saloon.body(11, theme: theme),
                  overflow: TextOverflow.ellipsis),
              Text('OUT', style: Saloon.label(10, theme: theme)),
            ],
          ),
        ),
      );
    }
    final folded = seat.folded;
    final cardStyle = CardStyles.byId(settings.cardStyleId);
    final status = _statusText(seat);
    return SizedBox(
      width: 104,
      child: Opacity(
        opacity: folded ? 0.55 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: pulse,
                  builder: (_, child) => Container(
                    decoration: isActor
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.accent.withValues(
                                    alpha: 0.45 + pulse.value * 0.4),
                                blurRadius: 10 + pulse.value * 8,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActor ? theme.accentLight : theme.accent,
                        width: isActor ? 3 : 1.5,
                      ),
                    ),
                    child: _avatar(theme, seat, true),
                  ),
                ),
                if (seat.isDealer)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardFront,
                        border:
                            Border.all(color: theme.railDark, width: 2),
                      ),
                      child: Center(
                        child: Text('D',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: theme.railDark)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              seat.name,
              style: Saloon.body(11, theme: theme),
              overflow: TextOverflow.ellipsis,
            ),
            // Hole cards.
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int k = 0;
                      k < seat.hole.length && k < 2;
                      k++)
                    Padding(
                      padding: EdgeInsets.only(left: k == 0 ? 0 : 3),
                      child: folded
                          ? Opacity(
                              opacity: 0.35,
                              child: PlayingCardWidget(
                                card: null,
                                theme: theme,
                                cardStyle: cardStyle,
                                width: 27,
                              ),
                            )
                          : DealPop(
                              key: ValueKey(
                                  'h${seat.hole[k]}-hand${engine.handNumber}-s$index'),
                              staggerMs: k * 110,
                              child: faceUp
                                  ? PlayingCardWidget(
                                      card: seat.hole[k],
                                      theme: theme,
                                      cardStyle: cardStyle,
                                      width: 27,
                                    )
                                  : PlayingCardWidget(
                                      card: null,
                                      theme: theme,
                                      cardStyle: cardStyle,
                                      width: 27,
                                    ),
                            ),
                    ),
                ],
              ),
            ),
            Text('${seat.stack}',
                style: Saloon.title(13, theme: theme)),
            // Bet tray.
            SizedBox(
              height: 22,
              child: seat.betStreet > 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChipWidget(
                          key: ValueKey('bet$index-${seat.betStreet}'),
                          theme: theme,
                          style: ChipStyles.byId(settings.chipStyleId),
                          amount: seat.betStreet,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text('${seat.betStreet}',
                            style: Saloon.body(11, theme: theme)),
                      ],
                    )
                  : null,
            ),
            SizedBox(
              height: 16,
              child: status.isEmpty
                  ? null
                  : Text(
                      status,
                      style: Saloon.label(9, theme: theme),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(PokerThemeDef theme, Seat seat, bool showInitial) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: seat.isHuman ? theme.accent : theme.railWood,
      ),
      child: Center(
        child: showInitial
            ? Text(
                (seat.name.isNotEmpty ? seat.name[0] : '?').toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: seat.isHuman ? theme.railDark : theme.accentLight,
                ),
              )
            : Icon(Icons.person_off,
                color: theme.accent.withValues(alpha: 0.5)),
      ),
    );
  }

  String _statusText(Seat seat) {
    if (seat.folded) return 'FOLDED';
    if (seat.allIn && seat.lastAction.isEmpty) return 'ALL-IN';
    if (isActor && !seat.isHuman) return 'thinking\u2026';
    if (isActor && seat.isHuman) return 'YOUR MOVE';
    if (seat.lastWin > 0 && engine.phase == Phase.handOver) {
      return '+${seat.lastWin}';
    }
    return seat.lastAction;
  }
}

class _RaiseSlider extends StatefulWidget {
  final PokerThemeDef theme;
  final double min;
  final double max;
  final double initial;
  final VoidCallback onCancel;
  final ValueChanged<double> onConfirm;
  const _RaiseSlider({
    required this.theme,
    required this.min,
    required this.max,
    required this.initial,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<_RaiseSlider> createState() => _RaiseSliderState();
}

class _RaiseSliderState extends State<_RaiseSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial.clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final allIn = _value >= widget.max;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            allIn
                ? '\u{1F525} ALL-IN ${_value.round()}'
                : 'RAISE TO ${_value.round()}',
            style: Saloon.display(18, theme: theme),
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: (widget.max - widget.min).round().clamp(1, 200),
            activeColor: theme.accent,
            inactiveColor: theme.accent.withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _value = v),
          ),
          Row(
            children: [
              Expanded(
                child: Saloon.button(
                  theme: theme,
                  text: 'Back',
                  primary: false,
                  fontSize: 14,
                  onTap: widget.onCancel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Saloon.button(
                  theme: theme,
                  text: allIn ? 'All-in!' : 'Raise',
                  icon: Icons.arrow_upward,
                  fontSize: 15,
                  onTap: () => widget.onConfirm(_value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
