import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import O "mo:sorted/Order";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import SMap "mo:sorted/Map";

import MPublic "../src/Metascore";
import MPlayer "../src/Player";
import PR "PlayerRecord";

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
        players : SMap.SortedValueMap<MPlayer.Player, PR.PlayerRecord>;
    };

    // Stable version of a GameRecord.
    public type GameRecordStable = (
        MPublic.GamePrincipal,              // Game principal ID.
        (MPublic.Metadata, [PR.PlayerRecord]), // Game metadata and scores.
    );

    public func fromStable(records : [GameRecordStable]) : Games {
        let games = emptyGames(records.size());
        for ((gameID, (metadata, players)) in records.vals()) {
            games.put(gameID, {
                metadata;
                players = PR.playersFromArray(players);
            });
        };
        games;
    };

    public func toStable(records : Games) : [GameRecordStable] {
        var games : [GameRecordStable] = [];
        for ((gID, r) in records.entries()) {
            games := Array.append<GameRecordStable>(games, [(
                gID, (
                    r.metadata, 
                    PR.playersToArray(r.players),
                ),
            )]);
        };
        games;
    };
};
