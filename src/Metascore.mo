import Array "mo:base/Array";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import MPublic "../public/Metascore";
import MStats "../public/Stats";

// This module is for internal use and should never be imported somewhere other
// than 'main.mo';
module {

    // NOTE: make sure this is updated! Ensures some compiler checks. ~ quint
    public type FullInterface = actor {
        // MetascoreInterface (see public/Metascore.mo).
        register    : shared (MPublic.GamePrincipal) -> async Result.Result<(), Text>;
        scoreUpdate : shared ([MPublic.Score]) -> async ();

        // PublicInterface (see public/Stats.mo).
        getPercentile         : query (MPublic.GamePrincipal, MPublic.Player) -> async ?Float;
        getRanking            : query (MPublic.GamePrincipal, MPublic.Player) -> async ?Nat;
        getMetascore          : query (MPublic.GamePrincipal, MPublic.Player) -> async Nat;
        getOverallMetascore   : query (MPublic.Player) -> async Nat;
        getGames              : query () -> async [MPublic.Metadata];

        // Internal Interface (used in main.mo).
        cron : shared () -> async ();
        registerGame : shared MPublic.Metadata -> async ();
        // TODO: add functions whenever it is public.
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
        playerRanking : HashMap.HashMap<MPublic.Player, Nat>;
    };

    // Internal class to keep track of data within the Metascore canister.
    // Used to keep the 'main.mo' file at a minimum.
    public class Metascore() : MStats.PublicInterface {
        public let games = HashMap.HashMap<
            MPublic.GamePrincipal, // Game principal id.
            GameRecord,            // Game state.
        >(
            0, Principal.equal, Principal.hash,
        );

        public func getPercentile(
            game    : MPublic.GamePrincipal,
            player  : MPublic.Player,
        ) : ?Float {
            switch (games.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.playerRanking.get(player)) {
                        case (null) { null; };
                        case (? r)  {
                            let n = Float.fromInt(gc.playerRanking.size());
                            ?((n - Float.fromInt(r - 1)) / n);
                        };
                    };
                };
            };
        };

        public func getRanking(
            game    : MPublic.GamePrincipal,
            player  : MPublic.Player,
        ) : ?Nat {
            switch (games.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.playerRanking.get(player)) {
                        case (null) { null; };
                        case (? r)  { ?r    };
                    };
                };
            };
        };

        public func getMetascore (
            game    : MPublic.GamePrincipal,
            player  : MPublic.Player,
        ) : Nat {
            // To drive people to try all games, 1/2 of points awarded for participation.
            var score : Float = 0.5;
            switch (getPercentile(game, player)) {
                case (null) { return 0; };
                case (?percentile) {
                    // Players get up to 1/4 of available points based on performance.
                    score += 0.25 * percentile;
                    switch (getRanking(game, player)) {
                        case (null) { return 0; };
                        case (?ranking) {
                            // Players get up to 1/4 of available points based on top 3
                            score += switch (ranking) {
                                case (1) { 0.25;   };
                                case (2) { 0.125;  }; // 0.25 / 2
                                case (3) { 0.0625; }; // 0.25 / 4
                                case (_) { 0;      };
                            };
                        };
                    };
                };
            };
            Int.abs(Float.toInt(score * 1_000_000_000_000));
        };

        public func getOverallMetascore(
            player  : MPublic.Player,
        ) : Nat {
            var score : Nat = 0;
            for ((gID, _) in games.entries()) {
                score += getMetascore(gID, player);
            };
            score;
        };

        public func getGames() : [MPublic.Metadata] {
            var md : [MPublic.Metadata] = [];
            for ((_, g) in games.entries()) {
                md := Array.append(md, [g.metadata]);
            };
            md;
        };
    };
}