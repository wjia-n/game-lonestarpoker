import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';

/// Audio controls and app preferences.
class SettingsScreen extends StatelessWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  void _applyAudio() {
    audio.configure(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      volume: settings.volume,
    );
    if (settings.musicOn) {
      audio.startMenuMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = settings.theme;
    return Scaffold(
      body: FeltBackdrop(
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              _header(context, theme),
              Expanded(
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (_, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      _section(theme, 'MUSIC & SOUND'),
                      _toggleRow(
                        theme,
                        icon: Icons.music_note,
                        label: 'Music',
                        value: settings.musicOn,
                        onChanged: (v) {
                          audio.click();
                          settings.setMusic(v);
                          _applyAudio();
                        },
                      ),
                      _toggleRow(
                        theme,
                        icon: Icons.volume_up,
                        label: 'Sound effects',
                        value: settings.sfxOn,
                        onChanged: (v) {
                          settings.setSfx(v);
                          _applyAudio();
                          audio.click();
                        },
                      ),
                      _volumeRow(theme),
                      const SizedBox(height: 18),
                      _section(theme, 'ABOUT'),
                      _infoRow(theme, 'Version', '1.0.0'),
                      _infoRow(theme, 'Chips',
                          '100% virtual \u2014 no real money, ever.'),
                      const SizedBox(height: 18),
                      _section(theme, 'DANGER ZONE'),
                      GestureDetector(
                        onTap: () => _confirmReset(context, theme),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.red.withValues(alpha: 0.12),
                            border: Border.all(
                                color: Colors.redAccent
                                    .withValues(alpha: 0.6),
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Text('Reset stats & names',
                                  style: Saloon.body(15, theme: theme)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, PokerThemeDef theme) {
    return Padding(
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
          Text('SETTINGS', style: Saloon.display(22, theme: theme)),
        ],
      ),
    );
  }

  Widget _section(PokerThemeDef theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: Saloon.label(13, theme: theme)),
    );
  }

  Widget _toggleRow(PokerThemeDef theme,
      {required IconData icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.accentLight),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Saloon.title(16, theme: theme))),
          Switch(
            value: value,
            activeTrackColor: theme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _volumeRow(PokerThemeDef theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, color: theme.accentLight),
          const SizedBox(width: 12),
          Expanded(
            child: Slider(
              value: settings.volume,
              activeColor: theme.accent,
              inactiveColor: theme.accent.withValues(alpha: 0.3),
              onChanged: (v) {
                settings.setVolume(v);
                _applyAudio();
              },
              onChangeEnd: (_) => audio.click(),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text('${(settings.volume * 100).round()}%',
                textAlign: TextAlign.right,
                style: Saloon.body(14, theme: theme)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(PokerThemeDef theme, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Saloon.title(15, theme: theme))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: Saloon.body(13, theme: theme)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, PokerThemeDef theme) async {
    audio.click();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.railDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: theme.accent, width: 2),
        ),
        title: Text('Reset everything?',
            style: Saloon.title(18, theme: theme)),
        content: Text(
          'Stats and player names go back to defaults. This cannot be undone.',
          style: Saloon.body(14, theme: theme),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('KEEP',
                style: TextStyle(
                    color: theme.accentLight, fontWeight: FontWeight.w800)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('RESET',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok == true) {
      for (int i = 0; i < PokerSettings.maxSeats; i++) {
        await settings.setPlayerName(
            i, PokerSettings.defaultNames[i % PokerSettings.defaultNames.length]);
      }
      await settings.resetStats();
    }
  }
}
