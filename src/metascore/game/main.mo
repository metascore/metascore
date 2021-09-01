import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Debug "mo:base/Debug";

import G "Game";
import MS "../MetaScore";

shared ({caller = owner}) actor class Game() : async G.Interface {
    public query func scores() : async [(Text, Nat)] {
        Debug.print("Returning scores...");
        [
            ("player0001", 10),
            ("player0002", 8),
            ("player0003", 2),
        ];
    };

    public shared func registerSelf(c : MS.RegisterCallback) : async () {
        await c("Saga Tarot");
    };
};
