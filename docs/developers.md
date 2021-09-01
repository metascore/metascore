# How to Integrate with Metascore

Here's how it works:

1. Your game will need to integrate with Stoic or Plug.
2. Your game will need to expose a method that dumps all of the scores for all of the players.
3. You will need to register your game with Metascore.

That's it! Let's take a closer look.

## Wallet Integration

We need a way to identify players across games. Internet Identity strictly prevents this, so your game canister must allow players to authenticate with either Stoic or Plug.

Not sure how to add Stoic and Plug integrations? TODO: link a little tutorial or code snippet. Remember, you don't have to integrate both, just one of them will do! If you're having a hard time, pop into the [Dfinity Dev Discord](https://discord.gg/YUyZDtjmHt) and ask for help in the #hackathon channel.

## Dumping Player Scores

The standard method that your game must implement is this:

```motoko
public query func metascoreDump () : async [(player : {#stoic : Text; #plug : Text}, score : Nat)] { ... };
```

This method should simply read whatever internal state you're using to store player scores and return that. **Edit: Only one score per player should be returned, and that should be their highest score achieved in the game.**

This it! The only code you need to implement is 1) stoic or plug integration, 2) `metascoreDump`.

## Register Your Game

Make sure you complete your integration before registering with the Metascore Can. We will be implementing a UI for you to register your own game cans. This UI will validate that your canister is compatible and will provide an error message if it is not.

## Scores In Your Game

We don't mind how your game's specific scoring works, that's up to you! Your scores could go up to million-billion, or ten, it makes no difference to us.
