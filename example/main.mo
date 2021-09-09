import Principal "mo:base/Principal";
import Result "mo:base/Result";

import MPublic "../src/Metascore";

shared ({caller = owner}) actor class Game() : async MPublic.GameInterface = this {
    var metascore : ?Principal = null;

    public query func metascoreScores() : async [MPublic.Score] {
        // TODO: store in data structure.
        [
            (#plug(Principal.fromText("ztlax-3lufm-ahpvx-36scg-7b4lf-m34dn-md7or-ltgjf-nhq4k-qqffn-oqe")), 10),
            (#stoic(Principal.fromText("k4ltb-urk4m-kdfc4-a2sib-br5ub-gcnep-tkxt2-2oqqa-ldzj2-zvmyw-gqe")), 8),
        ];
    };

    public shared({caller}) func metascoreRegisterSelf(callback : MPublic.RegisterCallback) : async () {
        switch (metascore) {
            case (null)  { assert(false);         };
            case (? mID) { assert(caller == mID); };
        };

        await callback({
            name = "Saga Tarot";
        });
    };

    public shared({caller}) func register(metascoreID : Principal) : async Result.Result<(), Text> {
        assert(caller == owner);
        switch (metascore) {
            case (? _)  { #ok(); };
            case (null) {
                metascore := ?metascoreID;
                let metascoreCanister : MPublic.MetascoreInterface = actor(Principal.toText(metascoreID));
                await metascoreCanister.register(Principal.fromActor(this));
            };
        };
    };

    public shared({caller}) func sendNewScores(scores : [MPublic.Score]) : async () {
        assert(caller == owner);
        switch (metascore) {
            case (null)  { assert(false); };
            case (? mID) {
                // TODO: update local scores.
                let metascore : MPublic.MetascoreInterface = actor(Principal.toText(mID));
                await metascore.scoreUpdate(scores);
            };
        };
    };
};
