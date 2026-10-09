import 'package:flutter/material.dart';

/// Art direction: warm western saloon — aged wood, brass, felt, leather.
/// Pseudo-3D physical materials; no neon, no cyberpunk.
class PokerThemeDef {
  final String id;
  final String name;
  final bool proOnly;
  final Color feltTop;
  final Color feltBottom;
  final Color railWood;
  final Color railDark;
  final Color accent;
  final Color accentLight;
  final Color cardFront;
  final Color cardBack;
  final Color textOnFelt;
  final Color chipEdge;

  const PokerThemeDef({
    required this.id,
    required this.name,
    this.proOnly = false,
    required this.feltTop,
    required this.feltBottom,
    required this.railWood,
    required this.railDark,
    required this.accent,
    required this.accentLight,
    required this.cardFront,
    required this.cardBack,
    required this.textOnFelt,
    required this.chipEdge,
  });
}

class PokerThemes {
  static const List<PokerThemeDef> all = [
    PokerThemeDef(
      id: 'saloon',
      name: 'Old Saloon',
      feltTop: Color(0xFF2E6B46),
      feltBottom: Color(0xFF1D4A2F),
      railWood: Color(0xFF6B4226),
      railDark: Color(0xFF3E2412),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      cardFront: Color(0xFFFFFDF4),
      cardBack: Color(0xFF8E1F2F),
      textOnFelt: Color(0xFFF5EFE0),
      chipEdge: Color(0xFFC9A227),
    ),
    PokerThemeDef(
      id: 'desert',
      name: 'Desert Dusk',
      feltTop: Color(0xFFB4692A),
      feltBottom: Color(0xFF7E4418),
      railWood: Color(0xFF4E2E14),
      railDark: Color(0xFF2E1A0A),
      accent: Color(0xFFF2C14E),
      accentLight: Color(0xFFFFE3A1),
      cardFront: Color(0xFFFFF8EA),
      cardBack: Color(0xFF5B2A1E),
      textOnFelt: Color(0xFFFFF3DC),
      chipEdge: Color(0xFFF2C14E),
    ),
    PokerThemeDef(
      id: 'riverboat',
      name: 'Riverboat',
      feltTop: Color(0xFF1F5C5C),
      feltBottom: Color(0xFF123B3B),
      railWood: Color(0xFF5C3A21),
      railDark: Color(0xFF33200F),
      accent: Color(0xFFD9A441),
      accentLight: Color(0xFFF4D789),
      cardFront: Color(0xFFFFFDF6),
      cardBack: Color(0xFF1E3A5F),
      textOnFelt: Color(0xFFEFF7F2),
      chipEdge: Color(0xFFD9A441),
    ),
    PokerThemeDef(
      id: 'ranch',
      name: 'Ranch House',
      feltTop: Color(0xFF7A8B3F),
      feltBottom: Color(0xFF4E5C26),
      railWood: Color(0xFF6E4A2A),
      railDark: Color(0xFF402818),
      accent: Color(0xFFE0B34C),
      accentLight: Color(0xFFF7DE9A),
      cardFront: Color(0xFFFFFEF8),
      cardBack: Color(0xFF6B4226),
      textOnFelt: Color(0xFFF8F4E4),
      chipEdge: Color(0xFFE0B34C),
    ),
    PokerThemeDef(
      id: 'midnight',
      name: 'Midnight Oil',
      feltTop: Color(0xFF2B3A55),
      feltBottom: Color(0xFF16202F),
      railWood: Color(0xFF3A2A1A),
      railDark: Color(0xFF1E1409),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      cardFront: Color(0xFFF4F1E6),
      cardBack: Color(0xFF232F45),
      textOnFelt: Color(0xFFEDEAE0),
      chipEdge: Color(0xFF8A93A8),
    ),
    PokerThemeDef(
      id: 'canyon',
      name: 'Canyon Red',
      feltTop: Color(0xFF9C3D2E),
      feltBottom: Color(0xFF66241B),
      railWood: Color(0xFF4A2C17),
      railDark: Color(0xFF2A1809),
      accent: Color(0xFFF0BE4A),
      accentLight: Color(0xFFFFE0A0),
      cardFront: Color(0xFFFFFBF0),
      cardBack: Color(0xFF7A1F1F),
      textOnFelt: Color(0xFFFFF0DC),
      chipEdge: Color(0xFFF0BE4A),
    ),
    PokerThemeDef(
      id: 'goldrush',
      name: 'Gold Rush',
      proOnly: true,
      feltTop: Color(0xFF8A6D1A),
      feltBottom: Color(0xFF5C4A10),
      railWood: Color(0xFF3E2A12),
      railDark: Color(0xFF241708),
      accent: Color(0xFFFFD75E),
      accentLight: Color(0xFFFFF0B0),
      cardFront: Color(0xFFFFFDF2),
      cardBack: Color(0xFF4A3808),
      textOnFelt: Color(0xFFFFF6DC),
      chipEdge: Color(0xFFFFD75E),
    ),
    PokerThemeDef(
      id: 'sagebrush',
      name: 'Sagebrush',
      proOnly: true,
      feltTop: Color(0xFF5F7A5A),
      feltBottom: Color(0xFF3B4E38),
      railWood: Color(0xFF5A3D22),
      railDark: Color(0xFF33200F),
      accent: Color(0xFFD8C27A),
      accentLight: Color(0xFFF2E3AE),
      cardFront: Color(0xFFFBF8EC),
      cardBack: Color(0xFF3B4E38),
      textOnFelt: Color(0xFFF2F0E2),
      chipEdge: Color(0xFFD8C27A),
    ),
    PokerThemeDef(
      id: 'mesquite',
      name: 'Mesquite Smoke',
      proOnly: true,
      feltTop: Color(0xFF4A4A48),
      feltBottom: Color(0xFF2A2A28),
      railWood: Color(0xFF5C3A21),
      railDark: Color(0xFF2E1C0E),
      accent: Color(0xFFE07B39),
      accentLight: Color(0xFFF7B27A),
      cardFront: Color(0xFFF6F2E8),
      cardBack: Color(0xFF33302C),
      textOnFelt: Color(0xFFF0ECE0),
      chipEdge: Color(0xFFE07B39),
    ),
    PokerThemeDef(
      id: 'bluebonnet',
      name: 'Bluebonnet',
      proOnly: true,
      feltTop: Color(0xFF2E4A7A),
      feltBottom: Color(0xFF1B2C4E),
      railWood: Color(0xFF4E2E14),
      railDark: Color(0xFF2A1809),
      accent: Color(0xFF9AB8E8),
      accentLight: Color(0xFFCBDDF7),
      cardFront: Color(0xFFFFFDF6),
      cardBack: Color(0xFF1F3358),
      textOnFelt: Color(0xFFEAF1FC),
      chipEdge: Color(0xFF9AB8E8),
    ),
    PokerThemeDef(
      id: 'longhorn',
      name: 'Longhorn',
      proOnly: true,
      feltTop: Color(0xFF6E3B22),
      feltBottom: Color(0xFF472414),
      railWood: Color(0xFF2E1C0E),
      railDark: Color(0xFF1A0F06),
      accent: Color(0xFFE8E0C8),
      accentLight: Color(0xFFFFFBEA),
      cardFront: Color(0xFFFFFDF4),
      cardBack: Color(0xFF472414),
      textOnFelt: Color(0xFFF5EEDC),
      chipEdge: Color(0xFFE8E0C8),
    ),
    PokerThemeDef(
      id: 'prickly',
      name: 'Prickly Pear',
      proOnly: true,
      feltTop: Color(0xFF3E6B4F),
      feltBottom: Color(0xFF26432F),
      railWood: Color(0xFF6B4226),
      railDark: Color(0xFF3E2412),
      accent: Color(0xFFE88CA0),
      accentLight: Color(0xFFF7BECB),
      cardFront: Color(0xFFFFFDF6),
      cardBack: Color(0xFF7A2E44),
      textOnFelt: Color(0xFFF2F6EE),
      chipEdge: Color(0xFFE88CA0),
    ),
    PokerThemeDef(
      id: 'whiskey',
      name: 'Whiskey Barrel',
      proOnly: true,
      feltTop: Color(0xFF7A5230),
      feltBottom: Color(0xFF4E3319),
      railWood: Color(0xFF33200F),
      railDark: Color(0xFF1C1108),
      accent: Color(0xFFF2C14E),
      accentLight: Color(0xFFFFE6A8),
      cardFront: Color(0xFFFFF9EC),
      cardBack: Color(0xFF5C3A1E),
      textOnFelt: Color(0xFFFFF2DC),
      chipEdge: Color(0xFFF2C14E),
    ),
    PokerThemeDef(
      id: 'tumbleweed',
      name: 'Tumbleweed',
      proOnly: true,
      feltTop: Color(0xFFA08B5B),
      feltBottom: Color(0xFF6E5C38),
      railWood: Color(0xFF4A3820),
      railDark: Color(0xFF2A2010),
      accent: Color(0xFF5C4A2A),
      accentLight: Color(0xFF9A865C),
      cardFront: Color(0xFFFFFDF2),
      cardBack: Color(0xFF6E5C38),
      textOnFelt: Color(0xFFFFF8E8),
      chipEdge: Color(0xFF5C4A2A),
    ),
  ];

