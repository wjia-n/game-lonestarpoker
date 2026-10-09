import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/saloon_art.dart';

/// How-to-play, condensed from RULES.md (the authoritative rules live there).
class RulesScreen extends StatelessWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const RulesScreen(
      {super.key, required this.audio, required this.settings});

  static const _sections = [
    (
      'Objective',
      'Win all the chips. Take a hand with the best 5-card poker hand at showdown \u2014 or be the last player who hasn\u2019t folded. Chips are 100% virtual; no real money, ever.'
    ),
    (
      'Setup',
      '2\u20136 seats. Vs Bots: you + 1\u20135 bots. Pass-and-Play: 2\u20136 humans. Everyone starts with 500 chips. Small blind 5, big blind 10, posted automatically. The dealer button rotates after every hand. Tournament mode doubles the blinds every 10 hands.'
    ),
    (
      'Turn order',
      'Pre-flop, the player left of the big blind acts first; later streets start left of the button. Heads-up, the button posts the small blind and acts first pre-flop. A betting round ends when everyone still in has matched the bet (or folded / gone all-in).'
    ),
    (
      'Legal moves',
      'Fold (give up), Check (pass \u2014 only when nobody bet), Call (match the bet), Raise (at least the big blind, or the size of the last raise), All-in (push your whole stack any time).'
    ),
    (
      'Illegal moves',
      'You can\u2019t check into a bet, call more than your stack (you\u2019ll go all-in instead), raise below the minimum, or act out of turn \u2014 the table only listens to the current player.'
    ),
    (
      'Side pots',
      'An all-in player can only win pots they contributed to. Extra chips form side pots contested by everyone still in. If betting is impossible, the board is dealt out automatically.'
    ),
    (
      'Showdown',
      'Best 5 cards from your 2 hole cards + 5 community cards wins. Hand ranks: High card < Pair < Two pair < Three of a kind < Straight < Flush < Full house < Four of a kind < Straight flush. Aces play high or low; kickers break ties.'
    ),
    (
      'Winning & draws',
      'Tied hands split the pot evenly; an odd chip goes to the tied player closest left of the button. Vs Bots: the game ends when you\u2019re broke or every bot is. Pass-and-Play: play as many hands as you like \u2014 richest rider leads.'
    ),
    (
      'The bots',
      'Greenhorn plays loose and calls too much \u2014 perfect for learning. Sharp plays its cards and folds the junk. Legend weighs pot odds and position, value-bets thin, and bluffs scary boards when you check to it.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = settings.theme;
    return Scaffold(
      body: FeltBackdrop(
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(
                  children: [
                    Saloon.iconButton(
                      theme: theme,
                      icon: Icons.arrow_back,
                      size: 42,
                      onTap: () {
                        audio.click();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Text('HOW TO PLAY',
                        style: Saloon.display(22, theme: theme)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    for (final s in _sections) ...[
                      Text(s.$1.toUpperCase(),
                          style: Saloon.label(13, theme: theme)),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.35),
                          border: Border.all(
                              color: theme.accent.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: Text(s.$2,
                            style: Saloon.body(14, theme: theme)
                                .copyWith(height: 1.45)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
