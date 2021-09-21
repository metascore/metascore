import Array "mo:base/Array";
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
import Users "Users";

import MAccount "../src/Account";
import MPlayer "../src/Player";
import MPublic "../src/Metascore";

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
        nextAccountId : MAccount.AccountId,
        accounts      : [Users.StableAccount],
        state         : [StableGame],
    ) : Interface.StateInterface {        
        // Tuple of a global scores and individual scores per game.
        private type GlobalScores = (
            // Global metascore (is the sum of the scores in second field).
            Nat,
            // A map of games to the players scores from that game.
            HashMap.HashMap<MPublic.GamePrincipal, Nat>,
        );

        // Calculates the global score based on all the game scores of a player.
        private func globalScore(accountId : MAccount.AccountId, m : HashMap.HashMap<MPublic.GamePrincipal, Nat>) : Nat {
            var score = 0;
            for ((gameId, s) in m.entries()) {
                score += metascore(gameId, accountId, s);
            };
            score;
        };

        // User account state.
        public let users = Users.Users(nextAccountId, accounts);

        // [🗄] A map of players to their global scores.
        public let globalLeaderboard : SMap.SortedValueMap<MAccount.AccountId, GlobalScores> = SMap.SortedValueMap(
            0, Nat.equal, Hash.hash,
            // Sort based on the global metascore.
            O.Descending(func((a, _) : GlobalScores, (b, _) : GlobalScores) : Order.Order{ Nat.compare(a, b); }),
        );
        
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

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | THE Metascore calculation... 🏁                                   |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        // Converts game scores to metascores.
        // | gameScore: a non-normalized score coming from a game.
        private func metascore(gameId : MPublic.GamePrincipal, accountId : MAccount.AccountId, gameScore : Nat) : Nat {
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

            // Global Leaderboard.
            for ((accountId, s) in scores.vals()) {
                let (g, ss) : GlobalScores = switch (globalLeaderboard.get(accountId)) {
                    case (null) {
                        (0, HashMap.HashMap<MPublic.GamePrincipal, Nat>(
                            0, Principal.equal, Principal.hash,
                        ));
                    };
                    case (? a) { a; };
                };
                // 1. Add new score to scores.
                let ms = metascore(gameId, accountId, s);
                ss.put(gameId, s);
                globalLeaderboard.put(accountId, (
                    g + ms, // 2. Add score to global total.
                    ss,
                ));
            };
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Adding new scores.                                                |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        public func updateScores(gameId : MPublic.GamePrincipal, scores : [MAccount.Score]) {
            var update = false;
            for (score in scores.vals()) {
                if (_updateScore(gameId, score)) update := true;
            };
            // The top score has changed, so all scores change...
            // [🗑] Recalculating everything...
            if (update) _recalculate(gameId);
        };

        public func updateScore(gameId : MPublic.GamePrincipal, score : MAccount.Score) {
            if (_updateScore(gameId, score)) _recalculate(gameId);
        };

        private func _recalculate(gameId : MPublic.GamePrincipal) {
            switch (gameLeaderboards.get(gameId)) {
                case (null) {
                    // [💀] Unreachable: should not happen.
                    // The game should be already be there...
                    assert(false);
                };
                case (? accountScores) {
                    for ((_, (accountId, score)) in accountScores.entries()) {
                        switch (globalLeaderboard.get(accountId)) {
                            case (null) {
                                // Player has no global scores yet.
                                let ss = HashMap.HashMap<MPublic.GamePrincipal, Nat>(
                                    1, Principal.equal, Principal.hash,
                                );
                                let ms = metascore(gameId, accountId, score);
                                ss.put(gameId, score);
                                globalLeaderboard.put(accountId, (
                                    ms,
                                    ss,
                                ));
                            };
                            case (? (g, ss)) {
                                let ms = metascore(gameId, accountId, score);
                                ss.put(gameId, score);
                                globalLeaderboard.put(accountId, (
                                    globalScore(accountId, ss),
                                    ss,
                                ));
                            };
                        };
                    };
                };
            };
        };

        // Returns whether the global scores need to be recalculated.
        private func _updateScore(gameId : MPublic.GamePrincipal, (accountId, score) : MAccount.Score) : Bool {
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
                    if (score <= os) return false;
                    // Old metascore.
                    let oms = metascore(gameId, accountId, os);
                    // Old index in ranking. Based on this index we need to do some additional calculations...
                    let oi  = switch (globalLeaderboard.getIndexOf(accountId)) {
                        case (null) {
                            // [💀] Unreachable: should not happen.
                            // If a player score is already registered, than it
                            // should also have an entry in the global leaderboard.
                            assert(false); 0;
                        };
                        case (? i) { i; };
                    };
                    // Old top score.
                    let ots = switch (accountScores.getValue(0)) {
                        case (null) {
                            // [💀] Unreachable: should not happen.
                            // If a player score is already registered, than it
                            // should also have a top player.
                            assert(false); 0;
                        };
                        case (? (_, s)) { s; };
                    };

                    accountScores.put(accountId, (accountId, score));
                    gameLeaderboards.put(gameId, accountScores);

                    // Recalculate part of the leaderboard, because of ranking changes.
                    if (oi == 0 or ots < score) return true;

                    // Nothing special... other scores are not influenced by this change.
                    // Since the top score was not improved/changed.
                    switch (globalLeaderboard.get(accountId)) {
                        case (null) {
                            // [💀] Unreachable: should not happen.
                            // If a player score is already registered, than it
                            // should also have an entry in the global leaderboard.
                            assert(false);
                        };
                        case (? (g, ss)) {
                            let ms = metascore(gameId, accountId, score);
                            ss.put(gameId, score);
                            globalLeaderboard.put(accountId, (
                                // The new score should be bigger than the previous one, this is checked above.
                                g + ms - oms,
                                ss,
                            ));
                        };
                    };
                };
                case (null) {
                    // Old top score.
                    let ots = switch (accountScores.getValue(0)) {
                        case (null)     { 0; };
                        case (? (_, s)) { s; };
                    };

                    accountScores.put(accountId, (accountId, score));
                    gameLeaderboards.put(gameId, accountScores);

                    // Recalculate part of the leaderboard, because of ranking changes.
                    if (ots < score) return true;
                    
                    switch (globalLeaderboard.get(accountId)) {
                        case (null) {
                            // Player has no scores yet.
                            let ss = HashMap.HashMap<MPublic.GamePrincipal, Nat>(
                                1, Principal.equal, Principal.hash,
                            );
                            let ms = metascore(gameId, accountId, score);
                            ss.put(gameId, score);
                            globalLeaderboard.put(accountId, (
                                ms,
                                ss,
                            ));
                        };
                        case (? (g, ss)) {
                            // Add new score.
                            let ms = metascore(gameId, accountId, score);
                            ss.put(gameId, score);
                            globalLeaderboard.put(accountId, (
                                g + ms,
                                ss,
                            ));
                        };
                    };
                };
            };
            false;
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Internal Interface, which contains a lot of getters...            |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        public func removeGame(gameId : MPublic.GamePrincipal) {
            switch (gameLeaderboards.get(gameId)) {
                case (null) {
                    // [💀] Unreachable: should not happen.
                    // The game should be already be there...
                    assert(false);
                };
                case (? accountScores) {
                    for ((_, (accountId, score)) in accountScores.entries()) {
                        switch (globalLeaderboard.get(accountId)) {
                            case (null) {};
                            case (? (g, ss)) {
                                let ms = metascore(gameId, accountId, score);
                                ss.delete(gameId);
                                globalLeaderboard.put(accountId, (
                                    globalScore(accountId, ss),
                                    ss,
                                ));
                            };
                        };
                    };
                };
            };
            games.delete(gameId);
            gameLeaderboards.delete(gameId);
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

        public func getDetailedGameScores(gameId : MPublic.GamePrincipal, count : ?Nat, offset : ?Nat) : [MAccount.DetailedScore] {
            let c : Nat = Option.get<Nat>(count,  100);
            let o : Nat = Option.get<Nat>(offset, 0  );
            switch (gameLeaderboards.get(gameId)) {
                case (null) { []; }; // Game not found.
                case (? accountScores) {
                    Array.tabulate<MAccount.DetailedScore>(
                        Nat.min(c, accountScores.size()),
                        func (i : Nat) : MAccount.DetailedScore {
                            switch (accountScores.getIndex(i + o)) {
                                case (null) {};
                                case (? (accountId, (_, score))) {
                                    switch (users.accounts.get(accountId)) {
                                        case (null) {};
                                        case (? account) {
                                            return (
                                                MAccount.getDetails(account),
                                                score,
                                            );
                                        };
                                    };
                                };
                            };
                            ({
                                alias      = null;
                                avatar     = null;
                                flavorText = ?"Dummy account";
                                id         = 0;
                            }, 0);
                        },
                    );
                };
            };
        };

        public func getGames() : [(MPublic.GamePrincipal, MPublic.Metadata)] {
            Iter.toArray(games.entries());
        };

        public func getMetascore(gameId : MPublic.GamePrincipal, accountId : MAccount.AccountId) : Nat {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { 0; }; // Game not found.
                case (? accountScores) {
                    switch (accountScores.get(accountId)) {
                        case (null)     { 0; }; // Player not found.
                        case (? (_, s)) {
                            metascore(gameId, accountId, s);
                        };
                    };
                };
            };
        };

        public func getMetascores(count : ?Nat, offset : ?Nat) : [MAccount.Score] {
            let c : Nat = Option.get<Nat>(count,  100);
            let o : Nat = Option.get<Nat>(offset, 0  );
            Array.tabulate<MAccount.Score>(
                Nat.min(c, globalLeaderboard.size()),
                func (i : Nat) : MAccount.Score {
                    switch (globalLeaderboard.getIndex(i + o)) {
                        case (null) { (0, 0); };
                        case (? (accountId, (score, _))) {
                            (accountId, score);
                        };
                    };
                },
            );
        };

        public func getDetailedMetascores(count : ?Nat, offset : ?Nat) : [MAccount.DetailedScore] {
            let c : Nat = Option.get<Nat>(count,  100);
            let o : Nat = Option.get<Nat>(offset, 0  );
            Array.tabulate<MAccount.DetailedScore>(
                Nat.min(c, globalLeaderboard.size()),
                func (i : Nat) : MAccount.DetailedScore {
                    switch (globalLeaderboard.getIndex(i + o)) {
                        case (null) {};
                        case (? (accountId, (score, _))) {
                            switch (users.accounts.get(accountId)) {
                                case (null) {};
                                case (? account) {
                                    return (
                                        MAccount.getDetails(account),
                                        score,
                                    );
                                };
                            };
                        };
                    };
                    ({
                        alias      = null;
                        avatar     = null;
                        flavorText = ?"Dummy account";
                        id         = 0;
                    }, 0);
                },
            );
        };

        public func getOverallMetascore(accountId : MAccount.AccountId) : Nat {
            switch (globalLeaderboard.get(accountId)) {
                case (null)     { 0; };
                case (? (s, _)) { s; };
            };
        };

        public func getPercentile(accountId : MAccount.AccountId) : ?Float {
            switch (globalLeaderboard.getIndexOf(accountId)) {
                case (null) { null; };
                case (? i)  {
                    let n = Float.fromInt(globalLeaderboard.size());
                    ?((n - Float.fromInt(i)) / n);
                };
            };
        };

        public func getPercentileMetascore(p : Float) : Nat {
            let i = Int.abs(Float.toInt(Float.ceil(
                Float.fromInt(globalLeaderboard.size()) * (1 - p),
            )));
            if (i >= globalLeaderboard.size()) {
                // Occurs when you want to get a percentile lower than 1/n.
                return 0;
            };

            switch (globalLeaderboard.getValue(i)) {
                case (null) {
                    // [💀] Unreachable: should not happen.
                    // Since we used the global leaderboard size, times [0-1],
                    // there should always be a result.
                    assert(false); 0;
                };
                case (? (s, _)) { s; };
            };
        };

        public func getPlayerCount() : Nat {
            globalLeaderboard.size();
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

        public func getTop(n : Nat) : [MAccount.Score] {
            Array.tabulate<MAccount.Score>(
                Nat.min(n, globalLeaderboard.size()),
                func (i : Nat) : MAccount.Score {
                    switch (globalLeaderboard.getIndex(i)) {
                        case (null) { (0, 0); };
                        case (? (accountId, (score, _))) {
                            (accountId, score);
                        };
                    };
                },
            );
        };
    };
};