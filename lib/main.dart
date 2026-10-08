import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const LoneStarPokerApp());

class LoneStarPokerApp extends StatelessWidget {
  const LoneStarPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.neonArcade,
      title: 'Lone Star Poker',
      tagline: 'Howdy, partner! Out-bluff three crafty bots in Texas-style showdowns. 🤠',
      emoji: '♠️',
      slug: 'lonestarpoker',
      howToPlay:
          '• You + 3 bot rivals, 500 chips each. Blinds 5/10 keep it spicy. 🌶️\n• Two hole cards, then the flop, turn and river hit the felt.\n• Bet with Fold, Check/Call, or Raise. Bots bluff — trust no one! 👀\n• Best 5-card hand wins the pot at showdown.\n• Go broke and the game\'s over. Feeling rich? Walk away like a legend! 🤠',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => LoneStarPokerScreen(players: players, callbacks: cb),
    );
  }
}
