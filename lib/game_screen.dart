import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class _PCard {
  final int r; // 2..14
  final int s; // 0..3
  const _PCard(this.r, this.s);
  String get label => r == 14 ? 'A' : r == 13 ? 'K' : r == 12 ? 'Q' : r == 11 ? 'J' : '$r';
  String get suit => '♠♥♦♣'[s];
  bool get red => s == 1 || s == 2;
}

const _catNames = [
  'High Card', 'Pair', 'Two Pair', 'Three of a Kind', 'Straight',
  'Flush', 'Full House', 'Four of a Kind', 'Straight Flush'
];

int _eval5(List<_PCard> cs) {
  final rs = cs.map((c) => c.r).toList()..sort((a, b) => b.compareTo(a));
  final flush = cs.every((c) => c.s == cs[0].s);
  final uniq = rs.toSet().toList()..sort((a, b) => b.compareTo(a));
  var straightHigh = 0;
  if (uniq.length == 5) {
    if (uniq[0] - uniq[4] == 4) {
      straightHigh = uniq[0];
    } else if (uniq[0] == 14 && uniq[1] == 5) {
      straightHigh = 5;
    }
  }
  final counts = <int, int>{};
  for (final r in rs) {
    counts[r] = (counts[r] ?? 0) + 1;
  }
  final groups = counts.entries.toList()
    ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : b.key.compareTo(a.key));
  int cat;
  List<int> kick;
  if (flush && straightHigh > 0) {
    cat = 8; kick = [straightHigh];
  } else if (groups[0].value == 4) {
    cat = 7; kick = [groups[0].key, groups[1].key];
  } else if (groups[0].value == 3 && groups[1].value == 2) {
    cat = 6; kick = [groups[0].key, groups[1].key];
  } else if (flush) {
    cat = 5; kick = rs;
  } else if (straightHigh > 0) {
    cat = 4; kick = [straightHigh];
  } else if (groups[0].value == 3) {
    cat = 3; kick = [groups[0].key, groups[1].key, groups[2].key];
  } else if (groups[0].value == 2 && groups[1].value == 2) {
    cat = 2; kick = [groups[0].key, groups[1].key, groups[2].key];
  } else if (groups[0].value == 2) {
    cat = 1; kick = [groups[0].key, groups[1].key, groups[2].key, groups[3].key];
  } else {
    cat = 0; kick = rs;
  }
  var score = cat * 759375;
  var mult = 50625;
  for (final k in kick.take(5)) {
    score += k * mult;
    mult ~/= 15;
  }
  return score;
}

int _eval7(List<_PCard> cs) {
  var best = 0;
  for (var a = 0; a < 3; a++) {
    for (var b = a + 1; b < 4; b++) {
      for (var c = b + 1; c < 5; c++) {
        for (var d = c + 1; d < 6; d++) {
          for (var e = d + 1; e < 7; e++) {
            final v = _eval5([cs[a], cs[b], cs[c], cs[d], cs[e]]);
            if (v > best) best = v;
          }
        }
      }
    }
  }
  return best;
}

enum _Act { fold, checkCall, raise }

class LoneStarPokerScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const LoneStarPokerScreen({super.key, required this.players, required this.callbacks});
  @override
  State<LoneStarPokerScreen> createState() => _LoneStarPokerScreenState();
}

