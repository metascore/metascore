# How to Integrate with Metascore

1. Player scores must be associated with a plug or stoic wallet address.
2. Your game must implement the Metascore Game Interface.
3. Your game calls its own `metascoreRegisterSelf` method.

- TODO: [Motoko Example](#)
- TODO: [Rust Example](#)
- TODO: [Unity Example](#)
- TODO: [Stoic Integration Example](#)
- TODO: [Plug Integration Example](#)

That's it! Let's take a closer look.

## Overview

Your Game Can is responsible for publishing scores to the Metascore Can (mainnet principal `todo-put-mainnet-principal-here`,) and keeping its metadata in that canister up to date.

```motoko
public type GameInterface = actor {
    metascoreScores : query () -> async [Score];
    metascoreRegisterSelf : shared (RegisterCallback) -> async ();
};
```
*See the whole interface at [public/Metascore.mo](public/Metascore.mo)*

## Registering with Metascore

Any canister that properly implements `Metascore.GameInterface` may register itself with Metascore by calling its own `metascoreRegisterSelf` method.

## Syncing Scores

1. Your Game Can should publish new high scores for a player as they happen (via the `Metascore.scoreUpdate` method). These incremental updates will make sure that scores for your game are always update to date on Metascore.
2. The Metascore Can will periodically (around once a day) ask your Game Can for a list of all the highest scores for all of your players (via your Game Can's `metascoreScores` method.) Periodic dumps will likely happen in off hours or manually at certain times, and are intended to act as a safety net for instances where the asyncronous pub/sub architecture fails.

## Syncing Metadata

Your Game Can updates its metadata when it registers with the Metascore Can, and on each periodic call. Implementing the `Metascore.GameInterface` takes care of this, so game's metadata will automatically be synced at least once a day.

## Wallet Integration

We need a way to identify players across games. Internet Identity strictly prevents this, so your game canister must allow players to authenticate with either Stoic or Plug. **It is essential that all of the scores you report to Metascore include the plug or stoic wallet address that they are associated with.**

Not sure how to add Stoic and Plug integrations? TODO: [Stoic Example](#), [Plug Example](#). Remember, you don't have to integrate both, just one of them will do! If you're having a hard time, pop into the [Dfinity Dev Discord](https://discord.gg/YUyZDtjmHt) and ask for help in the #hackathon channel.