#!/bin/sh

dfx start --background --clean
dfx deploy --no-wallet
gameID=$(dfx canister id game)

echo ""

playerP="variant{plug = \"playerPlug\"}"
playerS="variant{stoic = \"playerStoic\"}"

dfx canister call metascore register "(principal \"$gameID\")"
dfx canister call metascore getOverallRanking "(principal \"$gameID\")"
dfx canister call metascore getRanking "(principal \"$gameID\", $playerS)"
dfx canister call metascore getPercentile "(principal \"$gameID\", $playerS)"
dfx canister call metascore getGameScoreComponent "(principal \"$gameID\", $playerP)"
dfx canister call metascore getGameScoreComponent "(principal \"$gameID\", $playerS)"

dfx canister call metascore cron > /dev/null

dfx stop

# Example output:
# [Canister rrkah-fqaaa-aaaaa-aaaaq-cai] Registering Saga Tarot (rwlgt-iiaaa-aaaaa-aaaaa-cai)...
# [Canister rwlgt-iiaaa-aaaaa-aaaaa-cai] Returning scores...
# (variant { ok })
#
# (vec { principal "2ibo7-dia"; principal "uuc56-gyb" })
# (opt (2 : nat))
# (opt (0.5 : float64))
# (opt (1_000_000_000_000 : nat))
# (opt (750_000_000_000 : nat))
#
# [Canister rrkah-fqaaa-aaaaa-aaaaq-cai] Getting scores...
# [Canister rwlgt-iiaaa-aaaaa-aaaaa-cai] Returning scores...
#
# etc... (every 3 seconds)
