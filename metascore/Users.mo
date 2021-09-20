import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import MAccount "../src/Account";
import MPlayer "../src/Player";

module {
    public type StableAccount = (
        MAccount.AccountId,
        MAccount.Account,
    );

    public func toStable(users : Users) : [StableAccount] {
        Iter.toArray(users.accounts.entries());
    };

    public class Users(
        accountId : MAccount.AccountId,
        users     : [StableAccount],
    ) {
        // The account identifier of the next account.
        public var nextAccountId = accountId;

        public let accounts = HashMap.HashMap<
            MAccount.AccountId,
            MAccount.Account,
        >(users.size(), Nat.equal, Hash.hash);

        public let principals = HashMap.HashMap<
            Principal, 
            MAccount.AccountId,
        >(users.size() * 2, Principal.equal, Principal.hash);

        public let links = HashMap.HashMap<
            Principal,
            Principal,
        >(0, Principal.equal, Principal.hash);

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Load stable state, given on creation. ~ constructor               |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        for ((accountId, account) in users.vals()) {
            // I know, this is the same as `putAccount`, but we can not use it
            // before it is defined. This order of code makes more sense, so I
            // will keep it this way.
            accounts.put(accountId, account);
            switch (account.stoicAddress) {
                case (null) {};
                case (? p)  { principals.put(p, accountId); };
            };
            switch (account.plugAddress) {
                case (null) {};
                case (? p)  { principals.put(p, accountId); };
            };
        };

        // ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
        // | Internal Interface, which contains a lot of getters...            |
        // ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

        // Returns the next available account identifier, and increases the
        // counter in the background.
        public func getNextAccountId() : MAccount.AccountId {
            let accountId = nextAccountId;
            nextAccountId += 1;
            accountId;
        };

        // Returns the account linked to the given principal.
        public func getAccountByPrincipal(principal : Principal) : ?MAccount.Account {
            switch (principals.get(principal)) {
                case (null) { null; };
                case (? accountId)  {
                    return accounts.get(accountId);
                };
            };
        };

        // Stores the given account.
        public func putAccount(account : MAccount.Account) {
            accounts.put(account.id, account);
            switch (account.stoicAddress) {
                case (null) {};
                case (? p)  { principals.put(p, account.id); };
            };
            switch (account.plugAddress) {
                case (null) {};
                case (? p)  { principals.put(p, account.id); };
            };
        };

        public func createAccount(player : MPlayer.Player) : MAccount.Account {
            let account = {
                alias         = null;
                avatar        = null;
                flavorText    = null;
                id            = getNextAccountId();
                plugAddress   = switch (player) {
                    case (#plug(p))  { ?p;   };
                    case (_)         { null; };
                };
                primaryWallet = player;
                stoicAddress  = switch (player) {
                    case (#stoic(p)) { ?p;   };
                    case (_)         { null; }; 
                };
            };
            putAccount(account);
            account;
        };

        // Gets the account, or creates one if not found, returns whether the account was created.
        public func ensureAccount(player : MPlayer.Player) : (MAccount.Account, Bool) {
            let principal = MPlayer.unpack(player);
            switch (principals.get(principal)) {
                case (null) {
                    (createAccount(player), true);
                };
                case (? accountId) {
                    switch (accounts.get(accountId)) {
                        case (? account) {
                            (account, false);
                        };
                        case (null) {
                            (createAccount(player), true);
                        };
                    };
                };
            };
        };

        public func canBeLinked(
            player    : MPlayer.Player,
            newPlayer : MPlayer.Player,
        ) : Result.Result<MAccount.Account, Text> {
            // Check whether the other player is not already linked.
            switch (getAccountByPrincipal(MPlayer.unpack(newPlayer))) {
                case (? _)  { return #err("other principal already linked"); };
                case (null) {};
            };

            // Check whether the player has an account and that the other wallet is empty.
            // Also checks whether the two players have different wallet types.
            switch (getAccountByPrincipal(MPlayer.unpack(player))) {
                case (null) { return #err("account not found"); };
                case (? account) {
                    switch (player) {
                        case (#plug(_)) {
                            if (account.stoicAddress != null) {
                                return #err("principal already linked");
                            };
                            switch (newPlayer) {
                                case (#plug(_)) {
                                    return #err("principal has the same wallet type: Plug");
                                };
                                case (_) {};
                            };
                        };
                        case (#stoic(_)) {
                            if (account.plugAddress != null) {
                                return #err("principal already linked");
                            };
                            switch (newPlayer) {
                                case (#stoic(_)) {
                                    return #err("principal has the same wallet type: Stoic");
                                };
                                case (_) {};
                            };
                        };
                    };
                    #ok(account);
                };
            };
        };

        // Links the new player to the given account. Will overwrite any data, 
        // if necessary, make sure canBeLinked() is called beforehand.
        public func link(
            account   : MAccount.Account,
            newPlayer : MPlayer.Player,
        ) : MAccount.Account {
            let newAccount : MAccount.Account = switch (newPlayer) {
                case (#plug(p)) {
                    {
                        alias         = account.alias;
                        avatar        = account.avatar;
                        flavorText    = account.flavorText;
                        id            = account.id;
                        plugAddress   = ?p;
                        primaryWallet = account.primaryWallet;
                        stoicAddress  = account.stoicAddress;
                    };
                };
                case (#stoic(p)) {
                    {
                        alias         = account.alias;
                        avatar        = account.avatar;
                        flavorText    = account.flavorText;
                        id            = account.id;
                        plugAddress   = account.plugAddress;
                        primaryWallet = account.primaryWallet;
                        stoicAddress  = ?p;
                    };
                };
            };
            putAccount(newAccount);
            newAccount;
        };
    };
};
