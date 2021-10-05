#!/usr/bin/env sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
BOLD='\033[1m'

bold() {
    echo "${BOLD}$1${NC}"
}

check() {
    bold "| $1: \c"
    if [ "$2" = "$3" ]; then
        echo "${GREEN}OK${NC}"
    else
        echo "${RED}NOK${NC}: expected ${3}, got ${2}"
        dfx -q stop > /dev/null 2>&1
        exit 1
    fi
}

bold "| Starting replica."
dfx start --background --clean > /dev/null 2>&1
dfx deploy --no-wallet metascore
metascoreId=$(dfx canister id metascore)
dfx deploy --no-wallet accounts
accountsId=$(dfx canister id accounts)
dfx canister --no-wallet call metascore setAccountsCanister "(principal \"${accountsId}\")"
dfx deploy --no-wallet game
gameId=$(dfx canister id game)

ownerId=$(dfx identity get-principal)
player1="variant{plug = principal \"ztlax-3lufm-ahpvx-36scg-7b4lf-m34dn-md7or-ltgjf-nhq4k-qqffn-oqe\"}"
player2="variant{stoic = principal \"k4ltb-urk4m-kdfc4-a2sib-br5ub-gcnep-tkxt2-2oqqa-ldzj2-zvmyw-gqe\"}"

bold "\n> TESTS\n"

check "Check if owner is admin" \
      "$(dfx canister call metascore isAdmin "(principal \"$ownerId\")")" \
      "(true)"

check "Register invalid game" "$(dfx canister call metascore register "(principal \"lgncu-2qaaa-aaaah-qadfa-cai\")")" "(
  variant {
    err = \"Could not register game with principal ID: lgncu-2qaaa-aaaah-qadfa-cai (Canister lgncu-2qaaa-aaaah-qadfa-cai does not exist)\"
  },
)"

check "Register game" "$(dfx canister call game register "(principal \"$metascoreId\")")" "(variant { ok })"

check "Get games" "$(dfx canister call metascore getGames)" "(
  vec {
    record {
      principal \"$gameId\";
      record {
        name = \"Saga Tarot\";
        playUrl = \"https://l2jyf-nqaaa-aaaah-qadha-cai.raw.ic0.app/\";
        flavorText = opt \"A tarot card game.\";
      };
    };
  },
)"

check "Get game scores" "$(dfx canister call metascore getGameScores "(principal \"$gameId\", opt 100, opt 0)")" "(vec { record { 1 : nat; 10 : nat }; record { 0 : nat; 8 : nat } })"

echo ""

check "Get Player1 percentile" "$(dfx canister call metascore getPercentile "(principal \"$gameId\", 1)")" "(opt (1 : float64))"
check "Get Player1 ranking"    "$(dfx canister call metascore getRanking "(principal \"$gameId\", 1)")"    "(opt (1 : nat))"

echo ""

check "Get Player2 percentile" "$(dfx canister call metascore getPercentile "(principal \"$gameId\", 0)")" "(opt (0.5 : float64))"
check "Get Player2 ranking"    "$(dfx canister call metascore getRanking "(principal \"$gameId\", 0)")"    "(opt (2 : nat))"

echo ""

check "Updates scores" "$(dfx canister call game sendNewScores "(vec { record { $player2; 15 } })")" "()"

echo ""

check "Get top 10" "$(dfx canister call metascore getTop "(principal \"$gameId\", 10)")" "(vec { record { 0 : nat; 15 : nat }; record { 1 : nat; 10 : nat } })"

echo ""

check "Unregister game" "$(dfx canister call metascore unregister "(principal \"$gameId\")")" "()"

check "Get top 10" "$(dfx canister call metascore getTop "(principal \"$gameId\", 10)")" "(vec {})"

bold "\n> TESTS ${GREEN}PASSED${NC}\n"

dfx -q stop > /dev/null 2>&1