class _LoneStarPokerScreenState extends State<LoneStarPokerScreen> {
  final _rnd = Random();
  final _styles = ['tight 🧊', 'loose 🎲', 'wild 🌪️'];
  final List<int> _stacks = [500, 500, 500, 500];
  List<List<_PCard>> _hole = [];
  List<_PCard> _community = [];
  List<_PCard> _deck = [];
  List<bool> _inHand = [];
  List<bool> _allIn = [];
  List<int> _committed = [0, 0, 0, 0];
  int _currentBet = 0;
  int _pot = 0;
  int _button = 0;
  int _handNum = 0;
  bool _inProgress = false;
  bool _over = false;
  bool _awaiting = false;
  int _awaitToCall = 0;
  bool _showdown = false;
  String _msg = 'Welcome to the saloon! 🤠';
  List<int> _winners = [];
  Completer<_Act>? _waiter;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_over) _newHand();
    });
  }

  int _activeCount() => _inHand.where((x) => x).length;
  int _canActCount() => [for (var i = 0; i < 4; i++) if (_inHand[i] && !_allIn[i]) i].length;

  void _newDeck() {
    _deck = [];
    for (var s = 0; s < 4; s++) {
      for (var r = 2; r <= 14; r++) {
        _deck.add(_PCard(r, s));
      }
    }
    _deck.shuffle(_rnd);
  }

  Future<void> _newHand() async {
    if (_over) return;
    if (_stacks[0] <= 0) {
      _over = true;
      Sfx.lose();
      widget.callbacks.finish(
        headline: '🤠 Busted! The saloon takes your boots.',
        subline: 'The bots are still laughing. Run it back! 🌵',
      );
      return;
    }
    for (var i = 1; i < 4; i++) {
      if (_stacks[i] < 10) {
        _stacks[i] = 500;
        _msg = '🤠 ${widget.players[i].name} rides back in with fresh chips!';
      }
    }
    _handNum++;
    _button = (_handNum - 1) % 4;
    _newDeck();
    _hole = List.generate(4, (_) => [_deck.removeLast(), _deck.removeLast()]);
    _community = [];
    _inHand = [true, true, true, true];
    _allIn = [false, false, false, false];
    _committed = [0, 0, 0, 0];
    _pot = 0;
    _winners = [];
    _showdown = false;
    _inProgress = true;
    widget.players[0].score = _stacks[0];
    widget.callbacks.refreshHud();
    setState(() => _msg = 'Hand $_handNum — blinds are in. Good luck, partner! 🍀');
    // blinds
    final sb = (_button + 1) % 4;
    final bb = (_button + 2) % 4;
    _postBlind(sb, 5);
    _postBlind(bb, 10);
    _currentBet = 10;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || _over) return;
    await _betStreet((_button + 3) % 4);
    if (!mounted || _over || !_inProgress) return;
    for (final street in [3, 1, 1]) {
      if (_activeCount() <= 1) break;
      for (var k = 0; k < street; k++) {
        _community.add(_deck.removeLast());
      }
      Sfx.move();
      _committed = [0, 0, 0, 0];
      _currentBet = 0;
      setState(() => _msg = street == 3 ? 'The FLOP hits the felt! 🃏' : 'Another card… feel lucky? 🍀');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _over || !_inProgress) return;
      final first = _firstActiveAfter(_button);
      await _betStreet(first);
      if (!mounted || _over || !_inProgress) return;
    }
    _finishHand();
  }

  void _postBlind(int i, int amt) {
    final pay = min(amt, _stacks[i]);
    _stacks[i] -= pay;
    _committed[i] += pay;
    if (_stacks[i] == 0) _allIn[i] = true;
  }

  int _firstActiveAfter(int from) {
    for (var k = 1; k <= 4; k++) {
      final i = (from + k) % 4;
      if (_inHand[i] && !_allIn[i]) return i;
    }
    return (from + 1) % 4;
  }

  Future<void> _betStreet(int first) async {
    if (_canActCount() <= 1 && _currentBet == 0) {
      _collect();
      return;
    }
    final order = List.generate(4, (k) => (first + k) % 4);
    var queue = order.where((i) => _inHand[i] && !_allIn[i]).toList();
    while (queue.isNotEmpty) {
      if (_activeCount() <= 1 || _over || !_inProgress) break;
      final i = queue.removeAt(0);
      if (!_inHand[i] || _allIn[i]) continue;
      final toCall = _currentBet - _committed[i];
      _Act act;
      if (widget.players[i].isBot) {
        await Future.delayed(const Duration(milliseconds: 550));
        if (!mounted || _over || !_inProgress) return;
        act = _botDecide(i, toCall);
      } else {
        act = await _askHuman(toCall);
        if (!mounted || _over || !_inProgress) return;
      }
      final raised = _applyAction(i, act, toCall);
      setState(() {});
      if (raised) {
        for (final j in order) {
          if (j != i &&
              _inHand[j] &&
              !_allIn[j] &&
              _committed[j] < _currentBet &&
              !queue.contains(j)) {
            queue.add(j);
          }
        }
      }
    }
    _collect();
  }

  void _collect() {
    for (var i = 0; i < 4; i++) {
      _pot += _committed[i];
      _committed[i] = 0;
    }
    _currentBet = 0;
    if (mounted) setState(() {});
  }

  /// Returns true if this was a genuine raise.
  bool _applyAction(int i, _Act act, int toCall) {
    final name = widget.players[i].name;
    if (act == _Act.fold) {
      _inHand[i] = false;
      _msg = '🚪 $name folds. Smart? Cowardly? You decide.';
      Sfx.tap();
      return false;
    }
    if (act == _Act.raise) {
      final total = toCall + 20;
      final pay = min(total, _stacks[i]);
      _stacks[i] -= pay;
      _committed[i] += pay;
      if (_stacks[i] == 0) _allIn[i] = true;
      if (pay >= total) {
        _currentBet = _committed[i];
        _msg = '🔥 $name RAISES to $_currentBet! Spicy!';
        Sfx.move();
        return true;
      }
      _msg = '😬 $name is ALL-IN!';
      Sfx.move();
      return false;
    }
    final pay = min(toCall, _stacks[i]);
    _stacks[i] -= pay;
    _committed[i] += pay;
    if (_stacks[i] == 0 && toCall > 0) _allIn[i] = true;
    _msg = toCall == 0 ? '✋ $name checks.' : '📞 $name calls $pay.';
    Sfx.click();
    return false;
  }

  double _botStrength(int i) {
    final h = _hole[i];
    if (_community.isEmpty) {
      var s = 0.3;
      if (h[0].r == h[1].r) s = 0.55 + h[0].r / 100;
      if (h[0].s == h[1].s) s += 0.08;
      final hi = max(h[0].r, h[1].r);
      s += hi / 200;
      if ((h[0].r - h[1].r).abs() <= 2) s += 0.05;
      return s.clamp(0.0, 1.0);
    }
    final all = [...h, ..._community];
    final v = _eval7(all) / 759375 / 8;
    return v.clamp(0.0, 1.0) * 0.7 + 0.25;
  }

  _Act _botDecide(int i, int toCall) {
    final style = _styles[i - 1];
    final strength = _botStrength(i);
    final r = _rnd.nextDouble();
    if (toCall == 0) {
      if (strength > 0.6 && r < 0.55) return _Act.raise;
      if (style == 'wild 🌪️' && r < 0.18) return _Act.raise;
      return _Act.checkCall;
    }
    if (strength > 0.7 && r < 0.55) return _Act.raise;
    final threshold = style == 'tight 🧊' ? 0.5 : style == 'loose 🎲' ? 0.32 : 0.22;
    if (strength > threshold) return _Act.checkCall;
    if (style == 'wild 🌪️' && r < 0.18) return _Act.checkCall;
    if (toCall <= 5 && r < 0.35) return _Act.checkCall;
    return _Act.fold;
  }

  Future<_Act> _askHuman(int toCall) async {
    _waiter = Completer<_Act>();
    setState(() {
      _awaiting = true;
      _awaitToCall = toCall;
    });
    final act = await _waiter!.future;
    if (mounted) setState(() => _awaiting = false);
    return act;
  }

  void _humanAct(_Act a) {
    if (_waiter != null && !_waiter!.isCompleted) {
      _waiter!.complete(a);
    }
  }

  void _finishHand() {
    _inProgress = false;
    _awaiting = false;
    final active = [for (var i = 0; i < 4; i++) if (_inHand[i]) i];
    if (active.length == 1) {
      final w = active[0];
      _stacks[w] += _pot;
      _winners = [w];
      _msg = '🏆 ${widget.players[w].name} takes the $_pot-chip pot — everyone else folded!';
      Sfx.win();
    } else {
      _showdown = true;
      var best = -1;
      _winners = [];
      final scores = <int>[];
      for (final i in active) {
        final s = _eval7([..._hole[i], ..._community]);
        scores.add(s);
        if (s > best) {
          best = s;
          _winners = [i];
        } else if (s == best) {
          _winners.add(i);
        }
      }
      final share = _pot ~/ _winners.length;
      for (final w in _winners) {
        _stacks[w] += share;
      }
      _msg = _winners.length == 1
          ? '🏆 ${widget.players[_winners[0]].name} wins $_pot with ${_catNames[best ~/ 759375]}!'
          : '🤝 Split pot! $share chips each.';
      Sfx.win();
      // showdown dialog
      final rows = <Widget>[];
      for (var k = 0; k < active.length; k++) {
        final i = active[k];
        final won = _winners.contains(i);
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${won ? '👑 ' : ''}${widget.players[i].name}: ',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                for (final c in _hole[i]) _tinyCard(c),
                Text(' ${_catNames[scores[k] ~/ 759375]}',
                    style: TextStyle(
                        fontWeight: won ? FontWeight.w900 : FontWeight.w500,
                        color: won ? Colors.amber.shade700 : null)),
              ],
            ),
          ),
        );
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || _over) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => WajihaDialog(
            title: 'Showdown! 🃏',
            emoji: '🤠',
            children: [
              ...rows,
              const SizedBox(height: 12),
              WajihaButton(
                label: 'Next Hand',
                emoji: '🔄',
                onTap: () {
                  Navigator.pop(context);
                  _newHand();
                },
              ),
            ],
          ),
        );
      });
    }
    widget.players[0].score = _stacks[0];
    widget.callbacks.refreshHud();
    setState(() {});
    if (active.length == 1) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && !_over) _newHand();
      });
    }
  }

  void _walkAway() {
    if (_over || _inProgress) return;
    _over = true;
    Sfx.win();
    widget.callbacks.finish(
      headline: '🤠 You rode off into the sunset with ${_stacks[0]} chips!',
      subline: _stacks[0] >= 500
          ? 'Legend status: confirmed. The saloon bows to you. 🌵'
          : 'A tactical retreat. The cards will be kinder tomorrow! 🍀',
    );
  }

  Widget _tinyCard(_PCard c) {
    return Container(
      width: 30,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(c.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: c.red ? Colors.red.shade700 : Colors.grey.shade900)),
          Text(c.suit,
              style: TextStyle(fontSize: 11, color: c.red ? Colors.red.shade700 : Colors.grey.shade900)),
        ],
      ),
    );
  }

  Widget _cardSlot(_PCard? c, {bool faceDown = false}) {
    final t = ThemeController.of(context).theme;
    return Container(
      width: 44,
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: c == null ? t.surface : (faceDown ? null : Colors.white),
        gradient: faceDown ? t.headerGradient : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: c == null
          ? const SizedBox()
          : faceDown
              ? const Center(child: Text('♠️', style: TextStyle(fontSize: 20)))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.label,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: c.red ? Colors.red.shade700 : Colors.grey.shade900)),
                    Text(c.suit,
                        style: TextStyle(
                            fontSize: 15,
                            color: c.red ? Colors.red.shade700 : Colors.grey.shade900)),
                  ],
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Column(
      children: [
        // pot
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
              gradient: t.headerGradient, borderRadius: t.radius),
          child: Text('🪙 POT: $_pot',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
        const SizedBox(height: 6),
        // bots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 1; i < 4; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _winners.contains(i)
                      ? Colors.amber.withValues(alpha: 0.25)
                      : t.surface,
                  borderRadius: t.radius,
                  border: Border.all(
                      color: _winners.contains(i)
                          ? Colors.amber
                          : t.muted.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text('${widget.players[i].emoji} ${_styles[i - 1]}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(widget.players[i].name,
                        style: TextStyle(
                            color: t.text, fontWeight: FontWeight.w800, fontSize: 13)),
                    Text('$_stacks[i] 🪙',
                        style: TextStyle(color: t.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final c in _hole.isEmpty ? <_PCard>[] : _hole[i])
                          _cardSlot(c, faceDown: !_showdown),
                      ],
                    ),
                    Text(
                      _inHand.isNotEmpty && !_inHand[i]
                          ? 'folded 🚪'
                          : _allIn[i]
                              ? 'ALL-IN! 😬'
                              : '',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // community
        Text('Community Cards 🃏',
            style: TextStyle(color: t.muted, fontWeight: FontWeight.w800, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < 5; k++)
              _cardSlot(k < _community.length ? _community[k] : null),
          ],
        ),
        const SizedBox(height: 6),
        Text(_msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 13)),
        const Spacer(),
        // player hole
        Text('😎 Your hand • $_stacks[0] 🪙',
            style: TextStyle(color: t.muted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final c in _hole.isEmpty ? <_PCard>[] : _hole[0])
              _cardSlot(c),
          ],
        ),
        const SizedBox(height: 10),
        if (_awaiting) ...[
          Text(
              _awaitToCall > 0 ? 'Call $_awaitToCall to stay in 👀' : 'Free peek — check or get spicy! 🌶️',
              style: TextStyle(color: t.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WajihaButton(label: 'Fold 🚪', onTap: () => _humanAct(_Act.fold), primary: false, fontSize: 15),
              const SizedBox(width: 8),
              WajihaButton(
                  label: _awaitToCall > 0 ? 'Call $_awaitToCall 📞' : 'Check ✋',
                  onTap: () => _humanAct(_Act.checkCall),
                  fontSize: 15),
              const SizedBox(width: 8),
              WajihaButton(
                  label: 'Raise 🔥',
                  onTap: _stacks[0] > _awaitToCall ? () => _humanAct(_Act.raise) : () {},
                  primary: _stacks[0] > _awaitToCall,
                  fontSize: 15),
            ],
          ),
        ] else if (!_inProgress && !_over)
          WajihaButton(label: 'Walk Away a Legend 🤠', emoji: '🌵', onTap: _walkAway, fontSize: 16)
        else
          Text(_inProgress ? 'Bots are scheming… 🕵️' : 'Shuffling up… 🃏',
              style: TextStyle(color: t.muted, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
      ],
    );
  }
}
