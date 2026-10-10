import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/poker_themes.dart';

/// Persisted settings + stats for Lone Star Poker.
///
/// Player names are stored as ONE order-preserving JSON string
/// ('lonestarpoker_player_names_json'). NEVER use setStringList: on Android it
/// is backed by an unordered StringSet and names come back scrambled after
/// every restart. A legacy StringList key is migrated once, then removed.
class PokerSettings extends ChangeNotifier {
  static const _kMusic = 'lonestarpoker_music_on';
  static const _kSfx = 'lonestarpoker_sfx_on';
  static const _kVolume = 'lonestarpoker_volume';
  static const _kDifficulty = 'lonestarpoker_bot_difficulty'; // 0/1/2
  static const _kBotCount = 'lonestarpoker_bot_count'; // 1..5 (vs bots)
  static const _kHumanCount = 'lonestarpoker_human_count'; // 2..6 (pass-play)
  static const _kPassPlay = 'lonestarpoker_pass_play';
  static const _kTournament = 'lonestarpoker_tournament';
  static const _kNamesLegacy = 'lonestarpoker_player_names';
  static const _kNamesJson = 'lonestarpoker_player_names_json';
  static const _kTheme = 'lonestarpoker_theme_id';
  static const _kCardStyle = 'lonestarpoker_card_style';
  static const _kChipStyle = 'lonestarpoker_chip_style';
  static const _kIsPro = 'lonestarpoker_is_pro';
  static const _kHands = 'lonestarpoker_hands_played';
  static const _kHandsWon = 'lonestarpoker_hands_won';
  static const _kBiggestPot = 'lonestarpoker_biggest_pot';
  static const _kGamesWon = 'lonestarpoker_games_won';
  static const _kReviewAsked = 'lonestarpoker_review_asked';
  static const _kCustomPrefix = 'lonestarpoker_custom_';

