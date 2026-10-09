import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/poker_themes.dart';
import '../theme/saloon_art.dart';

/// Pro upsell: Free-vs-Pro comparison, real Play Billing purchases,
/// and the tip jar. Graceful when the store isn't configured yet.
class ProScreen extends StatefulWidget {
  final SaloonAudio audio;
  final PokerSettings settings;
  const ProScreen({super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;

  static const _comparison = [
    ('Full Texas Hold\u2019em game', true, true),
    ('3 bot difficulties (Greenhorn / Sharp / Legend)', true, true),
    ('Pass-and-play with friends', true, true),
    ('6 felt themes, 4 card backs, 3 chip styles', true, true),
    ('Renameable players', true, true),
    ('8 more felt themes (Gold Rush, Bluebonnet\u2026)', false, true),
    ('Custom theme creator \u2014 your colors', false, true),
    ('5 more card backs + 3 more chip styles', false, true),
    ('5\u20136 seat tables', false, true),
    ('Tournament blinds mode', false, true),
  ];

  @override
  void initState() {
    super.initState();
    _store.proPurchased.addListener(_onProPurchased);
    _store.lastThanks.addListener(_onThanks);
    _init();
  }

  Future<void> _init() async {
    await _store.init();
    if (mounted) setState(() => _loading = false);
  }

  void _onProPurchased() {
    if (_store.proPurchased.value) {
      widget.settings.setPro(true);
      widget.audio.win();
    }
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      _store.lastThanks.value = null;
    }
  }

  @override
  void dispose() {
    _store.proPurchased.removeListener(_onProPurchased);
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.theme;
    final isPro = widget.settings.isPro;
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
                        widget.audio.click();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 12),
                    Text('LONE STAR PRO',
                        style: Saloon.display(22, theme: theme)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (isPro) _proBadge(theme),
                    _comparisonCard(theme),
                    const SizedBox(height: 18),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _storeSection(theme, isPro),
                    const SizedBox(height: 18),
                    _tipJar(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _proBadge(PokerThemeDef theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.accent.withValues(alpha: 0.18),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: theme.accent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\u2019re PRO, partner. Every theme, back and chip style is unlocked.',
              style: Saloon.body(14, theme: theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonCard(PokerThemeDef theme) {
    Widget tick(bool yes) => Icon(
          yes ? Icons.check_circle : Icons.remove_circle_outline,
          color: yes ? const Color(0xFF7CB87C) : Colors.white24,
          size: 20,
        );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.4),
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13)),
              color: theme.accent.withValues(alpha: 0.15),
            ),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                    width: 64,
                    child: Text('FREE',
                        textAlign: TextAlign.center,
                        style: Saloon.label(11, theme: theme))),
                SizedBox(
                    width: 64,
                    child: Text('PRO',
                        textAlign: TextAlign.center,
                        style: Saloon.label(11, theme: theme))),
              ],
            ),
          ),
          for (final row in _comparison)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.$1,
                        style: Saloon.body(13, theme: theme)),
                  ),
                  SizedBox(width: 64, child: Center(child: tick(row.$2))),
                  SizedBox(width: 64, child: Center(child: tick(row.$3))),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _storeSection(PokerThemeDef theme, bool isPro) {
    if (!_store.available || !_store.storeReady) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(
              color: theme.accent.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront,
                color: theme.accent.withValues(alpha: 0.7), size: 34),
            const SizedBox(height: 8),
            Text(
              _store.error ?? 'Store is getting ready\u2026',
              style: Saloon.body(14, theme: theme),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Purchases unlock here as soon as the products are live in Play Console.',
              style: Saloon.body(12, theme: theme),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    final pro = _store.proProduct;
    return Column(
      children: [
        if (!isPro && pro != null)
          _buyRow(
            theme,
            title: 'Lone Star PRO',
            subtitle: '${pro.title} \u2014 one-time unlock, yours forever.',
            price: pro.price,
            busy: _store.purchaseInProgress.value,
            onTap: () {
              widget.audio.click();
              _store.buyPro();
            },
          ),
        if (!isPro)
          TextButton(
            onPressed: () {
              widget.audio.click();
              _store.restore();
            },
            child: Text('Restore purchases',
                style: TextStyle(
                    color: theme.accentLight,
                    fontWeight: FontWeight.w700)),
          ),
        ValueListenableBuilder<String?>(
          valueListenable: _store.purchaseError,
          builder: (_, err, _) => err == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(err,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
        ),
      ],
    );
  }

  Widget _tipJar(PokerThemeDef theme) {
    if (!_store.storeReady) return const SizedBox.shrink();
    final coffee = _store.coffeeProduct;
    final chocolate = _store.chocolateProduct;
    if (coffee == null && chocolate == null) {
      return const SizedBox.shrink();
    }
    Widget tip(ProductDetails p, IconData icon, String label) {
      return Expanded(
        child: GestureDetector(
          onTap: () {
            widget.audio.click();
            _store.buyTip(p);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                  color: theme.accent.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(icon, color: theme.accentLight, size: 28),
                const SizedBox(height: 6),
                Text(label, style: Saloon.title(14, theme: theme)),
                Text(p.price, style: Saloon.body(12, theme: theme)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIP JAR', style: Saloon.label(13, theme: theme)),
        const SizedBox(height: 8),
        Text(
          'Made by an indie maker with love. Tips keep the saloon open \u2014 never required, always appreciated.',
          style: Saloon.body(12, theme: theme),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (coffee != null) tip(coffee, Icons.coffee, 'Coffee'),
            if (coffee != null && chocolate != null)
              const SizedBox(width: 10),
            if (chocolate != null)
              tip(chocolate, Icons.cookie, 'Chocolate'),
          ],
        ),
      ],
    );
  }

  Widget _buyRow(PokerThemeDef theme,
      {required String title,
      required String subtitle,
      required String price,
      required bool busy,
      required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            theme.accent.withValues(alpha: 0.25),
            theme.accent.withValues(alpha: 0.08)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: theme.accent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Saloon.title(18, theme: theme)),
                    Text(subtitle, style: Saloon.body(12, theme: theme)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Saloon.button(
              theme: theme,
              text: busy ? 'Working\u2026' : 'Unlock Pro \u2014 $price',
              icon: Icons.lock_open,
              onTap: busy ? null : onTap,
            ),
          ),
        ],
      ),
    );
  }
}
