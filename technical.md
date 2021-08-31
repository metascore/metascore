# How Metascore Will Work

## Score Aggregation / Normalization

We don't want games to have to use a normalized scoring system because coordination is hard. Instead, the Metascore Can will normalize the scores. A basic mechanism to do this is to calculate the percentile for each player score for each game sum them. 

## Ranks

My first thought was to have a ranking system similar to competitive online games, where specific ranks are given for the very best players and rank tiers are used for the rest of the population. For us, this would look something like:

- #1; Title: *Best Gamer of The Hackathon (Season 2)*;
- #2; Title: *#2 Gamer of the Hackathon (Season 2)*;
- #3; Title: *#3 Gamer of the Hackathon (Season 2)*;
- Elite; Title: *Elite Hackathon Gamer (Season 2)*;
- Strong; Title: *Strong Hackathon Gamer (Season 2)*;
- Participant; Title: *Hackathon Gamer (Season 2)*;

## Rewards

Rank badges are intended to be non-transferable status symbols that players can use to flex. We should develop unique badge art for these. I have no interest in making these transferable NFTs or doing anything else that will water down their effectiveness as a status symbol.

That said, the people want airdrops! So, as well as the Rank Badges, we will provide transferable NFT rewards (that still increase in value based on metascore.) My hope is that we can find an NFT partner to work with. If not, we can take our time after the hackathon to develop an NFT project.

## Sybil (Players)

Generating a wallet address with Plug or Stoic is possibly even easier than generating a new Internet Identity 😥. Possible solutions

- Link a social account to verify
- Add a phone number to verify

I hate Sybil.

## Sybil (Developers)

I anticipate there being a manageable number of game canisters for **manual validation**. A real script kiddie might attempt to register a boatload of games that return a high score for their accounts and a zero for others, or something else nefarious.
