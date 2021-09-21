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
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";

import Interface "Interface";
import State "State";
import Users "Users";

import MAccount "../src/Account";
import MPublic "../src/Metascore";
import MPlayer "../src/Player";

shared ({caller = owner}) actor class Metascore() : async Interface.FullInterface {
    // Time since last cron call.
    private stable var lastCron : Int = Time.now();

    // Map of registered game canisters.
    private stable var games : [State.StableGame] = [];
    private let state = State.State(games);

    private stable var nextAccountId = 0;
    private stable var accounts : [Users.StableAccount] = [];
    private let users = Users.Users(nextAccountId, accounts);

    system func preupgrade() {
        games    := State.toStable(state);

        nextAccountId := users.nextAccountId;
        accounts := Users.toStable(users);
    };

    system func postupgrade() {
        games         := [];
  
        nextAccountId := 0;
        accounts      := [];
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
        mapScores(await game.metascoreScores());
    };

    private func mapScores(scores : [MPublic.Score]) : [MAccount.Score] {
        Array.map<MPublic.Score, MAccount.Score>(
            scores,
            func ((player, score) : MPublic.Score) : MAccount.Score {
                let (account, _) = users.ensureAccount(player);
                (account.id, score);
            },
        );
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
                state.updateScores(caller, mapScores(scores));
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
                state.updateScore(gameId, score);
            };
        };
    };

    // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
    // | User Account Management                                               |
    // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

    public query func getAccount(id : MAccount.AccountId) : async Result.Result<MAccount.Account, ()> {
        switch (users.accounts.get(id)) {
            case (null) { #err(); };
            case (? a)  { #ok(a); };
        };
    };

    public shared({caller}) func updateAccount(
        req : MAccount.UpdateRequest,
    ) : async MAccount.UpdateResponse {
        switch (users.getAccountByPrincipal(caller)) {
            case (null)      {
                #err("account not found: " # Principal.toText(caller));
            };
            case (? account) {
                let updatedAccount : MAccount.Account = {
                    alias         = req.alias;
                    avatar        = req.avatar;
                    flavorText    = req.flavorText;
                    id            = account.id;
                    plugAddress   = account.plugAddress;
                    primaryWallet = switch (req.primaryWallet) {
                        case (null) { account.primaryWallet; };
                        case (? newWallet) { newWallet; };
                    };
                    stoicAddress  = account.stoicAddress;
                };
                users.putAccount(updatedAccount);
                #ok(updatedAccount);
            };
        };
    };

    public shared({caller}) func authenticateAccount(
        req : MAccount.AuthenticationRequest,
    ) : async MAccount.AuthenticationResponse {
        switch (req) {
            case (#authenticate(playerId)) {
                let principal = MPlayer.unpack(playerId);
                if (not Principal.equal(principal, caller)) return #forbidden;
                let (account, new) = users.ensureAccount(playerId);
                #ok({
                    message = switch (new) {
                        case (true)  "created new account";
                        case (false) "retrieved account";
                    };
                    account;
                });
            };
            case (#link(playerA, playerB)) {
                let principalA = MPlayer.unpack(playerA);
                let principalB = MPlayer.unpack(playerB);
                if (Principal.equal(principalA, principalB)) return #err({
                    message = "principals can not be the same";
                });

                let (player, newPlayer) = if (Principal.equal(caller, principalA)) {
                    (playerA, playerB);
                } else {
                    if (Principal.equal(caller, principalB)) {
                        (playerB, playerA);
                    } else {
                        // Caller is not authorized to link two `other` principals,
                        // one of the two need to be the same as the caller.
                        return #forbidden;
                    };
                };

                // Check whether the two players can be linked.
                let account = switch (users.canBeLinked(player, newPlayer)) {
                    case (#err(msg))    { return #err({ message=msg; })};
                    case (#ok(account)) { account; };
                };


                let newPrincipal = MPlayer.unpack(newPlayer);
                switch (users.getLink(caller)) {
                    case (null) {
                        // Initial request, create link.
                        users.links.push((newPrincipal, caller));
                        #pendingConfirmation({
                            message = "awaiting confirmation from: " # Principal.toText(newPrincipal);
                        });
                    };
                    case (? link) {
                        if (not Principal.equal(link, newPrincipal)) {
                            // Pending link was not the new player.
                            users.deleteLink(caller); // Do we still need this?
                            users.links.push((newPrincipal, caller));
                            return #pendingConfirmation({
                                message = "awaiting confirmation from: " # Principal.toText(newPrincipal);
                            });
                        };

                        // We already get an (new) account from `canBeLinked`.
                        users.deleteLink(caller);
                        users.deleteLink(newPrincipal);
                        let newAccount = users.link(account, newPlayer);
                        #ok({
                            message = "linked principals to account";
                            account = newAccount;
                        });
                    };
                };
            };
        };
    };

    // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
    // | Public Interface                                                      |
    // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

    // Return the top n players. Can return less if the number of players is
    // less than n.
    public query func getTop(n : Nat) : async [MAccount.Score] {
        var top : [MAccount.Score] = [];
        for ((p, (s, _)) in state.globalLeaderboard.entries()) {
            top := Array.append<MAccount.Score>(top, [(p, s)]);
        };
        top;
    };

    // Returns the percentile of a player in a specific game.
    // Null gets return if the player has no score for that game.
    public query func getPercentile(
        game    : MPublic.GamePrincipal,
        account : MAccount.AccountId,
    ) : async ?Float {
        state.getPercentile(game, account);
    };

    // Returns the ranking of a player in a specific game (1-index based).
    // Null gets return if the player has no score for that game.
    public query func getRanking(
        game    : MPublic.GamePrincipal,
        account : MAccount.AccountId,
    ) : async ?Nat {
        state.getRanking(game, account);
    };

    // Returns the metascore of a player in a specific game ([0-1T] points).
    // 0 gets return if the player has no score for that game.
    public query func getMetascore(
        game   : MPublic.GamePrincipal,
        account : MAccount.AccountId,
    ) : async Nat {
        state.getMetascore(game, account);
    };

    // Returns the cumulative metascore of a player.
    public query func getOverallMetascore(
        player  : MAccount.AccountId,
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
    ) : async [MAccount.Score] {
        state.getGameScores(game, count, offset);
    };

    // Returns a list of overall metascores.
    public query func getMetascores(
        count   : ?Nat,
        offset  : ?Nat,
    ) : async [MAccount.Score] {
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
                        text #= "<dt>" # Nat.toText(p) # "</dt>";
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
