import Array "mo:base/Array";
import AssetStorage "mo:asset-storage/AssetStorage";
import Blob "mo:base/Blob";
import Float "mo:base/Float";
import Error "mo:base/Error";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import O "mo:sorted/Order";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import SMap "mo:sorted/Map";
import Time "mo:base/Time";
import Text "mo:base/Text";

import Interface "Interface";
import State "State";

import MAccount "../src/Account";
import MPublic "../src/Metascore";
import MPlayer "../src/Player";

shared ({caller = owner}) actor class Metascore() : async Interface.FullInterface {
    // Time since last cron call.
    private stable var lastCron : Int = Time.now();

    // The state: games.
    private stable var games : [State.StableGame] = [];
    private let state = State.State(games);

    // TODO: use "ic:{canister}"?
    private stable var users : ?Interface.AccountsInterface = null;

    public shared({caller}) func setAccountsCanister(c : Principal) : async Principal {
        assert(_isAdmin(caller));
        let can : Interface.AccountsInterface = actor(Principal.toText(c));
        users := ?can;
        c;
    };

    system func preupgrade() {
        games := State.toStable(state);
    };

    system func postupgrade() {
        games := [];
    };

    // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
    // | Admin zone. 🚫                                                        |
    // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

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

    // Load games from a backup.
    // @auth: admin
    public shared({caller}) func loadGames(backup : [(MPublic.GamePrincipal, MPublic.Metadata)]) : async () {
        assert(_isAdmin(caller));
        for ((gameId, metadata) in Iter.fromArray(backup)) {
            state.games.put(gameId, metadata);
        }
    };

    // Load game scores from a backup.
    // @auth: admin
    public shared({caller}) func loadGameScores(game : MPublic.GamePrincipal, scores : [MPublic.Score]) : async () {
        assert(_isAdmin(caller));
        let accountScores = switch (state.gameLeaderboards.get(game)) {
            case (null) {
                SMap.SortedValueMap<MAccount.AccountId, MAccount.Score>(
                    0, Nat.equal, Hash.hash,
                    O.Descending(State.compareAccountScores),
                );
            };
            case (? ps) { ps; };
        };
        let mappedScores = await mapScoresToAccounts(scores);
        for ((a, s) in mappedScores.vals()) {
            switch (accountScores.get(a)) {
                case (? (_, os)) {
                    // Score is already the same, no need to update anything.
                    if (s > os) accountScores.put(a, (a, s));
                };
                case null accountScores.put(a, (a, s));
            };
        };
        state.gameLeaderboards.put((game, accountScores));
    };

    // Load game scores from a backup.
    // @auth: admin
    public shared({caller}) func loadAccountScores(game : MPublic.GamePrincipal, scores : [MAccount.Score]) : async () {
        assert(_isAdmin(caller));
        let accountScores = switch (state.gameLeaderboards.get(game)) {
            case (null) {
                SMap.SortedValueMap<MAccount.AccountId, MAccount.Score>(
                    0, Nat.equal, Hash.hash,
                    O.Descending(State.compareAccountScores),
                );
            };
            case (? ps) { ps; };
        };
        for ((a, s) in Iter.fromArray(scores)) {
            switch (accountScores.get(a)) {
                case (? (_, os)) {
                    if (s > os) accountScores.put(a, (a, s));
                };
                case null accountScores.put(a, (a, s));
            };
        };
        state.gameLeaderboards.put((game, accountScores));
    };

    // Load metascores from a backup.
    // @auth: admin
    // public shared ({ caller }) func loadMetascores(scores : [MAccount.Score]) : async () {
    //     assert(_isAdmin(caller));
    //     let ss = HashMap.HashMap<MPublic.GamePrincipal, Nat>(
    //         1, Principal.equal, Principal.hash,
    //     );
    //     for ((accountId, score) in Iter.fromArray(scores)) {
    //         state.globalLeaderboard.put(accountId, (
    //             score,
    //             ss,
    //         ));
    //     };
    // };

    // Calculate overall scores for a game.
    // @auth: admin
    // public shared ({ caller }) func calculateMetascores(game : MPublic.GamePrincipal, batch : Nat) : async () {
    //     assert(_isAdmin(caller));
    //     state.recalculate(game, batch);
    // };

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
        state.updateScores(caller, scores);
        state.games.put(caller, metadata);
    };

    private func getScores(gameId : MPublic.GamePrincipal) : async [MAccount.Score] {
        let game : MPublic.GameInterface = actor(Principal.toText(gameId));
        await mapScoresToAccounts(await game.metascoreScores());
    };

    private func mapScoresToAccounts(scores : [MPublic.Score]) : async [MAccount.Score] {
        let usersCan = switch (users) {
            case (null) throw Error.reject("no accounts canister found");
            case (? can) { can; };
        };
        await usersCan.getAccountsFromScores(scores);
    };

    // Allows owners and games to unregister games/themselves.
    public shared({caller}) func unregister(
        id : MPublic.GamePrincipal,
    ) : async () {
        assert(_isAdmin(caller) or id == caller);
        state.removeGame(id);
    };

    // Allows games to send score updates. These updates don't need to be the
    // full leaderboard, but can only contain new/updated scores. The whole
    // leaderboard will occasionally get queried on the metascoreScores endpoint.
    public shared({caller}) func scoreUpdate(
        scores : [MPublic.Score],
    ) : async () {
        switch (state.games.get(caller)) {
            case (null) {
                // Means that the caller was not the game canister itself.
                assert(false);
            };
            case (? _)  {
                let mappedScores = await mapScoresToAccounts(scores);
                state.updateScores(caller, mappedScores);
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

    // Pull scores for one game.
    public shared ({caller}) func queryGameScores(gameId : MPublic.GamePrincipal) : async () {
        assert(_isAdmin(caller));
        let scores = await getScores(gameId);
        state.updateScores(gameId, scores);
    };

    // Gets all scores from every game.
    // Currently only used by the cron.
    private func queryAllScores() : async () {
        for ((gameId, _) in state.games.entries()) {
            let scores = await getScores(gameId);
            state.updateScores(gameId, scores);
        };
    };

    // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
    // | Public Interface                                                      |
    // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

    // Return the top n players. Can return less if the number of players is
    // less than n.
    public query func getTop(gameId : MPublic.GamePrincipal, n : Nat) : async [MAccount.Score] {
        state.getTop(gameId, n);
    };

    // Returns the percentile of a player in a specific game.
    // Null gets return if the player has no score for that game.
    public query func getPercentile(
        gameId    : MPublic.GamePrincipal,
        accountId : MAccount.AccountId,
    ) : async ?Float {
        state.getPercentile(gameId, accountId);
    };

    // Returns the ranking of a player in a specific game (1-index based).
    // Null gets return if the player has no score for that game.
    public query func getRanking(
        game    : MPublic.GamePrincipal,
        account : MAccount.AccountId,
    ) : async ?Nat {
        state.getRanking(game, account);
    };

    // Returns the list of registered games.
    public query func getGames() : async [(MPublic.GamePrincipal, MPublic.Metadata)] {
        state.getGames();
    };

    // Returns a list of detailed scores for a game.
    public func getDetailedGameScores(
        game    : MPublic.GamePrincipal,
        count   : ?Nat,
        offset  : ?Nat,
    ) : async [MAccount.DetailedScore] {
        let usersCan = switch (users) {
            case (null) throw Error.reject("no accounts canister found");
            case (? can) { can; };
        };
        let scores = state.getGameScores(game, count, offset);
        await usersCan.getAccountDetailsFromScores(scores);
    };

    // Returns a list of scores for a game.
    public query func getGameScores(
        game    : MPublic.GamePrincipal,
        count   : ?Nat,
        offset  : ?Nat,
    ) : async [MAccount.Score] {
        state.getGameScores(game, count, offset);
    };

    // Returns total number of players.
    public func getPlayerCount() : async Nat {
        let usersCan = switch (users) {
            case (null) throw Error.reject("no accounts canister found");
            case (? can) { can; };
        };
        await usersCan.getAccountCount();
    };
    
    // Returns total number of scores.
    public query func getScoreCount() : async Nat {
        state.getScoreCount();
    };

    // Drain recent score update requests.
    public query func drainScoreUpdateLog() : async [(MPublic.GamePrincipal, MAccount.Score)] {
        Iter.toArray(state.scoreUpdateLog.vals());
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
                switch (state.gameLeaderboards.get(gameId)) {
                    case (null) {};
                    case (? accountScores) {
                        switch (accountScores.getIndex(i)) {
                            case (null) {};
                            case (? (_, (p, s))) {
                                text #= "<dt>" # Nat.toText(p) # "</dt>";
                                text #= "<dd>" # Nat.toText(s) # "</dd>";
                            };
                        };
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
