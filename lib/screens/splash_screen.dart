import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';
import 'menu_screen.dart';

/// SINGLE splash, two moments: first the WAJIHA company mark, then the game
/// splash (logo + name + animated loading line + "Credits: WAJIHA").
class SplashScreen extends StatefulWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyMoment = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the company moment shows, then menu music.
    widget.audio.prewarm();
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyMoment = false);
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    return Scaffold(
      backgroundColor: const Color(0xFF120C06),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _companyMoment
            ? _CompanyMoment(key: const ValueKey('company'))
            : _GameSplash(
                key: const ValueKey('game'),
                theme: theme,
                loader: _loader,
              ),
      ),
    );
  }
}

class _CompanyMoment extends StatelessWidget {
  const _CompanyMoment({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  offset: const Offset(0, 12),
                  blurRadius: 30,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/wajiha_logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 26),
          const Text(
            'WAJIHA',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: Color(0xFFE8CE7A),
              shadows: [
                Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 3),
                    blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'P R E S E N T S',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameSplash extends StatelessWidget {
  final PokerThemeDef theme;
  final AnimationController loader;
  const _GameSplash({super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return FeltBackdrop(
      theme: theme,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.accent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/lonestarpoker_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text('LONE STAR POKER', style: Saloon.display(34, theme: theme)),
              const SizedBox(height: 6),
              Text(
                'TEXAS HOLD\u2019EM SHOWDOWNS',
                style: Saloon.label(13, theme: theme),
              ),
              const SizedBox(height: 28),
              // Animated loading line.
              SizedBox(
                width: 230,
                child: AnimatedBuilder(
                  animation: loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black.withValues(alpha: 0.5),
                          border: Border.all(
                              color: theme.accent.withValues(alpha: 0.6)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [theme.accentLight, theme.accent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loader.value < 1
                            ? 'Shuffling the deck\u2026'
                            : 'Take your seat!',
                        style: Saloon.body(13, theme: theme),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/wajiha_logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Saloon.label(14, theme: theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
