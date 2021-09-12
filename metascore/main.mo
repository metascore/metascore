import Array "mo:base/Array";
import AssetStorage "mo:http/AssetStorage";
import Blob "mo:base/Blob";
import Float "mo:base/Float";
import Error "mo:base/Error";
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

import GR "GameRecord";
import Interface "Interface";
import M "Metascore";
import PR "PlayerRecord";

import MPublic "../src/Metascore";
import MPlayer "../src/Player";

shared ({caller = owner}) actor class Metascore() : async Interface.FullInterface {
    // Time since last cron call.
    private stable var lastCron : Int = Time.now();

    // Map of registered game canisters.
    private stable var games : [GR.GameRecordStable] = [];
    private let state = M.Metascore(games);
    // Map of player scores.
    private let scores = PR.emptyPlayerScores(games.size());

    system func preupgrade() {
        games := GR.toStable(state.games);
    };

    system func postupgrade() {
        for ((gID, (_, ps)) in games.vals()) {
            for (p in ps.vals()) {
                let pID = p.player;
                switch (scores.get(pID)) {
                    case (null) {
                        let ps = PR.emptyPlayerGameScores(1);
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

    // Register a new game. The metascore canister will check whether the given
    // principal ID (canister) implements the Metascore game interface. If so,
    // it will query the metascoreRegisterSelf endpoint.
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
                    #err("Could not register game with principal ID: " # Principal.toText(id) # " (" # Error.message(e) # ")");
                };
            };
        };
    };

    // Callback that gets passed by the register endpoint.
    public shared({caller}) func registerGame(
        metadata : MPublic.Metadata
    ) : async () {
        let scores = await getScores(caller);
        putGameRecord(caller, metadata, scores);
    };

    // Allows owners and games to unregister games/themselves.
    public shared({caller}) func unregister(
        id : MPublic.GamePrincipal,
    ) : async () {
        assert(_isAdmin(caller) or id == caller);
        state.games.delete(id);
    };

    // Allows games to send score updates. These updates don't need to be the
    // full leaderboard, but can only contain new/updated scores. The whole
    // leaderboard will occasionally get queried on the metascoreScores endpoint.
    public shared({caller}) func scoreUpdate(
        scores : [MPublic.Score],
    ) : async() {
        switch (state.games.get(caller)) {
            case (null) {
                // Means that the caller was not the game canister itself.
                assert(false);
            };
            case (? g)  {
                putGameRecord(caller, g.metadata, sortScores(scores));
            };
        };
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

    // Gets all scores form every game.
    // Currently only used by the cron.
    private func queryAllScores() : async () {
        for ((gID, g) in state.games.entries()) {
            let scores = await getScores(gID);
            putGameRecord(gID, g.metadata, scores);
        };
    };

    private func putGameRecord(
        gameID   : MPublic.GamePrincipal,
        metadata : MPublic.Metadata,
        players  : [PR.PlayerRecord],
    ) {
        switch (state.games.get(gameID)) {
            // Game has no scores yet.
            case (null) {
                // Add scores to state.
                state.games.put(gameID, {
                    metadata;
                    players = PR.playersFromArray(players); 
                });
                // Store individual player scores.
                for (p in players.vals()) {
                    let pID = p.player;
                    switch (scores.get(pID)) {
                        // Create new player, if no scores yet.
                        case (null) {
                            let ps = PR.emptyPlayerGameScores(1);
                            ps.put(gameID, state.getMetascore(gameID, pID));
                            scores.put(pID, ps);
                        };
                        // Update scores for game.
                        case (? ps) {
                            ps.put(gameID, state.getMetascore(gameID, pID));
                            scores.put(pID, ps);
                        };
                    };
                };
            };
            // Update existing game scores.
            case (? gr) {
                // Update game state by updating previous player state.
                let ps = gr.players;
                for (p in players.vals()) {
                    let pID = p.player;
                    gr.players.put(pID, p);
                };
                state.games.put(gameID, {
                    metadata = gr.metadata;
                    players  = ps;
                });
                // Update individual player scores.
                for ((_, p) in ps.entries()) {
                    let pID = p.player;
                    // Create new player, if no scores yet.
                    switch (scores.get(pID)) {
                        case (null) {
                            let ps = PR.emptyPlayerGameScores(1);
                            ps.put(gameID, state.getMetascore(gameID, pID));
                            scores.put(pID, ps);
                        };
                        // Update scores for game.
                        case (? ps) {
                            ps.put(gameID, state.getMetascore(gameID, pID));
                            scores.put(pID, ps);
                        };
                    };
                };
             };
        };
    };

    // Get all scores of a specific game. Returns a list of sorted scores (high to low).
    private func getScores(id : MPublic.GamePrincipal) : async [PR.PlayerRecord] {
        let game : MPublic.GameInterface = actor(Principal.toText(id));
        sortScores(await game.metascoreScores());
    };

    private func sortScores(scores : [MPublic.Score]) : [PR.PlayerRecord] {
        Array.sort<PR.PlayerRecord>(
            Array.map<MPublic.Score, PR.PlayerRecord>(
                scores,
                func ((player, score) : MPublic.Score) : PR.PlayerRecord {
                    { player; score; };
                },
            ),
            // Sort from high to low.
            func (a : PR.PlayerRecord, b : PR.PlayerRecord) : Order.Order {
                let (x, y) = (a.score, b.score);
                if      (x < y)  { #greater; }
                else if (x == y) { #equal;   }
                else             { #less;    };
            },
        );
    };

    // Return the top n players. Can return less if the number of players is
    // less than n.
    public query func getTop(n : Nat) : async [MPublic.Score] {
        var top : [MPublic.Score] = [];
        for ((p, scores) in scores.entries()) {
            top := Array.append<MPublic.Score>(top, [(
                p, PR.totalScore(scores)
            )]);
        };
        top;
    };

    // Returns the percentile of a player in a specific game.
    // Null gets return if the player has no score for that game.
    public query func getPercentile(
        game    : MPublic.GamePrincipal,
        player  : MPlayer.Player,
    ) : async ?Float {
        state.getPercentile(game, player);
    };

    // Returns the ranking of a player in a specific game (1-index based).
    // Null gets return if the player has no score for that game.
    public query func getRanking(
        game    : MPublic.GamePrincipal,
        player  : MPlayer.Player,
    ) : async ?Nat {
        state.getRanking(game, player);
    };

    // Returns the metascore of a player in a specific game ([0-1T] points).
    // 0 gets return if the player has no score for that game.
    public query func getMetascore(
        game    : MPublic.GamePrincipal,
        player  : MPlayer.Player,
    ) : async Nat {
        state.getMetascore(game, player);
    };

    // Returns the cumulative metascore of a player.
    public query func getOverallMetascore(
        player  : MPlayer.Player,
    ) : async Nat {
        state.getOverallMetascore(player);
    };

    // Returns the list of registered games.
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
