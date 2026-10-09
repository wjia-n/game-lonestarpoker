import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = PokerSettings();
  await settings.load();
  final audio = SaloonAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(LoneStarPokerApp(settings: settings, audio: audio));
}

class LoneStarPokerApp extends StatefulWidget {
  final PokerSettings settings;
  final SaloonAudio audio;
  const LoneStarPokerApp(
      {super.key, required this.settings, required this.audio});

  @override
  State<LoneStarPokerApp> createState() => _LoneStarPokerAppState();
}

class _LoneStarPokerAppState extends State<LoneStarPokerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; the game screen additionally freezes its engine.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Lone Star Poker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: widget.settings.theme.feltBottom,
          colorScheme: ColorScheme.fromSeed(
            seedColor: widget.settings.theme.accent,
            brightness: Brightness.dark,
          ),
        ),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
