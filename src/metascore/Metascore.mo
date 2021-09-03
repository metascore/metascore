import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Player "Player";

module {
    public type Score = (
        Player.Player, // Wallet address of the player.
        Nat,           // Score of the player.
    );
    public type Scores = [Score];

    public type Metadata = {
        name : Text; // Name of the game.
        // TODO: add more fields (e.g. genre, ...)
    };

    // Callback on which new games should register.
    public type RegisterCallback = shared (
        metadata : Metadata
    ) -> async ();

    public type GameInterface = actor {
        // Methods that needs to be called to register a new game.
        // Can be called by any principal account.
        register : (Principal) -> async Result.Result<(), Text>;

        // Callback to register games, should not get invoked directly.
        registerGame : RegisterCallback;
    };

    public type Interface = actor {
        register     : (Principal) -> async Result.Result<(), Text>;
        registerGame : RegisterCallback;

        getPercentile : query (Principal, Player.Player) -> async ?Float;
    };

    public type MetascoreInterface = {
        getPercentile         : (Principal, Player.Player) -> ?Float;
        getRanking            : (Principal, Player.Player) -> ?Nat;
        getGameScoreComponent : (Principal, Player.Player) -> ?Nat;

        getGame    : Principal -> ?GameRecord;
        addGame    : (Principal, GameRecord) -> ();
        updateGame : (Principal, GameRecord) -> ();
        gameIDs    : () -> Iter.Iter<Principal>;
        games      : () -> Iter.Iter<(Principal, GameRecord)>;
    };

    public type GameRecord = {
        name          : Text;
        rawScores     : Scores;
        playerRanking : HashMap.HashMap<Player.Player, Nat>;
    };

    public class Metascore() : MetascoreInterface {
        private let gameCanisters = HashMap.HashMap<Principal, GameRecord>(
            0, Principal.equal, Principal.hash,
        );

        public func getPercentile(
            game    : Principal,
            player  : Player.Player,
        ) : ?Float {
            switch (gameCanisters.get(game)) {
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
            game    : Principal,
            player  : Player.Player,
        ) : ?Nat {
            switch (gameCanisters.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.playerRanking.get(player)) {
                        case (null) { null; };
                        case (? r)  { ?r    };
                    };
                };
            };
        };

        public func getGameScoreComponent (
            game    : Principal,
            player  : Player.Player,
        ) : ?Nat {
            // To drive people to try all games, 1/2 of points awarded for participation.
            var score : Float = 0.5;
            switch (getPercentile(game, player)) {
                case (null) return null;
                case (?percentile) {
                    // Players get up to 1/4 of available points based on performance.
                    score += 0.25 * percentile;
                    switch (getRanking(game, player)) {
                        case (null) return null;
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
            ?Int.abs(Float.toInt(score * 1_000_000_000_000));
        };

        public func getGame(gameID : Principal) : ?GameRecord {
            gameCanisters.get(gameID);
        };

        public func addGame(gameID : Principal, record : GameRecord) {
            gameCanisters.put(gameID, record);
        };

        public func updateGame(gameID : Principal, record : GameRecord) {
            gameCanisters.put(gameID, record);
        };

        public func gameIDs() : Iter.Iter<Principal> {
            Iter.map<(Principal, GameRecord), Principal>(gameCanisters.entries(), func ((p, _)) : Principal { p; });
        };

        public func games() : Iter.Iter<(Principal, GameRecord)> {
            gameCanisters.entries();
        };
    };
};
