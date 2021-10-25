import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Queue "mo:queue/Queue";
import EQueue "mo:queue/EvictingQueue";
import Result "mo:base/Result";

import MAccount "../src/Account";
import MPlayer "../src/Player";

import Debug "mo:base/Debug";

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

        public let links = EQueue.EvictingQueue<(Principal, Principal)>(100);

        public func size() : Nat {
            accounts.size();
        };

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

        public func getAccountsById(from : Nat, to : Nat) : [MAccount.Account] {
            var as : [MAccount.Account] = [];
            for (i in Iter.range(from, to - 1)) {
                switch (accounts.get(i)) {
                    case (null)      {};
                    case (? account) {
                        as := Array.append<MAccount.Account>(as, [account]);
                    };
                };
            };
            as;
        };

        // Stores the given account.
        public func putAccount(account : MAccount.Account) {
            accounts.put(account.id, account);
            switch (account.plugAddress) {
                case (null) {};
                case (? p)  { principals.put(p, account.id); };
            };
            switch (account.stoicAddress) {
                case (null) {};
                case (? p)  { principals.put(p, account.id); };
            };
        };

        // Deletes the given account.
        public func deleteAccount(account : MAccount.Account) {
            accounts.delete(account.id);
            switch (account.plugAddress) {
                case (null) {};
                case (? p)  { principals.delete(p); };
            };
            switch (account.stoicAddress) {
                case (null) {};
                case (? p)  { principals.delete(p); };
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
            // Check whether the player has an account and that the other wallet is empty.
            // Also checks whether the two players have different wallet types.
            switch (ensureAccount(player)) {
                case (account, _) {
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
            var alias : ?Text = null;
            var avatar : ?Text = null;
            var flavorText : ?Text = null;
            switch (getAccountByPrincipal(MPlayer.unpack(newPlayer))) {
                // Merge account fields via defined > undefined, stoic > plug
                case (null) {
                    alias := account.alias;
                    avatar := account.avatar;
                    flavorText := account.flavorText;
                };
                case (? oldAccount) {
                    alias := switch (oldAccount.alias) {
                        case null account.alias;
                        case x x;
                    };
                    avatar := switch (oldAccount.avatar) {
                        case null account.avatar;
                        case x x;
                    };
                    flavorText := switch (oldAccount.flavorText) {
                        case null account.flavorText;
                        case x x;
                    };
                    // Delete other account of player, if exists.
                    deleteAccount(oldAccount)
                };
            };
            // Add player to account.
            let newAccount : MAccount.Account = switch (newPlayer) {
                case (#plug(p)) {
                    {
                        alias         = alias;
                        avatar        = avatar;
                        flavorText    = flavorText;
                        id            = account.id;
                        plugAddress   = ?p;
                        primaryWallet = account.primaryWallet;
                        stoicAddress  = account.stoicAddress;
                    };
                };
                case (#stoic(p)) {
                    {
                        alias         = alias;
                        avatar        = avatar;
                        flavorText    = flavorText;
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

        public func getLink(p : Principal) : ?Principal {
            for ((from, to) in links.vals()) {
                if (Principal.equal(from, p)) return ?to;
            };
            null;
        };

        public func deleteLink(p : Principal) {
            links.custom(func ((i, o) : Queue.Queue<(Principal, Principal)>) : Queue.Queue<(Principal, Principal)> {
                (deleteLink_(i, p), deleteLink_(o, p));
            });
        };

        private func deleteLink_(l : List.List<(Principal, Principal)>, p : Principal) : List.List<(Principal, Principal)> {
            List.filter(l, func((a, _) : (Principal, Principal)) : Bool {
                // Only keep principals that are not equal to p.
                not Principal.equal(a, p);
            });
        };
    };
};