  static PokerThemeDef byId(String id, {PokerThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    return all.firstWhere((t) => t.id == id, orElse: () => all[0]);
  }
}

/// Card back styles (fronts stay readable ivory; backs vary).
class CardStyleDef {
  final String id;
  final String name;
  final bool proOnly;
  final Color back;
  final Color backPattern;
  final String motif; // drawn motif key
  const CardStyleDef({
    required this.id,
    required this.name,
    this.proOnly = false,
    required this.back,
    required this.backPattern,
    required this.motif,
  });
}

class CardStyles {
  static const List<CardStyleDef> all = [
    CardStyleDef(id: 'classic', name: 'Saloon Classic', back: Color(0xFF8E1F2F), backPattern: Color(0xFFB03A48), motif: 'star'),
    CardStyleDef(id: 'brand', name: 'Cattle Brand', back: Color(0xFF5B2A1E), backPattern: Color(0xFF7E442E), motif: 'brand'),
    CardStyleDef(id: 'denim', name: 'Denim', back: Color(0xFF2E4A6B), backPattern: Color(0xFF4A6B94), motif: 'diamond'),
    CardStyleDef(id: 'parchment', name: 'Wanted Poster', back: Color(0xFFC9A86A), backPattern: Color(0xFFE0C48E), motif: 'star'),
    CardStyleDef(id: 'midnight', name: 'Midnight Deck', proOnly: true, back: Color(0xFF232F45), backPattern: Color(0xFF3A4A68), motif: 'moon'),
    CardStyleDef(id: 'gold', name: 'Gold Foil', proOnly: true, back: Color(0xFF8A6D1A), backPattern: Color(0xFFC9A227), motif: 'star'),
    CardStyleDef(id: 'cactus', name: 'Cactus Green', proOnly: true, back: Color(0xFF2E5B3F), backPattern: Color(0xFF4A7E5C), motif: 'cactus'),
    CardStyleDef(id: 'charcoal', name: 'Charcoal', proOnly: true, back: Color(0xFF33302C), backPattern: Color(0xFF57534A), motif: 'diamond'),
    CardStyleDef(id: 'rosewood', name: 'Rosewood', proOnly: true, back: Color(0xFF6E2A3A), backPattern: Color(0xFF9C4A5C), motif: 'brand'),
  ];

