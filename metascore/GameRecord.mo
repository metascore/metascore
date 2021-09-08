import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import Player "Player";
import MPublic "../src/Metascore";

module {
    public type Games = HashMap.HashMap<
        MPublic.GamePrincipal, // Game principal id.
        GameRecord,            // Game state.
    >;

    public func empty(n : Nat) : Games {
        HashMap.HashMap<MPublic.GamePrincipal, GameRecord>(n, Principal.equal, Principal.hash);
    };

    public type Ranking = HashMap.HashMap<MPublic.Player, Nat>;

    public func emptyRanking(n : Nat) : Ranking {
        HashMap.HashMap<MPublic.Player, Nat>(n, Player.equal, Player.hash);
    };

    // Internal representation of a game.
    public type GameRecord = {
        // Name of the game.
        metadata : MPublic.Metadata;
        // The raw scores of the game.
        // TODO: use data structure to avoid duplicates and efficient updates.
        rawScores : [MPublic.Score];
        // Calculated ranking (1st..) of every player. Should always be up to
        // date (will be updates together with raw scores).
        playerRanking : Ranking;
    };

    // Stable version of a GameRecord;
    public type GameRecordStable = (
        MPublic.GamePrincipal,               // Game principal ID.
        (MPublic.Metadata, [MPublic.Score]), // Game metadata and scores.
    );

    // Converts scores to a map of rankings.
    // Assumes that the incoming scores are sorted (high to low).
    public func scoresToRanking(scores : [MPublic.Score]) : HashMap.HashMap<MPublic.Player, Nat> {
        let m = emptyRanking(scores.size());
        for (i in scores.keys()) {
            let (p, _) = scores[i];
            m.put(p, i + 1);
        };
        m;
    };

    public func fromStable(records : [GameRecordStable]) : Games {
        let xs = empty(records.size());
        for ((gID, (metadata, scores)) in records.vals()) {
            xs.put(gID, {
                metadata;
                rawScores      = scores;
                playerRanking  = scoresToRanking(scores);
            });
        };
        xs;
    };

    public func toStable(records : Games) : [GameRecordStable] {
        var xs : [GameRecordStable] = [];
        for ((gID, r) in records.entries()) {
            xs := Array.append<GameRecordStable>(xs, [(
                gID,
                (r.metadata, r.rawScores),
            )]);
        };
        xs;
    };
};
