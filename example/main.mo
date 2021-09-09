import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Debug "mo:base/Debug";

import MPublic "../src/Metascore";

shared ({caller = owner}) actor class Game() : async MPublic.GameInterface {
    public query func metascoreScores() : async [MPublic.Score] {
        Debug.print("Returning scores...");
        [
            (#plug(Principal.fromText("ztlax-3lufm-ahpvx-36scg-7b4lf-m34dn-md7or-ltgjf-nhq4k-qqffn-oqe")), 10),
            (#stoic(Principal.fromText("k4ltb-urk4m-kdfc4-a2sib-br5ub-gcnep-tkxt2-2oqqa-ldzj2-zvmyw-gqe")), 8),
        ];
    };

    public shared func metascoreRegisterSelf(callback : MPublic.RegisterCallback) : async () {
        await callback({
            name = "Saga Tarot";
        });
    };
};