  static const maxSeats = 6;
  static const defaultNames = [
    'You',
    'Maverick',
    'Deadeye',
    'Calamity',
    'Dusty',
    'Sage'
  ];

  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i % defaultNames.length] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == maxSeats) {
        return [for (int i = 0; i < maxSeats; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int difficulty = 1;
  int botCount = 3;
  int humanCount = 2;
  bool passPlay = false;
  bool tournament = false;
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'saloon';
  String cardStyleId = 'classic';
  String chipStyleId = 'classic';
  bool isPro = true; // everything unlocked — no Pro version
  int handsPlayed = 0;
  int handsWon = 0;
  int biggestPot = 0;
  int gamesWon = 0;
  bool reviewAsked = false;

  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'feltTop': 0xFF2E6B46,
    'feltBottom': 0xFF1D4A2F,
    'railWood': 0xFF6B4226,
    'railDark': 0xFF3E2412,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'cardFront': 0xFFFFFDF4,
    'cardBack': 0xFF8E1F2F,
    'textOnFelt': 0xFFF5EFE0,
    'chipEdge': 0xFFC9A227,
  };

  PokerThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return PokerThemeDef(
      id: 'custom',
      name: 'My Creation',
      feltTop: c('feltTop'),
      feltBottom: c('feltBottom'),
      railWood: c('railWood'),
      railDark: c('railDark'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      cardFront: c('cardFront'),
      cardBack: c('cardBack'),
      textOnFelt: c('textOnFelt'),
      chipEdge: c('chipEdge'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    botCount = (p.getInt(_kBotCount) ?? 3).clamp(1, 5);
    humanCount = (p.getInt(_kHumanCount) ?? 2).clamp(2, 6);
    passPlay = p.getBool(_kPassPlay) ?? false;
    tournament = p.getBool(_kTournament) ?? false;

    // One-time migration from the legacy unordered StringList key.
    var raw = p.getString(_kNamesJson);
    if (raw == null) {
      final legacy = p.getStringList(_kNamesLegacy);
      if (legacy != null && legacy.isNotEmpty) {
        final fixed = List<String>.generate(
            maxSeats, (i) => _cleanName(i, i < legacy.length ? legacy[i] : null));
        raw = encodePlayerNames(fixed);
        await p.setString(_kNamesJson, raw);
      }
      await p.remove(_kNamesLegacy);
    }
    playerNames = decodePlayerNames(raw);

    themeId = p.getString(_kTheme) ?? 'saloon';
    cardStyleId = p.getString(_kCardStyle) ?? 'classic';
    chipStyleId = p.getString(_kChipStyle) ?? 'classic';
    isPro = true; // everything unlocked
    handsPlayed = p.getInt(_kHands) ?? 0;
    handsWon = p.getInt(_kHandsWon) ?? 0;
    biggestPot = p.getInt(_kBiggestPot) ?? 0;
    gamesWon = p.getInt(_kGamesWon) ?? 0;
    reviewAsked = p.getBool(_kReviewAsked) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    notifyListeners();
  }

  Future<void> _save(String key, Object v) async {
    final p = _prefs;
    if (p == null) return;
    if (v is bool) await p.setBool(key, v);
    if (v is int) await p.setInt(key, v);
    if (v is double) await p.setDouble(key, v);
    if (v is String) await p.setString(key, v);
  }

  /// Save a player name immediately (called on every keystroke).
  Future<void> setPlayerName(int i, String name) async {
    if (i < 0 || i >= maxSeats) return;
    playerNames[i] = name.trim().isEmpty
        ? defaultNames[i % defaultNames.length]
        : name.trim();
    await _prefs?.setString(_kNamesJson, encodePlayerNames(playerNames));
    notifyListeners();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    await _save(_kMusic, v);
    notifyListeners();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    await _save(_kSfx, v);
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    await _save(_kVolume, volume);
    notifyListeners();
  }

  Future<void> setDifficulty(int v) async {
    difficulty = v.clamp(0, 2);
    await _save(_kDifficulty, difficulty);
    notifyListeners();
  }

  Future<void> setBotCount(int v) async {
    botCount = v.clamp(1, 5);
    await _save(_kBotCount, botCount);
    notifyListeners();
  }

  Future<void> setHumanCount(int v) async {
    humanCount = v.clamp(2, 6);
    await _save(_kHumanCount, humanCount);
    notifyListeners();
  }

  Future<void> setPassPlay(bool v) async {
    passPlay = v;
    await _save(_kPassPlay, v);
    notifyListeners();
  }

  Future<void> setTournament(bool v) async {
    tournament = v;
    await _save(_kTournament, v);
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    themeId = id;
    await _save(_kTheme, id);
    notifyListeners();
  }

  Future<void> setCardStyle(String id) async {
    cardStyleId = id;
    await _save(_kCardStyle, id);
    notifyListeners();
  }

  Future<void> setChipStyle(String id) async {
    chipStyleId = id;
    await _save(_kChipStyle, id);
    notifyListeners();
  }

  Future<void> setCustomColor(String key, int argb) async {
    customColors[key] = argb;
    await _save('$_kCustomPrefix$key', argb);
    notifyListeners();
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    await _save(_kIsPro, v);
    notifyListeners();
  }

  Future<void> recordHand({required bool won, required int pot}) async {
    handsPlayed++;
    if (won) handsWon++;
    if (pot > biggestPot) biggestPot = pot;
    await _save(_kHands, handsPlayed);
    await _save(_kHandsWon, handsWon);
    await _save(_kBiggestPot, biggestPot);
    notifyListeners();
  }

  Future<void> recordGameWon() async {
    gamesWon++;
    await _save(_kGamesWon, gamesWon);
    notifyListeners();
  }

  /// Reset stats to zero (kept separate so the UI never touches internals).
  Future<void> resetStats() async {
    handsPlayed = 0;
    handsWon = 0;
    biggestPot = 0;
    gamesWon = 0;
    await _save(_kHands, 0);
    await _save(_kHandsWon, 0);
    await _save(_kBiggestPot, 0);
    await _save(_kGamesWon, 0);
    notifyListeners();
  }

  Future<void> markReviewAsked() async {
    reviewAsked = true;
    await _save(_kReviewAsked, true);
  }

  PokerThemeDef get theme =>
      PokerThemes.byId(themeId, custom: customTheme);
}
