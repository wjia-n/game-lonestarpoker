import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';
import 'pro_screen.dart';import 'rules_screen.dart';
import 'settings_screen.dart';
import 'setup_screen.dart';
import 'themes_screen.dart';

/// Main menu: bold western-saloon front door to the game.
class MenuScreen extends StatefulWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.lonestarpoker';

  @override
  void initState() {
    super.initState();
    // Menu music is app-scoped: (re)start it whenever we land on the menu.
    widget.audio.startMenuMusic();
  }

  Future<void> _share() async {
    widget.audio.click();
    await SharePlus.instance.share(
      ShareParams(
        text:
            'I\u2019m playing Lone Star Poker \u2014 Texas Hold\u2019em showdowns, crafty bots, zero real money. Take your seat!\n$_storeUrl',
        subject: 'Lone Star Poker',
      ),
    );
  }

  Future<void> _rate() async {
    widget.audio.click();
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
    } catch (_) {
      await SharePlus.instance
          .share(ShareParams(text: _storeUrl));
    }
  }

  void _go(Widget page) {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    final s = widget.settings;
    return Scaffold(
      body: FeltBackdrop(
        theme: theme,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/lonestarpoker_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                  Text('LONE STAR POKER',
                      style: Saloon.display(30, theme: theme),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('TEXAS HOLD\u2019EM SHOWDOWNS',
                      style: Saloon.label(12, theme: theme)),
                  const SizedBox(height: 26),
                  Saloon.button(
                    theme: theme,
                    text: 'Play vs Bots',
                    icon: Icons.casino,
                    onTap: () => _go(SetupScreen(
                        audio: widget.audio,
                        settings: widget.settings,
                        passPlay: false)),
                  ),
                  const SizedBox(height: 14),
                  Saloon.button(
                    theme: theme,
                    text: 'Pass & Play',
                    icon: Icons.people,
                    primary: false,
                    onTap: () => _go(SetupScreen(
                        audio: widget.audio,
                        settings: widget.settings,
                        passPlay: true)),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _menuChip(theme, Icons.palette, 'Themes', () {
                        _go(ThemesScreen(
                            audio: widget.audio, settings: widget.settings));
                      }),
                      _menuChip(theme, Icons.settings, 'Settings', () {
                        _go(SettingsScreen(
                            audio: widget.audio, settings: widget.settings));
                      }),
                      _menuChip(theme, Icons.star, 'Go Pro', () {
                        _go(ProScreen(
                            audio: widget.audio, settings: widget.settings));
                      }),
                      _menuChip(theme, Icons.menu_book, 'How to Play',
                          () {
                        _go(RulesScreen(
                            audio: widget.audio, settings: widget.settings));
                      }),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _statsStrip(theme, s),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Saloon.iconButton(
                          theme: theme, icon: Icons.share, onTap: _share),
                      const SizedBox(width: 18),
                      Saloon.iconButton(
                          theme: theme,
                          icon: Icons.star_rate,
                          onTap: _rate),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Chips are 100% virtual \u2014 no real money, ever.',
                      style: Saloon.body(11, theme: theme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuChip(PokerThemeDef theme, IconData icon, String label,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
              color: theme.accent.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.accentLight, size: 18),
            const SizedBox(width: 8),
            Text(label, style: Saloon.body(14, theme: theme)),
          ],
        ),
      ),
    );
  }

  Widget _statsStrip(PokerThemeDef theme, PokerSettings s) {
    Widget stat(String label, String value) => Column(
          children: [
            Text(value, style: Saloon.title(18, theme: theme)),
            Text(label.toUpperCase(),
                style: Saloon.label(9, theme: theme)),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          stat('Hands', '${s.handsPlayed}'),
          stat('Won', '${s.handsWon}'),
          stat('Biggest pot', '${s.biggestPot}'),
          stat('Tables cleared', '${s.gamesWon}'),
        ],
      ),
    );
  }
}
