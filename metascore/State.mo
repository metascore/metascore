import Array "mo:base/Array";
import Float "mo:base/Float";
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

import MPlayer "../src/Player";
import MPublic "../src/Metascore";

module {
    public type StableGame = (
        MPublic.GamePrincipal,
        (MPublic.Metadata, [MPublic.Score]),
    );
    
    // Converts the state to its corresponing stable form.
    public func toStable(s : State) : [StableGame] {
        var games : [StableGame] = [];
        for ((gameId, playerScores) in s.gameLeaderboards.entries()) {
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
            var scores : [(MPlayer.Player, Nat)] = [];
            for ((_, playerScore) in playerScores.entries()) {
                scores := Array.append<MPublic.Score>(
                    scores, [playerScore],
                );
            };
            games := Array.append<StableGame>(games, [(
                gameId, (metadata, scores),
            )])
        };
        games;
    };

    // Compares two player scores.
    public let comparePlayerScores = func ((_, a) : MPublic.Score, (_, b) : MPublic.Score) : Order.Order {
        Nat.compare(a, b);
    };

    public class State(
        state : [StableGame],
    ) : Interface.StateInterface {        
        // Tuple of a global scores and individual scores per game.
        private type GlobalScores = (
            // Global metascore (is the sum of the scores in second field).
            Nat,
            // A map of games to the players scores from that game.
            HashMap.HashMap<MPublic.GamePrincipal, Nat>,
        );

        // Calculates the global score based on all the game scores of a player.
        private func globalScore(m : HashMap.HashMap<MPublic.GamePrincipal, Nat>) : Nat {
            var score = 0;
            for ((gameId, s) in m.entries()) {
                score += metascore(gameId, s);
            };
            score;
        };

        // [🗄] A map of players to their global scores.
        public let globalLeaderboard : SMap.SortedValueMap<MPlayer.Player, GlobalScores> = SMap.SortedValueMap(
            0, MPlayer.equal, MPlayer.hash,
            // Sort based on the global metascore.
            O.Descending(func((a, _) : GlobalScores, (b, _) : GlobalScores) : Order.Order{ Nat.compare(a, b); }),
        );
        
        // A map of players to their game scores.
        private type PlayerScores = SMap.SortedValueMap<MPlayer.Player, MPublic.Score>;

        // [🗄] A map of games to their player scores.
        public let gameLeaderboards : HashMap.HashMap<MPublic.GamePrincipal, PlayerScores> = HashMap.HashMap(
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
        private let T1 = 1_000_000_000_000;
        private func metascore(gameId : MPublic.GamePrincipal, gameScore : Nat) : Nat {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { return 0; };
                case (? playerScores) {
                    switch (playerScores.getValue(0)) {
                        case (null) {
                            // No scores yet?
                            return T1;
                        };
                        case (? (_, s)) {
                            // You get 0.5T for participation.
                            // You can get up to 0.5T based on your score relative to the best score.
                            let topScore   = Float.fromInt(s);
                            let normalized = Float.fromInt(gameScore) / topScore;
                            Int.abs(Float.toInt(Float.fromInt(T1) * (0.5 + normalized / 2)));
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
            let playerScores = SMap.SortedValueMap<MPlayer.Player, MPublic.Score>(
                scores.size(), MPlayer.equal, MPlayer.hash,
                O.Descending(comparePlayerScores),
            );
            for ((p, s) in scores.vals()) {
                playerScores.put(p, (p, s));
            };
            gameLeaderboards.put((gameId, playerScores));

            // Global Leaderboard.
            for ((p, s) in scores.vals()) {
                let (g, ss) : GlobalScores = switch (globalLeaderboard.get(p)) {
                    case (null) {
                        (0, HashMap.HashMap<MPublic.GamePrincipal, Nat>(
                            0, Principal.equal, Principal.hash,
                        ));
                    };
                    case (? p) { p; };
                };
                // 1. Add new score to scores.
                let ms = metascore(gameId, s);
                ss.put(gameId, s);
                globalLeaderboard.put(p, (
                    g + ms, // 2. Add score to global total.
                    ss,
                ));
            };
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Adding new scores.                                                |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        public func updateScores(gameId : MPublic.GamePrincipal, scores : [MPublic.Score]) {
            var update = false;
            for (score in scores.vals()) {
                if (_updateScore(gameId, score)) update := true;
            };
            // The top score has changed, so all scores change...
            // [🗑] Recalculating everything...
            if (update) _recalculate(gameId);
        };

        public func updateScore(gameId : MPublic.GamePrincipal, score : MPublic.Score) {
            if (_updateScore(gameId, score)) _recalculate(gameId);
        };

        private func _recalculate(gameId : MPublic.GamePrincipal) {
            switch (gameLeaderboards.get(gameId)) {
                case (null) {
                    // [💀] Unreachable: should not happen.
                    // The game should be already be there...
                    assert(false);
                };
                case (? playerScores) {
                    for ((_, (playerId, score)) in playerScores.entries()) {
                        switch (globalLeaderboard.get(playerId)) {
                            case (null) {
                                // Player has no global scores yet.
                                let ss = HashMap.HashMap<MPublic.GamePrincipal, Nat>(
                                    1, Principal.equal, Principal.hash,
                                );
                                let ms = metascore(gameId, score);
                                ss.put(gameId, score);
                                globalLeaderboard.put(playerId, (
                                    ms,
                                    ss,
                                ));
                            };
                            case (? (g, ss)) {
                                let ms = metascore(gameId, score);
                                ss.put(gameId, score);
                                globalLeaderboard.put(playerId, (
                                    globalScore(ss),
                                    ss,
                                ));
                            };
                        };
                    };
                };
            };
        };

        // Returns whether the global scores need to be recalculated.
        private func _updateScore(gameId : MPublic.GamePrincipal, (playerId, score) : MPublic.Score) : Bool {
            let playerScores = switch (gameLeaderboards.get(gameId)) {
                case (null) {
                    SMap.SortedValueMap<MPlayer.Player, MPublic.Score>(
                        0, MPlayer.equal, MPlayer.hash,
                        O.Descending(comparePlayerScores),
                    );
                };
                case (? ps) { ps; };
            };
            switch (playerScores.get(playerId)) {
                case (? (_, os)) {
                    // Score is already the same, no need to update anything.
                    if (score <= os) return false;
                    // Old metascore.
                    let oms = metascore(gameId, os);
                    // Old index in ranking. Based on this index we need to do some additional calculations...
                    let oi  = switch (globalLeaderboard.getIndexOf(playerId)) {
                        case (null) {
                            // [💀] Unreachable: should not happen.
                            // If a player score is already registered, than it
                            // should also have an entry in the global leaderboard.
                            assert(false); 0;
                        };
                        case (? i) { i; };
                    };
                    // Old top score.
                    let ots = switch (playerScores.getValue(0)) {
                        case (null) {
                            // [💀] Unreachable: should not happen.
                            // If a player score is already registered, than it
                            // should also have a top player.
                            assert(false); 0;
                        };
                        case (? (_, s)) { s; };
                    };

                    playerScores.put(playerId, (playerId, score));
                    gameLeaderboards.put(gameId, playerScores);

                    // Recalculate part of the leaderboard, because of ranking changes.
                    if (oi == 0 or ots < score) return true;

                    // Nothing special... other scores are not influenced by this change.
                    // Since the top score was not improved/changed.
                    switch (globalLeaderboard.get(playerId)) {
                        case (null) {
                            // [💀] Unreachable: should not happen.
                            // If a player score is already registered, than it
                            // should also have an entry in the global leaderboard.
                            assert(false);
                        };
                        case (? (g, ss)) {
                            let ms = metascore(gameId, score);
                            ss.put(gameId, score);
                            globalLeaderboard.put(playerId, (
                                // The new score should be bigger than the previous one, this is checked above.
                                g + ms - oms,
                                ss,
                            ));
                        };
                    };
                };
                case (null) {
                    // Old top score.
                    let ots = switch (playerScores.getValue(0)) {
                        case (null)     { 0; };
                        case (? (_, s)) { s; };
                    };

                    playerScores.put(playerId, (playerId, score));
                    gameLeaderboards.put(gameId, playerScores);

                    // Recalculate part of the leaderboard, because of ranking changes.
                    if (ots < score) return true;
                    
                    switch (globalLeaderboard.get(playerId)) {
                        case (null) {
                            // Player has no scores yet.
                            let ss = HashMap.HashMap<MPublic.GamePrincipal, Nat>(
                                1, Principal.equal, Principal.hash,
                            );
                            let ms = metascore(gameId, score);
                            ss.put(gameId, score);
                            globalLeaderboard.put(playerId, (
                                ms,
                                ss,
                            ));
                        };
                        case (? (g, ss)) {
                            // Add new score.
                            let ms = metascore(gameId, score);
                            ss.put(gameId, score);
                            globalLeaderboard.put(playerId, (
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

        public func getGameScores(gameId : MPublic.GamePrincipal, count : ?Nat, offset : ?Nat) : [MPublic.Score] {
            let c : Nat = Option.get<Nat>(count,  100);
            let o : Nat = Option.get<Nat>(offset, 0  );
            switch (gameLeaderboards.get(gameId)) {
                case (null) { []; }; // Game not found.
                case (? playerScores) {
                    Array.tabulate<MPublic.Score>(
                        Nat.min(c, playerScores.size()),
                        func (i : Nat) : MPublic.Score {
                            switch (playerScores.getValue(i + o)) {
                                case (? s)  { s; };
                                case (null) { (#plug(Principal.fromText("aaaaa-aa")), 0); };
                            };
                        },
                    );
                };
            };
        };

        public func getGames() : [(MPublic.GamePrincipal, MPublic.Metadata)] {
            Iter.toArray(games.entries());
        };

        public func getMetascore(gameId : MPublic.GamePrincipal, playerId : MPlayer.Player) : Nat {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { 0; }; // Game not found.
                case (? playerScores) {
                    switch (playerScores.get(playerId)) {
                        case (null)     { 0; }; // Player not found.
                        case (? (_, s)) {
                            metascore(gameId, s);
                        };
                    };
                };
            };
        };

        public func getMetascores(count : ?Nat, offset : ?Nat) : [MPublic.Score] {
            let c : Nat = Option.get<Nat>(count,  100);
            let o : Nat = Option.get<Nat>(offset, 0  );
            Array.tabulate<MPublic.Score>(
                Nat.min(c, globalLeaderboard.size()),
                func (i : Nat) : MPublic.Score {
                    switch (globalLeaderboard.getIndex(i + o)) {
                        case (null) { (#plug(Principal.fromText("aaaaa-aa")), 0); };
                        case (? (playerId, (score, _))) {
                            (playerId, score);
                        };
                    };
                },
            );
        };

        public func getOverallMetascore(playerId : MPlayer.Player) : Nat {
            switch (globalLeaderboard.get(playerId)) {
                case (null)     { 0; };
                case (? (s, _)) { s; };
            };
        };

        public func getPercentile(gameId : MPublic.GamePrincipal, playerId : MPlayer.Player) : ?Float {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { null; };
                case (? playerScores) {
                    switch (playerScores.getIndexOf(playerId)) {
                        case (null) { null; };
                        case (? i)  {
                            let n = Float.fromInt(playerScores.size());
                            ?((n - Float.fromInt(i)) / n);
                        };
                    };
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

        public func getRanking(gameId : MPublic.GamePrincipal, playerId : MPlayer.Player) : ?Nat {
            switch (gameLeaderboards.get(gameId)) {
                case (null) { null; };
                case (? playerScores) {
                    switch (playerScores.getIndexOf(playerId)) {
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

        public func getTop(n : Nat) : [MPublic.Score] {
            Array.tabulate<MPublic.Score>(
                Nat.min(n, globalLeaderboard.size()),
                func (i : Nat) : MPublic.Score {
                    switch (globalLeaderboard.getIndex(i)) {
                        case (null) { (#plug(Principal.fromText("aaaaa-aa")), 0); };
                        case (? (playerId, (score, _))) {
                            (playerId, score);
                        };
                    };
                },
            );
        };
    };
};