import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Debug "mo:base/Debug";

import G "Game";
import MS "../MetaScore";

shared ({caller = owner}) actor class Game() : async G.Interface {
    public query func metascoreScores() : async MS.Scores {
        Debug.print("Returning scores...");
        [
            (Principal.fromText("2ibo7-dia"), 10),
            (Principal.fromText("uuc56-gyb"), 8),
        ];
    };

    public shared func metascoreRegisterSelf(c : MS.RegisterCallback) : async () {
        await c("Saga Tarot");
    };
};
