import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Debug "mo:base/Debug";

import MPublic "../src/Metascore";

shared ({caller = owner}) actor class Game() : async MPublic.GameInterface {
    public query func metascoreScores() : async [MPublic.Score] {
        Debug.print("Returning scores...");
        [
            (#plug("playerPlug"), 10),
            (#stoic("playerStoic"), 8),
        ];
    };

    public shared func metascoreRegisterSelf(callback : MPublic.RegisterCallback) : async () {
        await callback({
            name = "Saga Tarot";
        });
    };
};
