import Array "mo:base/Array";
import EQueue "mo:queue/EvictingQueue";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import O "mo:sorted/Order";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import SMap "mo:sorted/Map";

import Interface "Interface";

import MAccount "../src/Account";
import MPlayer "../src/Player";
import MPublic "../src/Metascore";

import Debug = "mo:base/Debug";

module {
    public type StableGame = (
        MPublic.GamePrincipal,
        (MPublic.Metadata, [MAccount.Score]),
    );
    
    // Converts the state to its corresponing stable form.
    // NOTE: does NOT include users!
    public func toStable(s : State) : [StableGame] {
        var games : [StableGame] = [];
        for ((gameId, accountScores) in s.gameLeaderboards.entries()) {
            let metadata : MPublic.Metadata = switch (s.games.get(gameId)) {
                case (? m)   { m; };
                case (null) {
                    // [💀] Unreachable: should not happen.
                    // If the leaderboard contains a game, so should games, 
                    // these should never be out of sync.
                    assert(false); {
                        name       = "💀";
                        playUrl    = "#";
                        flavorText = null;
                    };
                };
            };
            var scores : [(MAccount.AccountId, Nat)] = [];
            for ((_, accountScore) in accountScores.entries()) {
                scores := Array.append<MAccount.Score>(
                    scores, [accountScore],
                );
            };
            games := Array.append<StableGame>(games, [(
                gameId, (metadata, scores),
            )])
        };
        games;
    };

    // Compares two player scores.
    public let compareAccountScores = func ((_, a) : MAccount.Score, (_, b) : MAccount.Score) : Order.Order {
        Nat.compare(a, b);
    };

    public class State(
        state         : [StableGame],
    ) : Interface.StateInterface {                
        // A map of players to their game scores.
        private type AccountScores = SMap.SortedValueMap<MAccount.AccountId, MAccount.Score>;

        // [🗄] A map of games to their player scores.
        public let gameLeaderboards : HashMap.HashMap<MPublic.GamePrincipal, AccountScores> = HashMap.HashMap(
            0, Principal.equal, Principal.hash,
        );

        // [🗄] A map of games to their metadata.
        public let games : HashMap.HashMap<MPublic.GamePrincipal, MPublic.Metadata> = HashMap.HashMap(
            0, Principal.equal, Principal.hash,
        );

        // A queue of recent score update requests.
        public let scoreUpdateLog = EQueue.EvictingQueue<(MPublic.GamePrincipal, MAccount.Score)>(100);

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | THE Metascore calculation... 🏁                                   |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        // Converts game scores to metascores.
        // | gameScore: a non-normalized score coming from a game.
        public func metascore(gameId : MPublic.GamePrincipal, accountId : MAccount.AccountId, gameScore : Nat) : Nat {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { return 0; };
                case (? accountScores) {
                    switch (accountScores.getValue(0)) {
                        case (null) {
                            // There are no scores yet? Well done, you'll get
                            // them all then...
                            return 1_000_000_000_000;
                        };
                        case (? (_, s)) {
                            // You get up to 0.5T for top 3.
                            let top = switch (accountScores.getIndexOf(accountId)) {
                                case (? 0) { 500_000_000_000; };
                                case (? 1) { 250_000_000_000; };
                                case (? 2) { 125_000_000_000; };
                                case (_)   { 0; };
                            };
                            // You can get up to 0.5T based on your score relative to the best score.
                            let topScore   = Float.fromInt(s);
                            let normalized = Float.fromInt(gameScore) / topScore;
                            Int.abs(Float.toInt(Float.fromInt(500_000_000_000) * normalized)) + top;
                        };
                    };
                };
            };
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Load stable state, given on creation. ~ constructor               |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        for ((gameId, (metadata, scores)) in state.vals()) {
            // Game Metadata.
            games.put(gameId, metadata);
            // Game Leaderboards.
            let accountScores = SMap.SortedValueMap<MAccount.AccountId, MAccount.Score>(
                scores.size(), Nat.equal, Hash.hash,
                O.Descending(compareAccountScores),
            );
            for ((a, s) in scores.vals()) {
                accountScores.put(a, (a, s));
            };
            gameLeaderboards.put((gameId, accountScores));
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Adding new scores.                                                |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        public func updateScores(gameId : MPublic.GamePrincipal, scores : [MAccount.Score]) {
            // NOTE: "heap out of bounds" error on this method with 3,682 records
            // Log score update requests.
            for (score in Iter.fromArray(scores)) {
                scoreUpdateLog.push((gameId, score));
            };

            for (score in scores.vals()) {
                _updateScore(gameId, score)
            };
        };

        public func updateScore(gameId : MPublic.GamePrincipal, score : MAccount.Score) {
            // Log score update requsts.
            scoreUpdateLog.push((gameId, score));
            _updateScore(gameId, score);
        };

        // Stores an updated game score.
        // Returns whether the global scores need to be recalculated.
        private func _updateScore(gameId : MPublic.GamePrincipal, (accountId, score) : MAccount.Score) {
            let accountScores = switch (gameLeaderboards.get(gameId)) {
                case (null) {
                    SMap.SortedValueMap<MAccount.AccountId, MAccount.Score>(
                        0, Nat.equal, Hash.hash,
                        O.Descending(compareAccountScores),
                    );
                };
                case (? ps) { ps; };
            };
            switch (accountScores.get(accountId)) {
                case (? (_, os)) {
                    // Score is already the same, no need to update anything.
                    if (score <= os) return; // TODO: add scoring types.

                    accountScores.put(accountId, (accountId, score));
                    gameLeaderboards.put(gameId, accountScores);
                };
                case (null) {
                    accountScores.put(accountId, (accountId, score));
                    gameLeaderboards.put(gameId, accountScores);
                };
            };
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Internal Interface, which contains a lot of getters...            |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        public func removeGame(gameId : MPublic.GamePrincipal) {
            games.delete(gameId);
            gameLeaderboards.delete(gameId);
            // NOTE: Disabling global leaderboard
            // switch (gameLeaderboards.get(gameId)) {
            //     case (null) {
            //         // [💀] Unreachable: should not happen.
            //         // The game should be already be there...
            //         assert(false);
            //     };
            //     case (? accountScores) {
            //         for ((_, (accountId, score)) in accountScores.entries()) {
            //             switch (globalLeaderboard.get(accountId)) {
            //                 case (null) {};
            //                 case (? (g, ss)) {
            //                     let ms = metascore(gameId, accountId, score);
            //                     ss.delete(gameId);
            //                     globalLeaderboard.put(accountId, (
            //                         globalScore(accountId, ss),
            //                         ss,
            //                     ));
            //                 };
            //             };
            //         };
            //     };
            // };
        };

        public func getGameScores(gameId : MPublic.GamePrincipal, count : ?Nat, offset : ?Nat) : [MAccount.Score] {
            let c : Nat = Option.get<Nat>(count,  100);
            let o : Nat = Option.get<Nat>(offset, 0  );
            switch (gameLeaderboards.get(gameId)) {
                case (null) { []; }; // Game not found.
                case (? accountScores) {
                    Array.tabulate<MAccount.Score>(
                        Nat.min(c, accountScores.size()),
                        func (i : Nat) : MAccount.Score {
                            switch (accountScores.getValue(i + o)) {
                                case (? score) { score;  };
                                case (null)    { (0, 0); };
                            };
                        },
                    );
                };
            };
        };

        public func getGames() : [(MPublic.GamePrincipal, MPublic.Metadata)] {
            Iter.toArray(games.entries());
        };

        public func getPercentile(gameId : MPublic.GamePrincipal, accountId : MAccount.AccountId) : ?Float {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { null; }; // Game not found.
                case (? accountScores) {
                    switch (accountScores.getIndexOf(accountId)) {
                        case (null) { null; };
                        case (? i)  {
                            let n = Float.fromInt(accountScores.size());
                            ?((n - Float.fromInt(i)) / n);
                        };
                    };
                };
            };
        };

        public func getRanking(gameId : MPublic.GamePrincipal, accountId : MAccount.AccountId) : ?Nat {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { null; };
                case (? accountScores) {
                    switch (accountScores.getIndexOf(accountId)) {
                        case (null) { null;     };
                        case (? s)  { ?(s + 1); };
                    };
                };
            };
        };

        public func getScoreCount() : Nat {
            var count = 0;
            for ((_, ps) in gameLeaderboards.entries()) {
                count += ps.size();
            };
            count;
        };

        public func getTop(gameId : MPublic.GamePrincipal, n : Nat) : [MAccount.Score] {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { []; }; // Game not found.
                case (? accountScores) {
                    Array.tabulate<MAccount.Score>(
                        Nat.min(n, accountScores.size()),
                        func (i : Nat) : MAccount.Score {
                            switch (accountScores.getIndex(i)) {
                                case (null) { (0, 0); };
                                case (? (_, (accountId, score))) {
                                    (accountId, score);
                                };
                            };
                        },
                    );
                };
            };
        };
    };
};