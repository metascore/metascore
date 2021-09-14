import Array "mo:base/Array";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import GR "GameRecord";
import MPlayer "../src/Player";
import MPublic "../src/Metascore";
import MStats "../src/Stats";

// This module is for internal use and should never be imported somewhere other
// than 'main.mo'.
module {
    // Internal class to keep track of data within the Metascore canister.
    // Used to keep the 'main.mo' file at a minimum.
    public class Metascore(
        state : [GR.GameRecordStable],
    ) : MStats.PublicInterface {
        public let games = GR.fromStable(state);

        public func getPercentile(
            game    : MPublic.GamePrincipal,
            player  : MPlayer.Player,
        ) : ?Float {
            switch (games.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.players.getIndex(player)) {
                        case (null) { null; };
                        case (? i)  {
                            let n = Float.fromInt(gc.players.size());
                            ?((n - Float.fromInt(i)) / n);
                        };
                    };
                };
            };
        };

        public func getRanking(
            game    : MPublic.GamePrincipal,
            player  : MPlayer.Player,
        ) : ?Nat {
            switch (games.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.players.getIndex(player)) {
                        case (null) { null;   };
                        case (? r)  { ?(r+1); };
                    };
                };
            };
        };

        public func getMetascore (
            game    : MPublic.GamePrincipal,
            player  : MPlayer.Player,
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
            player  : MPlayer.Player,
        ) : Nat {
            var score : Nat = 0;
            for ((gID, _) in games.entries()) {
                score += getMetascore(gID, player);
            };
            score;
        };

        public func getGames() : [(MPublic.GamePrincipal, MPublic.Metadata)] {
            var md : [(MPublic.GamePrincipal, MPublic.Metadata)] = [];
            for ((p, g) in games.entries()) {
                md := Array.append(md, [(p, g.metadata)]);
            };
            md;
        };
    };
}