import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';
import 'pro_screen.dart';

/// Theme / card-back / chip-style picker + custom theme creator.
/// 14 felt themes, 9 card backs, 6 chip styles. Pro-only items are locked
/// in the free version and open the Pro screen.
class ThemesScreen extends StatelessWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const ThemesScreen(
      {super.key, required this.audio, required this.settings});

  void _goPro(BuildContext context) {
    audio.click();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ProScreen(audio: audio, settings: settings)));
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _section(theme, 'FELT THEMES'),
                      _themeGrid(context, theme),
                      const SizedBox(height: 18),
                      _section(theme, 'MY CUSTOM THEME'),
                      _customCard(context, theme),
                      const SizedBox(height: 18),
                      _section(theme, 'CARD BACKS'),
                      _cardBackGrid(context, theme),
                      const SizedBox(height: 18),
                      _section(theme, 'CHIP STYLES'),
                      _chipGrid(context, theme),
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
          Text('DRESS THE TABLE', style: Saloon.display(22, theme: theme)),
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

  // ------------------------------------------------------------ themes
  Widget _themeGrid(BuildContext context, PokerThemeDef theme) {
    final isPro = settings.isPro;
    final items = [...PokerThemes.all];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final t = items[i];
        final locked = t.proOnly && !isPro;
        final selected = settings.themeId == t.id;
        return GestureDetector(
          onTap: () {
            if (locked) {
              _goPro(context);
              return;
            }
            audio.click();
            settings.setTheme(t.id);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? theme.accentLight : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  offset: const Offset(0, 4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [t.feltTop, t.feltBottom],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Text(
                        t.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (locked)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: Icon(Icons.lock,
                            color: Colors.white70, size: 26),
                      ),
                    ),
                  if (selected)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _customCard(BuildContext context, PokerThemeDef theme) {
    final isPro = settings.isPro;
    final selected = settings.themeId == 'custom';
    return GestureDetector(
      onTap: () {
        if (!isPro) {
          _goPro(context);
          return;
        }
        audio.click();
        settings.setTheme('custom');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.accentLight : theme.accent.withValues(alpha: 0.5),
            width: selected ? 3 : 1.5,
          ),
          color: Colors.black.withValues(alpha: 0.35),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    settings.customTheme.feltTop,
                    settings.customTheme.feltBottom
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border:
                    Border.all(color: theme.accent.withValues(alpha: 0.6)),
              ),
              child: isPro
                  ? null
                  : const Icon(Icons.lock, color: Colors.white70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Creation',
                      style: Saloon.title(16, theme: theme)),
                  Text(
                    isPro
                        ? 'Your colors, your felt. Tap to edit.'
                        : 'A Pro feature \u2014 design your own felt.',
                    style: Saloon.body(12, theme: theme),
                  ),
                ],
              ),
            ),
            if (isPro)
              Saloon.iconButton(
                theme: theme,
                icon: Icons.edit,
                size: 42,
                onTap: () {
                  audio.click();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CustomThemeScreen(
                          audio: audio, settings: settings)));
                },
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ card backs
  Widget _cardBackGrid(BuildContext context, PokerThemeDef theme) {
    final isPro = settings.isPro;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: CardStyles.all.length,
      itemBuilder: (_, i) {
        final c = CardStyles.all[i];
        final locked = c.proOnly && !isPro;
        final selected = settings.cardStyleId == c.id;
        return GestureDetector(
          onTap: () {
            if (locked) {
              _goPro(context);
              return;
            }
            audio.click();
            settings.setCardStyle(c.id);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? theme.accentLight : Colors.transparent,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: PlayingCardWidget(
                      card: null,
                      theme: theme,
                      cardStyle: c,
                      width: 52,
                    ),
                  ),
                  if (locked)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: Icon(Icons.lock,
                            color: Colors.white70, size: 24),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Text(
                        c.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ chips
  Widget _chipGrid(BuildContext context, PokerThemeDef theme) {
    final isPro = settings.isPro;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: ChipStyles.all.length,
      itemBuilder: (_, i) {
        final c = ChipStyles.all[i];
        final locked = c.proOnly && !isPro;
        final selected = settings.chipStyleId == c.id;
        return GestureDetector(
          onTap: () {
            if (locked) {
              _goPro(context);
              return;
            }
            audio.click();
            settings.setChipStyle(c.id);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? theme.accentLight : Colors.transparent,
                width: 3,
              ),
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChipWidget(
                          theme: theme,
                          style: c,
                          amount: 100,
                          size: 54),
                      const SizedBox(height: 6),
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (locked)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.lock, color: Colors.white70, size: 24),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom theme creator: pick every felt color from curated swatches.
class CustomThemeScreen extends StatelessWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  static const _labels = {
    'feltTop': 'Felt light',
    'feltBottom': 'Felt dark',
    'railWood': 'Rail wood',
    'railDark': 'Rail shadow',
    'accent': 'Brass accent',
    'accentLight': 'Accent highlight',
    'cardFront': 'Card face',
    'cardBack': 'Card back',
    'textOnFelt': 'Table text',
    'chipEdge': 'Chip edge',
  };

  // Curated western palette swatches (no neon).
  static const _swatches = [
    0xFF2E6B46, 0xFF1D4A2F, 0xFF3E6B4F, 0xFF26432F, // greens
    0xFF8E1F2F, 0xFF5B2A1E, 0xFF9C3D2E, 0xFF66241B, // reds
    0xFF1F5C5C, 0xFF123B3B, 0xFF2E4A7A, 0xFF1B2C4E, // teals/blues
    0xFFB4692A, 0xFF7E4418, 0xFF7A5230, 0xFF4E3319, // ambers
    0xFF6B4226, 0xFF3E2412, 0xFF4A4A48, 0xFF2A2A28, // woods/smoke
    0xFFC9A227, 0xFFE8CE7A, 0xFFF2C14E, 0xFFFFE3A1, // brass
    0xFFFFFDF4, 0xFFF5EFE0, 0xFFE8E0C8, 0xFF9A865C, // ivories
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
                    Text('MY CREATION', style: Saloon.display(22, theme: theme)),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (_, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Text(
                        'Tap a row, then pick a color. Your theme applies instantly everywhere.',
                        style: Saloon.body(13, theme: theme),
                      ),
                      const SizedBox(height: 12),
                      for (final key in _labels.keys)
                        _colorRow(context, theme, key),
                      const SizedBox(height: 16),
                      Saloon.button(
                        theme: theme,
                        text: 'Use this theme',
                        icon: Icons.check,
                        onTap: () {
                          audio.gameStart();
                          settings.setTheme('custom');
                          Navigator.of(context).pop();
                        },
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

  Widget _colorRow(
      BuildContext context, PokerThemeDef theme, String key) {
    final current = settings.customColors[key] ?? 0xFF000000;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.35),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(current),
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(_labels[key]!,
                  style: Saloon.title(15, theme: theme)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sw in _swatches)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    settings.setCustomColor(key, sw);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Color(sw),
                      border: Border.all(
                        color: sw == current
                            ? theme.accentLight
                            : Colors.white24,
                        width: sw == current ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
