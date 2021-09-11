import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

// Public Metascore interfaces/types.
import MPlayer "../src/Player";
import MPublic "../src/Metascore";

// Example game canister for Metascore.
shared ({caller = owner}) actor class Game() : async MPublic.GameInterface = this {
 
    // Reference to the metascore canister, will be empty if the game is not yet registered.
    var metascore : ?Principal = null;
    // Simple map to keep the scores related to a player.
    var state : HashMap.HashMap<MPlayer.Player, Nat> = HashMap.HashMap<MPlayer.Player, Nat>(
        0, MPlayer.equal, MPlayer.hash,
    );

    // Add initial state for example purposes.
    for (s in [
        (#plug(Principal.fromText("ztlax-3lufm-ahpvx-36scg-7b4lf-m34dn-md7or-ltgjf-nhq4k-qqffn-oqe")), 10),
        (#stoic(Principal.fromText("k4ltb-urk4m-kdfc4-a2sib-br5ub-gcnep-tkxt2-2oqqa-ldzj2-zvmyw-gqe")), 8),
    ].vals()) {
        state.put(s.0, s.1);
    };

    public query func metascoreScores() : async [MPublic.Score] {
        Iter.toArray(state.entries());
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

    // Custom endpoint that the owner can trigger, to register the game to the given metascoreID.
    // A game is required needs to register itself with the Metascore canister.
    // In other words: the Metascore canister will check whether the caller (canister in this case) implements the
    // GameInterface. This means that only the game canister itself can register to participate in the leaderboards.
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

    // Custom endpoint so that the owner can send new scores, this can also another game canister that keeps track of
    // the scoring for the game. NOTE: it is also possible to only send updated/new scores and not the whole leaderboard.
    public shared({caller}) func sendNewScores(scores : [MPublic.Score]) : async () {
        assert(caller == owner);
        switch (metascore) {
            case (null)  { assert(false); };
            case (? mID) {
                for (s in scores.vals()) {
                    state.put(s.0, s.1);
                };
                let metascore : MPublic.MetascoreInterface = actor(Principal.toText(mID));
                await metascore.scoreUpdate(scores);
            };
        };
    };
};
