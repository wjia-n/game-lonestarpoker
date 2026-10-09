import 'package:flutter/material.dart';
import '../engine/poker_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';
import 'game_screen.dart';
import 'pro_screen.dart';

/// Pre-game setup: vs bots or pass-and-play, seats, difficulty, tournament,
/// and renameable players (saved on every keystroke).
class SetupScreen extends StatefulWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  final bool passPlay;
  const SetupScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.passPlay});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late bool _passPlay;
  final List<TextEditingController> _nameControllers = [];
  final List<FocusNode> _focusNodes = [];

  static const _difficulties = ['Greenhorn', 'Sharp', 'Legend'];
  static const _difficultyBlurb = [
    'Loose and friendly \u2014 great for learning.',
    'Plays its cards \u2014 a real challenge.',
    'Tight, observant, and bluffs scary boards.',
  ];

  @override
  void initState() {
    super.initState();
    _passPlay = widget.passPlay;
    for (int i = 0; i < PokerSettings.maxSeats; i++) {
      final c = TextEditingController(text: widget.settings.playerNames[i]);
      final f = FocusNode();
      // Commit on focus loss (we already save on every keystroke).
      f.addListener(() {
        if (!f.hasFocus) {
          widget.settings.setPlayerName(i, c.text);
        }
      });
      _nameControllers.add(c);
      _focusNodes.add(f);
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  int get _seatCount =>
      _passPlay ? widget.settings.humanCount : widget.settings.botCount + 1;

  /// Free tier caps tables at 4 seats; Pro unlocks 5\u20136.
  int get _maxSeatsFree => 4;

  void _start() {
    widget.audio.gameStart();
    final s = widget.settings;
    final seats = <SeatConfig>[];
    for (int i = 0; i < _seatCount; i++) {
      final isHuman = _passPlay || i == 0;
      seats.add(SeatConfig(
        name: s.playerNames[i],
        isHuman: isHuman,
        difficulty: isHuman ? 1 : s.difficulty,
      ));
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: s,
          config: GameConfig(
            seats: seats,
            tournament: s.tournament,
          ),
          passPlay: _passPlay,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    final s = widget.settings;
    final isPro = s.isPro;
    final maxCount = _passPlay
        ? (isPro ? 6 : _maxSeatsFree)
        : (isPro ? 5 : 3); // bots; +1 human seat
    return Scaffold(
      body: FeltBackdrop(
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              _header(theme),
              Expanded(
                child: ListenableBuilder(
                  listenable: s,
                  builder: (_, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      _modeToggle(theme),
                      const SizedBox(height: 18),
                      _sectionTitle(theme, _passPlay ? 'Players' : 'Rivals'),
                      _stepper(
                        theme,
                        label: _passPlay ? 'Humans' : 'Bots',
                        value: _passPlay ? s.humanCount : s.botCount,
                        min: _passPlay ? 2 : 1,
                        max: maxCount,
                        onChanged: (v) {
                          widget.audio.click();
                          if (_passPlay) {
                            s.setHumanCount(v);
                          } else {
                            s.setBotCount(v);
                          }
                        },
                      ),
                      if (!_passPlay) ...[
                        const SizedBox(height: 14),
                        _sectionTitle(theme, 'Bot skill'),
                        _difficultyPicker(theme, s),
                      ],
                      const SizedBox(height: 14),
                      _sectionTitle(theme, 'Tournament blinds'),
                      _tournamentRow(theme, s, isPro),
                      const SizedBox(height: 14),
                      _sectionTitle(theme, 'Who\u2019s playing?'),
                      Text(
                        'Tap a name to rename. Saved automatically.',
                        style: Saloon.body(12, theme: theme),
                      ),
                      const SizedBox(height: 8),
                      ..._nameFields(theme, s),
                      if (!isPro &&
                          ((_passPlay && s.humanCount >= _maxSeatsFree) ||
                              (!_passPlay && s.botCount >= 3)))
                        _proNudge(theme),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: Saloon.button(
                    theme: theme,
                    text: 'Take your seat',
                    icon: Icons.play_arrow,
                    onTap: _start,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(PokerThemeDef theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          Saloon.iconButton(
            theme: theme,
            icon: Icons.arrow_back,
            size: 42,
            onTap: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 12),
          Text('TABLE SETUP', style: Saloon.display(22, theme: theme)),
        ],
      ),
    );
  }

  Widget _sectionTitle(PokerThemeDef theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: Saloon.label(13, theme: theme)),
    );
  }

  Widget _modeToggle(PokerThemeDef theme) {
    Widget opt(bool selected, String label, IconData icon, VoidCallback tap) {
      return Expanded(
        child: GestureDetector(
          onTap: tap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? theme.accent
                  : Colors.black.withValues(alpha: 0.35),
              border: Border.all(
                  color: selected
                      ? theme.accentLight
                      : theme.accent.withValues(alpha: 0.4),
                  width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: selected ? theme.railDark : theme.accentLight,
                    size: 20),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color:
                            selected ? theme.railDark : theme.accentLight)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        opt(!_passPlay, 'Vs Bots', Icons.casino, () {
          widget.audio.click();
          setState(() => _passPlay = false);
        }),
        const SizedBox(width: 10),
        opt(_passPlay, 'Pass & Play', Icons.people, () {
          widget.audio.click();
          setState(() => _passPlay = true);
        }),
      ],
    );
  }

  Widget _stepper(PokerThemeDef theme,
      {required String label,
      required int value,
      required int min,
      required int max,
      required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Saloon.title(16, theme: theme))),
          Saloon.iconButton(
              theme: theme,
              icon: Icons.remove,
              size: 38,
              onTap: value > min ? () => onChanged(value - 1) : null),
          SizedBox(
              width: 44,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: Saloon.display(22, theme: theme))),
          Saloon.iconButton(
              theme: theme,
              icon: Icons.add,
              size: 38,
              onTap: value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }

  Widget _difficultyPicker(PokerThemeDef theme, PokerSettings s) {
    return Column(
      children: [
        Row(
          children: List.generate(3, (i) {
            final selected = s.difficulty == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  widget.audio.click();
                  s.setDifficulty(i);
                },
                child: Container(
                  margin: EdgeInsets.only(
                      left: i == 0 ? 0 : 5, right: i == 2 ? 0 : 5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? theme.accent
                        : Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                        color: selected
                            ? theme.accentLight
                            : theme.accent.withValues(alpha: 0.4),
                        width: 2),
                  ),
                  child: Center(
                    child: Text(_difficulties[i],
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? theme.railDark
                                : theme.accentLight)),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(_difficultyBlurb[s.difficulty],
            style: Saloon.body(12, theme: theme),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _tournamentRow(
      PokerThemeDef theme, PokerSettings s, bool isPro) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        if (!isPro) {
          _showProGate();
          return;
        }
        s.setTournament(!s.tournament);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.35),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tournament blinds',
                          style: Saloon.title(16, theme: theme)),
                      if (!isPro) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star,
                            size: 16, color: theme.accent),
                      ],
                    ],
                  ),
                  Text('Blinds double every 10 hands.',
                      style: Saloon.body(12, theme: theme)),
                ],
              ),
            ),
            Switch(
              value: s.tournament && isPro,
              activeTrackColor: theme.accent,
              onChanged: (_) {
                widget.audio.click();
                if (!isPro) {
                  _showProGate();
                  return;
                }
                s.setTournament(!s.tournament);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _nameFields(PokerThemeDef theme, PokerSettings s) {
    return List.generate(_seatCount, (i) {
      final isHuman = _passPlay || i == 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.35),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHuman ? theme.accent : theme.railWood,
                border: Border.all(color: theme.accentLight, width: 1.5),
              ),
              child: Center(
                child: Text(
                  (s.playerNames[i].isNotEmpty
                          ? s.playerNames[i][0]
                          : '?')
                      .toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color:
                          isHuman ? theme.railDark : theme.accentLight),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameControllers[i],
                focusNode: _focusNodes[i],
                style: Saloon.body(16, theme: theme),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: isHuman ? 'Player ${i + 1}' : 'Bot ${i + 1}',
                  hintStyle: Saloon.body(16, theme: theme).copyWith(
                      color: theme.textOnFelt.withValues(alpha: 0.35)),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 14,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    const SizedBox.shrink(),
                // Save on EVERY keystroke (never only on keyboard-done).
                onChanged: (v) => s.setPlayerName(i, v),
              ),
            ),
            Icon(isHuman ? Icons.person : Icons.smart_toy,
                color: theme.accent.withValues(alpha: 0.7), size: 20),
          ],
        ),
      );
    });
  }

  Widget _proNudge(PokerThemeDef theme) {
    return GestureDetector(
      onTap: () {
        widget.audio.click();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                ProScreen(audio: widget.audio, settings: widget.settings)));
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.accent.withValues(alpha: 0.15),
          border: Border.all(color: theme.accent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: theme.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Go Pro for 5\u20136 seat tables, tournament blinds and every theme.',
                style: Saloon.body(13, theme: theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProGate() {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ProScreen(audio: widget.audio, settings: widget.settings)));
  }
}
