import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Roles "mo:auth/Roles";

import Users "Users";

import MAccount "../src/Account";
import MPublic "../src/Metascore";
import MPlayer "../src/Player";

shared({caller = owner}) actor class Accounts() : async MAccount.PublicInterface = {
    private stable var nextAccountId = 0;
    private stable var stableAccounts : [Users.StableAccount] = [];
    private let users = Users.Users(nextAccountId, stableAccounts);

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
    
    public query func getAccount(
        accountId : MAccount.AccountId,
    ) : async Result.Result<MAccount.Account, ()> {
        switch (users.accounts.get(accountId)) {
            case (null) { #err(); };
            case (? a)  { #ok(a); };
        };
    };

    public query func getAccountCount() : async Nat {
        users.size();
    };

    public query func getAccountDetails(
        accountId : MAccount.AccountId,
    ) : async Result.Result<MAccount.AccountDetails, ()> {
        switch (users.accounts.get(accountId)) {
            case (null) { #err(); };
            case (? a)  { #ok(MAccount.getDetails(a)); };
        };
    };

    public query func getAccountDetailsFromScores(
        scores : [MAccount.Score],
    ) : async [MAccount.DetailedScore] {
        var accounts : [MAccount.DetailedScore] = [];
        for ((accountId, score) in scores.vals()) {
            switch (users.accounts.get(accountId)) {
                case (null) {
                    accounts := Array.append<MAccount.DetailedScore>(
                        accounts,
                        [(
                            {
                                alias      = null;
                                avatar     = null;
                                flavorText = null;
                                id         = accountId;
                            }, 
                            score,
                        )],
                    );
                };
                case (? details) {
                    accounts := Array.append<MAccount.DetailedScore>(
                        accounts, 
                        [(details, score)],
                    );
                };
            };
        };
        accounts;
    };

    public shared func getAccountsFromScores(
        scores : [MPublic.Score],
    ) : async [MAccount.Score] {
        let accounts = Array.init<(MAccount.AccountId, Nat)>(scores.size(), (0 , 0));
        for (i in scores.keys()) {
            let (playerId, score) = scores[i];
            switch (users.getAccountByPrincipal(MPlayer.unpack(playerId))) {
                case (null) {
                    let (account, _) = users.ensureAccount(playerId);
                    accounts[i] := (account.id, score);
                };
                case (? account) {
                    accounts[i] := (account.id, score);
                };
            };
        };
        Array.freeze(accounts);
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

    // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
    // | Admin zone. 🚫                                                        |
    // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

    private stable var stableAdmins : [(Principal, [Roles.Role])] = [(owner, [Roles.ALL])];
    private let admins = Roles.Users(stableAdmins);

    private func _isAdmin(caller : Principal) : Bool {
        admins.hasRole(caller, Roles.ALL);
    };

    // Load accounts from a backup.
    // @auth: admin
    public shared({caller}) func loadAccounts(
        backup : [MAccount.Account],
    ) : async () {
        assert(_isAdmin(caller));
        for (account in backup.vals()) {
            users.putAccount(account);
        };
        if (users.size() > users.nextAccountId) {
            users.nextAccountId := users.size();
        };
    };

    // Returns a range of accounts.
    // @auth: admin
    public shared({caller}) func getAccountsById(
        from : Nat,
        to   : Nat,
    ) : async [MAccount.Account] {
        assert(_isAdmin(caller));
        users.getAccountsById(from, to);
    };

    // Get an account by wallet principal
    // @auth: admin
    public shared({caller}) func getAccountByPrincipal(p : Principal) : async ?MAccount.Account {
        assert(_isAdmin(caller));
        users.getAccountByPrincipal(p);
    };

    // Adds a new principal as an admin.
    // @auth: admin
    public shared({caller}) func addAdmin(p : Principal) : async () {
        assert(_isAdmin(caller));
        admins.addUserWithRoles(caller, p, [Roles.ALL]);
    };

    // Removes the given principal from the list of admins.
    // @auth: admin
    public shared({caller}) func removeAdmin(p : Principal) : async () {
        assert(_isAdmin(caller));
        admins.removeUser(caller, p);
    };

    // Check whether the given principal is an admin.
    // @auth: admin
    public query({caller}) func isAdmin(p : Principal) : async Bool {
        assert(_isAdmin(caller));
        admins.hasRole(p, Roles.ALL);
    };

    // Manually set the next account id in case of emergency
    // @auth: admin
    public shared({caller}) func setNextId(id : Nat) : async () {
        assert(_isAdmin(caller));
        users.nextAccountId := id;
    };

    // Check the next account id
    // @auth: admin
    public query({caller}) func getNextId() : async Nat {
        assert(_isAdmin(caller));
        users.nextAccountId;
    };

    // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
    // | Pre/Post Upgrade                                                      |
    // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

    system func preupgrade() {
        nextAccountId  := users.nextAccountId;
        stableAccounts := Users.toStable(users);
        stableAdmins   := Roles.toStable(owner, admins);
    };

    system func postupgrade() {
        stableAccounts := [];
        stableAdmins   := [];
    };
};