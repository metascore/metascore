#!/usr/bin/env sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

bold() {
    tput bold
    echo $1
    tput sgr0
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
dfx deploy --no-wallet game

ownerID=$(dfx identity get-principal)
gameID=$(dfx canister id game)
metascoreID=$(dfx canister id metascore)
player1="variant{plug = principal \"ztlax-3lufm-ahpvx-36scg-7b4lf-m34dn-md7or-ltgjf-nhq4k-qqffn-oqe\"}"
player2="variant{stoic = principal \"k4ltb-urk4m-kdfc4-a2sib-br5ub-gcnep-tkxt2-2oqqa-ldzj2-zvmyw-gqe\"}"

bold "\n> TESTS\n"

check "Check if owner is admin" \
      "$(dfx canister call metascore isAdmin "(principal \"$ownerID\")")" \
      "(true)"

check "Register invalid game" "$(dfx canister call metascore register "(principal \"lgncu-2qaaa-aaaah-qadfa-cai\")")" "(
  variant {
    err = \"Could not register game with principal ID: lgncu-2qaaa-aaaah-qadfa-cai (Canister lgncu-2qaaa-aaaah-qadfa-cai does not exist)\"
  },
)"

check "Register game" "$(dfx canister call game register "(principal \"$metascoreID\")")" "(variant { ok })"

check "Get games" "$(dfx canister call metascore getGames)" "(
  vec {
    record {
      principal \"ryjl3-tyaaa-aaaaa-aaaba-cai\";
      record { name = \"Saga Tarot\" };
    };
  },
)"

echo ""

check "Get Player1 percentile" "$(dfx canister call metascore getPercentile "(principal \"$gameID\", $player1)")" "(opt (1 : float64))"
check "Get Player1 ranking"    "$(dfx canister call metascore getRanking "(principal \"$gameID\", $player1)")"    "(opt (1 : nat))"
check "Get Player1 metascore"  "$(dfx canister call metascore getOverallMetascore "($player1)")"                  "(1_000_000_000_000 : nat)"

echo ""

check "Get Player2 percentile" "$(dfx canister call metascore getPercentile "(principal \"$gameID\", $player2)")" "(opt (0.5 : float64))"
check "Get Player2 ranking"    "$(dfx canister call metascore getRanking "(principal \"$gameID\", $player2)")"    "(opt (2 : nat))"
check "Get Player2 metascore"  "$(dfx canister call metascore getOverallMetascore "($player2)")"                  "(750_000_000_000 : nat)"

echo ""

check "Updates scores" "$(dfx canister call game sendNewScores "(vec { record { $player2; 15 } })")" "()"
check "Get Player1 metascore" "$(dfx canister call metascore getOverallMetascore "($player1)")" "(750_000_000_000 : nat)"
check "Get Player2 metascore" "$(dfx canister call metascore getOverallMetascore "($player2)")" "(1_000_000_000_000 : nat)"

echo ""

check "Get top 10" "$(dfx canister call metascore getTop "(10)")" "(
  vec {
    record {
      variant {
        stoic = principal \"k4ltb-urk4m-kdfc4-a2sib-br5ub-gcnep-tkxt2-2oqqa-ldzj2-zvmyw-gqe\"
      };
      1_000_000_000_000 : nat;
    };
    record {
      variant {
        plug = principal \"ztlax-3lufm-ahpvx-36scg-7b4lf-m34dn-md7or-ltgjf-nhq4k-qqffn-oqe\"
      };
      750_000_000_000 : nat;
    };
  },
)"

bold "\n> TESTS ${GREEN}PASSED${NC}\n"

dfx -q stop > /dev/null 2>&1
