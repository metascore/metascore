import Array "mo:base/Array";
import AssetStorage "mo:http/AssetStorage";
import Blob "mo:base/Blob";
import Float "mo:base/Float";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";

import Interface "Interface";
import State "State";

import MPublic "../src/Metascore";
import MPlayer "../src/Player";

shared ({caller = owner}) actor class Metascore() : async Interface.FullInterface {
    // Time since last cron call.
    private stable var lastCron : Int = Time.now();

    // Map of registered game canisters.
    private stable var games : [State.StableGame] = [];
    private let state = State.State(games);

    system func preupgrade() {
        games := State.toStable(state);
    };

    system func postupgrade() {
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
        for (score in scores.vals()) {
            State.updateScore(state, caller, score);
        };
    };

    private func getScores(gameId : MPublic.GamePrincipal) : async [MPublic.Score] {
        let game : MPublic.GameInterface = actor(Principal.toText(gameId));
        await game.metascoreScores();
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
            case (? _)  {
                for (score in scores.vals()) {
                    State.updateScore(state, caller, score);
                };
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
        for ((gameId, _) in state.games.entries()) {
            let scores = await getScores(gameId);
            for (score in scores.vals()) {
                State.updateScore(state, gameId, score);
            };
        };
    };

    // Return the top n players. Can return less if the number of players is
    // less than n.
    public query func getTop(n : Nat) : async [MPublic.Score] {
        var top : [MPublic.Score] = [];
        for ((p, (s, _)) in state.globalLeaderboard.entries()) {
            top := Array.append<MPublic.Score>(top, [(p, s)]);
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
    public query func getGames() : async [(MPublic.GamePrincipal, MPublic.Metadata)] {
        state.getGames();
    };

    // Returns a list of scores for a game.
    public query func getGameScores(
        game    : MPublic.GamePrincipal,
        count   : ?Nat,
        offset  : ?Nat,
    ) : async [MPublic.Score] {
        state.getGameScores(game, count, offset);
    };

    // Returns a list of overall metascores.
    public query func getMetascores(
        count   : ?Nat,
        offset  : ?Nat,
    ) : async [MPublic.Score] {
        state.getMetascores(count, offset);
    };

    // Returns the overall metascore for the given percentile.
    public query func getPercentileMetascore(percentile : Float) : async Nat {
        state.getPercentileMetascore(percentile);
    };

    // Returns total number of players.
    public query func getPlayerCount() : async Nat {
        state.getPlayerCount();
    };
    
    // Returns total number of scores.
    public query func getScoreCount() : async Nat {
        state.getScoreCount();
    };

    public query func http_request(
        r : AssetStorage.HttpRequest,
    ) : async AssetStorage.HttpResponse {
        var text = "<html><title>Metascore</title><body>";
        text #= "<h1>Hello world!</h1>";
        for ((gameId, metadata) in state.games.entries()) {
            text #= "<div>";
            text #= "<h2>" # metadata.name # " (" # Principal.toText(gameId) # ")</h2>";
            text #= "<h3>Top 3</h3>";
            text #= "<dl>";
            for (i in Iter.range(0, 2)) {
                switch (state.globalLeaderboard.getIndex(i)) {
                    case (null) {};
                    case (? (p, (s, _)))  {
                        text #= "<dt>" # MPlayer.toText(p) # "</dt>";
                        text #= "<dd>" # Nat.toText(s) # "</dd>";
                    };
                };
            };
            text #= "</dl>";
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
