# How Metascore Will Work

These are my first draft thoughts. Seems like it will work 🤷‍♂️.

## Score Aggregation / Normalization

We don't want games to have to use a normalized scoring system because coordination is hard. Instead, the Metascore Can will normalize the scores. A basic mechanism to do this is to calculate the percentile for each player score for each game sum them. 

## Ranks

My first thought was to have a ranking system similar to competitive online games, where specific ranks are given for the very best players and rank tiers are used for the rest of the population. For us, this would look something like:

- #1; Title: *Best Gamer of The Hackathon (Season 2)*; Awarded to the highest score
- #2; Title: *#2 Gamer of the Hackathon (Season 2)*; Awarded to the second highest score
- #3; Title: *#3 Gamer of the Hackathon (Season 2)*; Awarded to the third highest score
- Elite; Title: *Elite Hackathon Gamer (Season 2)*; Awarded to the top 10% of scores
- Strong; Title: *Strong Hackathon Gamer (Season 2)*; Awarded to the top 50% of scores
- Participant; Title: *Hackathon Gamer (Season 2)*; Awarded to everyone

Let's look at some badge systems for inspiration. Here's rocket league. Simple recognizable shapes ❤️.

![rocket league](https://cdn.dribbble.com/users/1708797/screenshots/6769253/rocketleague_ranks.png)

Here's Valorant. They look very similar to rocket league. They use polygons with an increasing number of vertices for higher ranks 🤔.

![valorant](https://images.contentstack.io/v3/assets/bltb6530b271fddd0b1/blte5a6438f76e89acf/5eec2c0f34f8f30c7cfb3025/VALORANT_ICONS_2.jpg)

Here's DOTA. Notice the specific ranks being displayed on the highest level badges.

![dota](https://i.redd.it/u4y3kphk1g211.png)

## Rewards

Rank badges are intended to be **non-transferable** status symbols that players can use to flex. We should develop unique badge art for these. We will not allow making these transferable NFTs or doing anything else that will water down their effectiveness as a status symbol.

That said, the people want airdrops! So, as well as the Rank Badges, we will provide transferable NFT rewards (that still increase in value based on metascore.) My hope is that we can find an NFT partner to work with. If not, we can take our time after the hackathon to develop an NFT project.

## Score Update Intervals

Watching your score change as you play and jockying for position on the leaderboards in realtime could be a highlight for hackathon participants. To that end, the scoreboard should update frequently.

Norton demoed his new NFT project that's apparently using the undocumented canister heartbeat functionality (see [this line](https://github.com/FloorLamp/cubic/blob/main/src/cubic/Cubic.mo#L447)). If testing heartbeat functionality reveals it as a usable solution, then that will be the first choice. If not, a rudimentary fallback might be to set up a server holding an authorized principal to periodically ping the Metascore Can to trigger a poll.

The community `metadeckDump` methods should be considered completely unoptimized and potentially expensive. Realtime polling is likely unrealistic for that reason. I imagine a polling rate of every minute or couple of minutes while the hackathon is ongoing will be manageable and have the desired effect.

## Eligable Scoring Period

At a certain fixed point in time, the Metascore Can will cease polling Game Cans and all scores will be considered final. There should be a grace period after the drop before ranks a granted. This will allow time for players to validate their accounts, and for us to verify results and make sure that all canisters have had a chance to make a positive final report.

Players should have a good period of time to play the games before scoring is halted. The deaddrop shouldn't be arbitarily tied to the hackathon's other milestones, but it isn't clear yet exactly what the configuration should be here.

Effectively, all scores from Game Cans are treated the same regardless of then they were created. Indeed, there's no data requirement for timestamps. This means that there is no "start time" and all scores a canister captures are valid as soon as that canister is live (once registered with Metacan scores will be retroactively applied the players' metascores.) This means that we're relying on the "newness" of the games (and the "newness" of the metascore data requirements) for this thing to work, which should be totally fine for now.

## Sybil (Players)

My favourite version of anti-sybil is not having to care about Sybil. For example, if we only have a few NFTs to give out, then only the best gamers will get them and we don't have to worry about script kiddies with X,000 wallet addresses. Unfortunately, that still leaves a lot of room for people to go full no life and clean sweep the leaderboards with multiple identities.

Generating a wallet address with Plug or Stoic is possibly even easier than generating a new Internet Identity 😥. Possible solutions

- Link a social account to verify
- Add a phone number to verify

Manually validating social seems like the type of thing maybe we could farm out to the community as well.

I hate Sybil.

## Sybil (Developers)

I anticipate there being a manageable number of game canisters for **manual validation**. A real script kiddie might attempt to register a boatload of games that return a high score for their accounts and a zero for others, or something else nefarious.

Not all games will be open source. We will validate manually by going to the game canister, playing it, and making sure it's a game. This feels like a good job to farm out to a couple of community members in exchange for an NFT.

We should also encourage the community to report anything fishy (ex: a game score that seems impossible.)

# Requirements

TODO: think more about requirements

**Actors**

- Metascore Canister "Canister"
- Canister owners
- Players
- Gem devs

## Motoko

- Canister can have multiple owners, so that ownership can be shared with trusted community members (gotta be limited, no logs)
- Canister owners can mark a game as verified or unverified
- Canister must run a "poll Game Cans and update scores" method periodically
- Canister must hold a registry of verified accounts
- Canister must provide a breakdown of metascores so that everyone can see how a player achieved their score

## Frontend

- Players can validate their accounts
- Game devs can register their game canister with Metascore
