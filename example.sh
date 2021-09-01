#!/bin/sh

dfx start --background --clean
dfx deploy --no-wallet
gameID=$(dfx canister id game)

echo ""

dfx canister call metascore register "(principal \"$gameID\")"

while [ 1 ]; do
    sleep 1; # in seconds
    dfx canister call metascore cron > /dev/null
done;

dfx stop

# Example output:
# [Canister rrkah-fqaaa-aaaaa-aaaaq-cai] Registering Saga Tarot (rwlgt-iiaaa-aaaaa-aaaaa-cai)...
# [Canister rwlgt-iiaaa-aaaaa-aaaaa-cai] Returning scores...
# (variant { ok })
#
# [Canister rrkah-fqaaa-aaaaa-aaaaq-cai] Getting scores...
# [Canister rwlgt-iiaaa-aaaaa-aaaaa-cai] Returning scores...
#
# etc... (every 3 seconds)
