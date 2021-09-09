import Array "mo:base/Array";
import AssetStorage "mo:http/AssetStorage";
import Blob "mo:base/Blob";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";

import GameRecord "GameRecord";
import M "Metascore";
import MPublic "../src/Metascore";
import MPlayer "../src/Player";

import Debug "mo:base/Debug";

shared ({caller = owner}) actor class Metascore() : async M.FullInterface {
    // Time since last cron call.
    private stable var lastCron : Int = Time.now();
    // Map of registered game canisters.
    private var games : [GameRecord.GameRecordStable] = [];
    private let state = M.Metascore(games);
    private let scores = GameRecord.emptyPlayerScores(games.size());

    system func preupgrade() {
        games := GameRecord.toStable(state.games);
    };

    system func postupgrade() {
        for ((gID, (_, ps)) in games.vals()) {
            for (p in ps.vals()) {
                let pID = p.player;
                switch (scores.get(pID)) {
                    case (null) {
                        let ps = GameRecord.emptyPlayerGameScores(1);
                        ps.put(gID, state.getMetascore(gID, pID));
                        scores.put(pID, ps);
                    };
                    case (? ps) {
                        ps.put(gID, state.getMetascore(gID, pID));
                        scores.put(pID, ps);
                    };
                };
            };
        };
        games := [];
    };

    // List of Metascore admins, these are principals that can trigger the cron,
    // add other admins and remove games.
    private stable var admins = [owner];

    private func _isAdmin(p : Principal) : Bool {
        for (a in admins.vals()) {
            if (a == p) { return true; };
        };
        false;
    };

    // Adds a new principal as an admin.
    // @auth: owner
    public shared({caller}) func addAdmin(p : Principal) : async () {
        assert(caller == owner);
        admins := Array.append(admins, [p]);
    };

    // Removes the given principal from the list of admins.
    // @auth: owner
    public shared({caller}) func removeAdmin(p : Principal) : async () {
        assert(caller == owner);
        admins := Array.filter(
            admins,
            func (a : Principal) : Bool {
                a != p;
            },
        );
    };

    // Check whether the given principal is an admin.
    // @auth: admin
    public query({caller}) func isAdmin(p : Principal) : async Bool {
        assert(_isAdmin(caller));
        for (a in admins.vals()) {
            if (a == p) return true;
        };
        return false;
    };

    public func register(
        id : MPublic.GamePrincipal,
    ) : async Result.Result<(), Text> {
        switch (state.games.get(id)) {
            case (? g)  { #ok(); };
            case (null) {
                try {
                    let game : MPublic.GameInterface = actor(Principal.toText(id));
                    await game.metascoreRegisterSelf(registerGame);
                    #ok();
                } catch (e) {
                    #err("Could not register game with principal ID: " # Principal.toText(id));
                };
            };
        };
    };

    public shared({caller}) func unregister(
        id : MPublic.GamePrincipal,
    ) : async () {
        assert(_isAdmin(caller) or id == caller);
        state.games.delete(id);
    };

    public shared({caller}) func scoreUpdate(
        scores : [MPublic.Score],
    ) : async() {
        switch (state.games.get(caller)) {
            // Means that the caller was not the game canister itself.
            case (null) {};
            case (? g)  {
                putGameRecord(caller, g.metadata, sortScores(scores));
            };
        };
    };

    public shared({caller}) func registerGame(
        metadata : MPublic.Metadata
    ) : async () {
        let scores = await getScores(caller);
        putGameRecord(caller, metadata, scores);
    };

    private let sec = 1_000_000_000;

    // Endpoint to trigger cron-like operations.
    // Fastest interval = 3 sec.
    public shared ({caller}) func cron() : async () {
        assert(_isAdmin(caller));

        let now = Time.now();
        if (3 * sec < now - lastCron) {
            await queryAllScores();
            lastCron := now;
        };
    };

    private func putGameRecord(
        gameID   : MPublic.GamePrincipal,
        metadata : MPublic.Metadata,
        players  : [GameRecord.PlayerRecord],
    ) {
        switch (state.games.get(gameID)) {
            case (null) {
                state.games.put(gameID, {
                    metadata;
                    players = GameRecord.playersFromArray(players); 
                });
            };
            case (? gr) {
                let ps = gr.players;
                for (p in players.vals()) {
                    let pID = p.player;
                    gr.players.put(pID, p);
                };
                state.games.put(gameID, {
                    metadata = gr.metadata;
                    players  = ps;
                });
             };
        };
        Debug.print(debug_show(players.size()));
        for (p in players.vals()) {
            let pID = p.player;
            switch (scores.get(pID)) {
                case (null) {
                    let ps = GameRecord.emptyPlayerGameScores(1);
                    ps.put(gameID, state.getMetascore(gameID, pID));
                    scores.put(pID, ps);
                };
                case (? ps) {
                    ps.put(gameID, state.getMetascore(gameID, pID));
                    scores.put(pID, ps);
                };
            };
        };
    };

    private func queryAllScores() : async () {
        for ((gID, g) in state.games.entries()) {
            let scores = await getScores(gID);
            putGameRecord(gID, g.metadata, scores);
        };
    };

    private func getScores(id : MPublic.GamePrincipal) : async [GameRecord.PlayerRecord] {
        let game : MPublic.GameInterface = actor(Principal.toText(id));
        sortScores(await game.metascoreScores());
    };

    private func sortScores(scores : [MPublic.Score]) : [GameRecord.PlayerRecord] {
        Array.sort<GameRecord.PlayerRecord>(
            Array.map<MPublic.Score, GameRecord.PlayerRecord>(
                scores,
                func ((player, score) : MPublic.Score) : GameRecord.PlayerRecord {
                    { player; score; };
                },
            ),
            // Sort from high to low.
            func (a : GameRecord.PlayerRecord, b : GameRecord.PlayerRecord) : Order.Order {
                let (x, y) = (a.score, b.score);
                if      (x < y)  { #greater; }
                else if (x == y) { #equal;   }
                else             { #less;    };
            },
        );
    };

    public query func getPercentile(
        game    : MPublic.GamePrincipal,
        player  : MPlayer.Player,
    ) : async ?Float {
        state.getPercentile(game, player);
    };

    public query func getRanking(
        game    : MPublic.GamePrincipal,
        player  : MPlayer.Player,
    ) : async ?Nat {
        state.getRanking(game, player);
    };

    public query func getMetascore(
        game    : MPublic.GamePrincipal,
        player  : MPlayer.Player,
    ) : async Nat {
        state.getMetascore(game, player);
    };

    public query func getOverallMetascore(
        player  : MPlayer.Player,
    ) : async Nat {
        state.getOverallMetascore(player);
    };

    public query func getGames() : async [MPublic.Metadata] {
        state.getGames();
    };

    public query func http_request(
        r : AssetStorage.HttpRequest,
    ) : async AssetStorage.HttpResponse {
        var text = "<html><title>Metascore</title><body>";
        text #= "<h1>Hello world!</h1>";
        for ((gID, g) in state.games.entries()) {
            text #= "<div>";
            text #= "<h2>" # g.metadata.name # " (" # Principal.toText(gID) # ")</h2>";
            text #= "<h3>Top 3</h3>";
            text #= "<ol>";
            for (i in Iter.range(0, 2)) {
                switch (g.players.getValue(i)) {
                    case (null) {};
                    case (? p)  {
                        text #= "<li>" # MPlayer.toText(p.player) # "</li>";
                    };
                };
            };
            text #= "</ol>";
            text #= "</div>";
        };
        text #= "</body></html>";
        {
            body               = Blob.toArray(Text.encodeUtf8(text));
            headers            = [("Content-Type", "text/html; charset=UTF-8")];
            streaming_strategy = null;
            status_code        = 200;
        };
    };
};
