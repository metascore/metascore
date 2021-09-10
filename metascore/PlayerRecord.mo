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
        let playerScoresCompare = func (
            a : PlayerGameScores,
            b : PlayerGameScores,
        ) : Order.Order {
            Nat.compare(totalScore(a), totalScore(b));
        };
        SMap.SortedValueMap<
            MPlayer.Player,
            PlayerGameScores,
        >(
            n, MPlayer.equal, MPlayer.hash,
            O.Descending(playerScoresCompare),
        );
    };

    public func totalScore(playerScores : PlayerGameScores) : Metascore {
        var score = 0;
        for ((_, s) in playerScores.entries()) {
            score += s;
        };
        score;
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
