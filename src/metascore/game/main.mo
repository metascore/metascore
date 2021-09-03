import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Debug "mo:base/Debug";

import G "Game";
import MS "../Metascore";

shared ({caller = owner}) actor class Game() : async G.Interface {
    public query func metascoreScores() : async MS.Scores {
        Debug.print("Returning scores...");
        [
            (#plug("playerPlug"), 10),
            (#stoic("playerStoic"), 8),
        ];
    };

    public shared func metascoreRegisterSelf(c : MS.RegisterCallback) : async () {
        await c("Saga Tarot");
    };
};
