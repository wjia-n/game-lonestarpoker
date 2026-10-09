import 'package:flutter_test/flutter_test.dart';
import 'package:lonestarpoker/engine/poker_engine.dart';

/// Headless smoke test for the engine state machine:
/// a full bot-vs-bot hand must complete (no stuck states),
/// chips must be conserved, and narration must flow.
void main() {
  test('bot hand completes with conserved chips', () async {
    final engine = PokerEngine();
    final events = <String>[];
    engine.onSfx = events.add;
    engine.newGame(GameConfig(seats: const [
      SeatConfig(name: 'You', isHuman: true),
      SeatConfig(name: 'BotA', isHuman: false, difficulty: 0),
      SeatConfig(name: 'BotB', isHuman: false, difficulty: 2),
    ]));

    // Wait for the hand to finish (generous: bots think 0.8-1.5s per action).
    // The human seat is auto-played: check when free, otherwise call.
    final deadline = DateTime.now().add(const Duration(minutes: 4));
    while (engine.phase != Phase.handOver &&
        engine.phase != Phase.gameOver &&
        DateTime.now().isBefore(deadline)) {
      if (engine.awaitingHuman && engine.phase == Phase.betting) {
        engine.humanAct(
            engine.canCheck ? ActionKind.check : ActionKind.call);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    expect(engine.phase, isNot(equals(Phase.idle)),
        reason: 'engine never left idle');
    expect(
        engine.phase == Phase.handOver || engine.phase == Phase.gameOver,
        isTrue,
        reason: 'hand did not complete — stuck in ${engine.phase}');

    // Chip conservation: after the awards, every chip is back in stacks.
    // (The pot display intentionally still shows the final pot during the
    // hand-over banner; betHand resets on the next hand.)
    final stacks = engine.seats.fold(0, (p, s) => p + s.stack);
    expect(stacks, equals(1500),
        reason: 'chips leaked: stacks=$stacks pot=${engine.pot}');

    expect(engine.narration.isNotEmpty, isTrue,
        reason: 'no narration produced');
    expect(events.isNotEmpty, isTrue, reason: 'no SFX hooks fired');

    // A winner was recorded.
    expect(engine.lastWins.isNotEmpty, isTrue);

    engine.dispose();
  }, timeout: const Timeout(Duration(minutes: 5)));
}
