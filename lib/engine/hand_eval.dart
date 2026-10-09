/// Texas Hold'em 7-card hand evaluator for Lone Star Poker.
///
/// Cards are ints 0..51: rank = card % 13 (0 = deuce … 12 = ace),
/// suit = card ~/ 13 (0 = spades, 1 = hearts, 2 = diamonds, 3 = clubs).
///
/// [evaluate7] returns a single int score: higher wins. Scores are built as
/// category * 16^5 + kicker ranks packed 4 bits each, so any straight
/// comparison of two scores is a correct hand comparison.
library;

class Card {
  static int rankOf(int c) => c % 13;
  static int suitOf(int c) => c ~/ 13;

  static const ranks = ['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'];
  static const suits = ['♠', '♥', '♦', '♣'];

  static String name(int c) => '${ranks[rankOf(c)]}${suits[suitOf(c)]}';

  /// Full 52-card deck, ordered.
  static List<int> newDeck() => List<int>.generate(52, (i) => i);
}

/// Hand categories, low to high.
class HandCat {
  static const high = 0;
  static const pair = 1;
  static const twoPair = 2;
  static const trips = 3;
  static const straight = 4;
  static const flush = 5;
  static const fullHouse = 6;
  static const quads = 7;
  static const straightFlush = 8;

  static const names = [
    'High Card',
    'One Pair',
    'Two Pair',
    'Three of a Kind',
    'Straight',
    'Flush',
    'Full House',
    'Four of a Kind',
    'Straight Flush',
  ];
}

class HandEval {
  /// Score the best 5-card hand out of 5, 6 or 7 cards. Higher score wins.
  /// (Flop = 5 cards, turn = 6, river/showdown = 7.)
  static int evaluate(List<int> cards) {
    assert(cards.length >= 5 && cards.length <= 7);
    if (cards.length == 5) return _evaluate5(cards);
    var best = -1;
    // All 5-card combinations of the available cards.
    final n = cards.length;
    for (var a = 0; a < n - 4; a++) {
      for (var b = a + 1; b < n - 3; b++) {
        for (var c = b + 1; c < n - 2; c++) {
          for (var d = c + 1; d < n - 1; d++) {
            for (var e = d + 1; e < n; e++) {
              final s = _evaluate5(
                  [cards[a], cards[b], cards[c], cards[d], cards[e]]);
              if (s > best) best = s;
            }
          }
        }
      }
    }
    return best;
  }

  /// Score the best 5-card hand out of 7 cards. Higher score wins.
  static int evaluate7(List<int> cards) => evaluate(cards);

  /// Pack category + 5 kickers (4 bits each) into one comparable int.
  static int _pack(int cat, List<int> kickers) {
    var s = cat;
    for (final k in kickers) {
      s = (s << 4) | k;
    }
    return s;
  }

  static int _evaluate5(List<int> cards) {
    final ranks = [for (final c in cards) Card.rankOf(c)]..sort();
    final suits = [for (final c in cards) Card.suitOf(c)];
    final flush = suits.every((s) => s == suits[0]);

    // rank counts, descending by (count, rank)
    final counts = <int, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    final groups = counts.entries.toList()
      ..sort((x, y) {
        final c = y.value.compareTo(x.value);
        return c != 0 ? c : y.key.compareTo(x.key);
      });

    // Straight detection (wheel A-2-3-4-5 included).
    int straightHigh = -1;
    final uniq = counts.keys.toList()..sort();
    if (uniq.length == 5) {
      if (uniq[4] - uniq[0] == 4) {
        straightHigh = uniq[4];
      } else if (uniq[0] == 0 &&
          uniq[1] == 1 &&
          uniq[2] == 2 &&
          uniq[3] == 3 &&
          uniq[4] == 12) {
        // A-2-3-4-5
        straightHigh = 3; // five-high
      }
    }

    if (flush && straightHigh >= 0) {
      return _pack(HandCat.straightFlush, [straightHigh, 0, 0, 0, 0]);
    }
    if (groups[0].value == 4) {
      final quad = groups[0].key;
      final kick = groups[1].key;
      return _pack(HandCat.quads, [quad, kick, 0, 0, 0]);
    }
    if (groups[0].value == 3 && groups[1].value == 2) {
      return _pack(HandCat.fullHouse, [groups[0].key, groups[1].key, 0, 0, 0]);
    }
    if (flush) {
      final desc = ranks.reversed.toList();
      return _pack(HandCat.flush, desc);
    }
    if (straightHigh >= 0) {
      return _pack(HandCat.straight, [straightHigh, 0, 0, 0, 0]);
    }
    if (groups[0].value == 3) {
      final kickers = [groups[1].key, groups[2].key]..sort((a, b) => b - a);
      return _pack(HandCat.trips, [groups[0].key, kickers[0], kickers[1], 0, 0]);
    }
    if (groups[0].value == 2 && groups[1].value == 2) {
      final pairs = [groups[0].key, groups[1].key]..sort((a, b) => b - a);
      return _pack(HandCat.twoPair, [pairs[0], pairs[1], groups[2].key, 0, 0]);
    }
    if (groups[0].value == 2) {
      final kickers = [groups[1].key, groups[2].key, groups[3].key]
        ..sort((a, b) => b - a);
      return _pack(HandCat.pair,
          [groups[0].key, kickers[0], kickers[1], kickers[2], 0]);
    }
    final desc = ranks.reversed.toList();
    return _pack(HandCat.high, desc);
  }

  static int categoryOf(int score) => score >> 20;

  static String categoryName(int score) =>
      HandCat.names[categoryOf(score).clamp(0, 8)];
}