  static CardStyleDef byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all[0]);
}

/// Chip edge styles.
class ChipStyleDef {
  final String id;
  final String name;
  final bool proOnly;
  final List<Color> spots;
  const ChipStyleDef({required this.id, required this.name, this.proOnly = false, required this.spots});
}

class ChipStyles {
  static const List<ChipStyleDef> all = [
    ChipStyleDef(id: 'classic', name: 'Saloon Clay', spots: [Color(0xFFC9A227), Color(0xFFFFFDF4)]),
    ChipStyleDef(id: 'brass', name: 'Brass Ring', spots: [Color(0xFF8A6D1A), Color(0xFFE8CE7A)]),
    ChipStyleDef(id: 'saddle', name: 'Saddle Tan', spots: [Color(0xFF6B4226), Color(0xFFC9A86A)]),
    ChipStyleDef(id: 'pokerchip', name: 'Roadhouse', proOnly: true, spots: [Color(0xFF8E1F2F), Color(0xFFFFFDF4)]),
    ChipStyleDef(id: 'turquoise', name: 'Turquoise', proOnly: true, spots: [Color(0xFF2E7A7A), Color(0xFFEAF6F2)]),
    ChipStyleDef(id: 'onyx', name: 'Onyx', proOnly: true, spots: [Color(0xFF2A2A28), Color(0xFFC9A227)]),
  ];

  static ChipStyleDef byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all[0]);
}
