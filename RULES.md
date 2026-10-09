# Lone Star Poker — RULES.md

Texas Hold'em showdown, saloon style. You and up to 5 rivals (crafty bots or
pass-and-play humans) battle for every chip on the felt. Chips are 100%
virtual — no real money, ever.

## 1. Objective
Win all the chips. A hand is won by holding the best 5-card poker hand at
showdown, or by being the last player who has not folded.

## 2. Setup
- 2–6 seats at the table. Vs Bots: you + 1–5 bots. Pass-and-Play: 2–6 humans.
- Everyone starts with 500 chips.
- Small blind 5, big blind 10, posted automatically before cards are dealt.
- Dealer button starts at seat 0 and rotates one seat left after every hand.
- A fresh 52-card deck is shuffled every hand.
- Tournament mode: blinds double every 10 hands (5/10 → 10/20 → 20/40 …).

## 3. Turn order
- Preflop: the player left of the big blind acts first; action moves clockwise.
- Flop/turn/river: the first still-in player left of the button acts first.
- Heads-up (2 players): the button posts the small blind and acts first preflop.
- A betting round ends when every still-in player has matched the current bet
  (or folded / gone all-in).

## 4. Legal moves
- **Fold** — give up your hand and any chips you already bet.
- **Check** — pass action, only legal when nobody has bet this round.
- **Call** — match the current bet.
- **Raise** — increase the bet. Minimum raise: big blind preflop, or at least
  the size of the previous raise afterwards.
- **All-in** — bet your entire remaining stack at any time.

## 5. Illegal moves
- Checking when there is a bet to call.
- Calling more than your stack (you go all-in instead).
- Raising below the minimum raise.
- Acting out of turn — the engine only accepts input from the current actor.

## 6. Captures
No captures — chips move only through blinds, bets, and pots.

## 7. Special rules
- Blinds are posted automatically, even if they put you all-in.
- An all-in player can only win pots they contributed to — extra chips form
  **side pots** contested by the remaining players.
- If all remaining players are all-in (or only one can still act), the board
  is dealt out automatically with no further betting.
- If everyone folds to one player, that player wins the pot immediately —
  no cards are revealed.
- A player with 0 chips after a hand is eliminated. In Vs Bots, eliminated
  bots stay out; the game ends when you are broke or all bots are broke.

## 8. Scoring (hand ranks, low to high)
High card < One pair < Two pair < Three of a kind < Straight < Flush <
Full house < Four of a kind < Straight flush.
Aces play high or low in straights (A-2-3-4-5 is a valid straight).
Kickers break ties within the same rank.

## 9. Winning conditions
- Best 5-card hand from your 2 hole cards + 5 community cards wins the pot.
- Vs Bots: win every chip on the table to win the game.
- Pass-and-Play: play as many hands as you like; richest player leads.

## 10. Draw conditions
- Tied hands split the pot evenly. An odd chip goes to the tied player
  closest left of the button.

## 11. AI strategy
- **Easy "Greenhorn":** loose and random. Calls too much, folds rarely, raises
  on a whim. Great for learning.
- **Medium "Sharp":** plays its cards. Folds weak hands facing bets, calls
  with decent draws and pairs, raises strong made hands.
- **Hard "Legend":** tight and observant. Weighs pot odds, position, and board
  texture; value-bets thin and bluffs scary boards when checked to.

## 12. Edge cases
- Player cannot cover the blind → posted as all-in with what they have.
- Two players all-in for different amounts → side pots per §7.
- Human backgrounds the app mid-hand → hand resumes on return (engine timers
  pause with the lifecycle).
- Deck/rank logic is deterministic and unit-tested; no impossible states.

## 13. Test cases
- Royal flush beats straight flush; straight flush beats quads.
- A-2-3-4-5 straight loses to 2-3-4-5-6.
- Split pot: identical boards with no better hole cards split evenly.
- Side pot: short-stack all-in wins only the main pot; best of the rest wins
  the side pot.
- Everyone folds preflop → big blind wins without showdown.
- All-in runout deals flop/turn/river automatically.
