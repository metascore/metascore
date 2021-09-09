import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import O "mo:sorted/Order";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import SMap "mo:sorted/Map";

import Player "Player";
import MPublic "../src/Metascore";

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

    public type Players = SMap.SortedValueMap<
        MPublic.Player, // Player principal id.
        PlayerRecord,   // Player state.
    >;

    public func emptyPlayers(n : Nat) : Players {
        let playerCompare = func (a : PlayerRecord, b : PlayerRecord) : Order.Order {
            Nat.compare(a.score, b.score);
        };
        SMap.SortedValueMap<MPublic.Player, PlayerRecord>(
            n, Player.equal, Player.hash,
            O.Descending(playerCompare),
        );
    };

    // Internal representation of a player.
    public type PlayerRecord = {
        player : MPublic.Player; // Player principal id.
        score  : Nat;            // Player score (not normalized!).
    };

    // Internal representation of a game.
    public type GameRecord = {
        // Name of the game.
        metadata : MPublic.Metadata;
        // List of players.
        players : SMap.SortedValueMap<MPublic.Player, PlayerRecord>;
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
};
