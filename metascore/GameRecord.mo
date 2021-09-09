import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import O "mo:sorted/Order";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import SMap "mo:sorted/Map";

import MPublic "../src/Metascore";
import MPlayer "../src/Player";

module {
    public type Games = HashMap.HashMap<
        MPublic.GamePrincipal, // Game principal id.
        GameRecord,            // Game state.
    >;

    public func emptyGames(n : Nat) : Games {
        HashMap.HashMap<MPublic.GamePrincipal, GameRecord>(
            n, Principal.equal, Principal.hash,
        );
    };

    // Internal representation of a game.
    public type GameRecord = {
        // Name of the game.
        metadata : MPublic.Metadata;
        // List of players.
        players : SMap.SortedValueMap<MPlayer.Player, PlayerRecord>;
    };

    // Stable version of a GameRecord.
    public type GameRecordStable = (
        MPublic.GamePrincipal,              // Game principal ID.
        (MPublic.Metadata, [PlayerRecord]), // Game metadata and scores.
    );

    public func fromStable(records : [GameRecordStable]) : Games {
        let xs = emptyGames(records.size());
        for ((gameID, (metadata, players)) in records.vals()) {
            xs.put(gameID, {
                metadata;
                players = playersFromArray(players);
            });
        };
        xs;
    };

    public func toStable(records : Games) : [GameRecordStable] {
        var xs : [GameRecordStable] = [];
        for ((gID, r) in records.entries()) {
            xs := Array.append<GameRecordStable>(xs, [(
                gID, (
                    r.metadata, 
                    playersToArray(r.players),
                ),
            )]);
        };
        xs;
    };

    public type Players = SMap.SortedValueMap<
        MPlayer.Player, // Player principal id.
        PlayerRecord,   // Player state.
    >;

    public func emptyPlayers(n : Nat) : Players {
        let playerCompare = func (a : PlayerRecord, b : PlayerRecord) : Order.Order {
            Nat.compare(a.score, b.score);
        };
        SMap.SortedValueMap<MPlayer.Player, PlayerRecord>(
            n, MPlayer.equal, MPlayer.hash,
            O.Descending(playerCompare),
        );
    };

    // Internal representation of a player.
    public type PlayerRecord = {
        player : MPlayer.Player; // Player principal id.
        score  : Nat;           // Player score (not normalized!).
    };

    public func playersFromArray(players : [PlayerRecord]) : Players {
        let ps = emptyPlayers(players.size());
        for (p in players.vals()) {
            ps.put(p.player, p);
        };
        ps;
    };

    public func playersToArray(players : Players) : [PlayerRecord] {
        var ps : [PlayerRecord] = [];
        for ((_, p) in players.entries()) {
            ps := Array.append(ps, [p]);
        };
        ps;
    };

    public type Metascore = Nat;

    public type PlayerScores = SMap.SortedValueMap<
        MPlayer.Player,
        PlayerGameScores,
    >;

    public func emptyPlayerScores(n : Nat) : PlayerScores {
        func sum(playerScores : HashMap.HashMap<MPublic.GamePrincipal, Metascore>) : Metascore {
            var score = 0;
            for ((_, s) in playerScores.entries()) {
                score += s;
            };
            score;
        };
        let playerScoresCompare = func (
            a : PlayerGameScores,
            b : PlayerGameScores,
        ) : Order.Order {
            Nat.compare(sum(a), sum(b));
        };
        SMap.SortedValueMap<
            MPlayer.Player,
            PlayerGameScores,
        >(
            n, MPlayer.equal, MPlayer.hash,
            O.Descending(playerScoresCompare),
        );
    };

    public type PlayerGameScores = HashMap.HashMap<
        MPublic.GamePrincipal,
        Metascore,
    >;

    public func emptyPlayerGameScores(n : Nat) : PlayerGameScores {
        HashMap.HashMap<
            MPublic.GamePrincipal,
            Metascore,
        >(n, Principal.equal, Principal.hash);
    };
};
