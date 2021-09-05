import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Debug "mo:base/Debug";

import G "../src/Game";
import MS "../src/Metascore";

shared ({caller = owner}) actor class Game() : async G.MetascoreInterface {
    public query func metascoreScores() : async MS.Scores {
        Debug.print("Returning scores...");
        [
            (#plug("playerPlug"), 10),
            (#stoic("playerStoic"), 8),
        ];
    };

    public shared func metascoreRegisterSelf(callback : MS.RegisterCallback) : async () {
        await callback({
            name = "Saga Tarot";
        });
    };
};
