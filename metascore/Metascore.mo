import Array "mo:base/Array";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import AR "AccountRecord";
import GR "GameRecord";
import MPlayer "../src/Player";
import MPublic "../src/Metascore";
import MStats "../src/Stats";

// This module is for internal use and should never be imported somewhere other
// than 'main.mo'.
module {
    // Internal class to keep track of data within the Metascore canister.
    // Used to keep the 'main.mo' file at a minimum.
    public class Metascore(
        gamesState : [GR.GameRecordStable],
        accountsState : AR.AccountsStateStable,
    ) : MStats.PublicInterface {

        // Games state.
        public let games = GR.fromStable(gamesState);
        // Accounts state.
        public let {
            accounts            : AR.Accounts;
            principalAccountMap : AR.PrincipalAccountMap;
            linkSignatures      : AR.LinkSignatures;
        } = AR.fromStable(accountsState);
        private var nextAccountId = AR.nextId(accountsState);

        public func getPercentile(
            game    : MPublic.GamePrincipal,
            player  : MPlayer.Player,
        ) : ?Float {
            switch (games.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.players.getIndex(player)) {
                        case (null) { null; };
                        case (? i)  {
                            let n = Float.fromInt(gc.players.size());
                            ?((n - Float.fromInt(i)) / n);
                        };
                    };
                };
            };
        };

        public func getRanking(
            game    : MPublic.GamePrincipal,
            player  : MPlayer.Player,
        ) : ?Nat {
            switch (games.get(game)) {
                case (null) { null; };
                case (? gc) {
                    switch (gc.players.getIndex(player)) {
                        case (null) { null;   };
                        case (? r)  { ?(r+1); };
                    };
                };
            };
        };

        public func getMetascore (
            game    : MPublic.GamePrincipal,
            player  : MPlayer.Player,
        ) : Nat {
            // To drive people to try all games, 1/2 of points awarded for participation.
            var score : Float = 0.5;
            switch (getPercentile(game, player)) {
                case (null) { return 0; };
                case (?percentile) {
                    // Players get up to 1/4 of available points based on performance.
                    score += 0.25 * percentile;
                    switch (getRanking(game, player)) {
                        case (null) { return 0; };
                        case (?ranking) {
                            // Players get up to 1/4 of available points based on top 3
                            score += switch (ranking) {
                                case (1) { 0.25;   };
                                case (2) { 0.125;  }; // 0.25 / 2
                                case (3) { 0.0625; }; // 0.25 / 4
                                case (_) { 0;      };
                            };
                        };
                    };
                };
            };
            Int.abs(Float.toInt(score * 1_000_000_000_000));
        };

        public func getOverallMetascore(
            player  : MPlayer.Player,
        ) : Nat {
            var score : Nat = 0;
            for ((gID, _) in games.entries()) {
                score += getMetascore(gID, player);
            };
            score;
        };

        public func getGames() : [(MPublic.GamePrincipal, MPublic.Metadata)] {
            var md : [(MPublic.GamePrincipal, MPublic.Metadata)] = [];
            for ((p, g) in games.entries()) {
                md := Array.append(md, [(p, g.metadata)]);
            };
            md;
        };

        public func getGameScores (
            game : MPublic.GamePrincipal,
            count : ?Nat,
            offset : ?Nat,
        ) : [MPublic.Score] {
            let c : Nat = Option.get<Nat>(count, 100);
            let o : Nat = Option.get<Nat>(offset, 0);
            var result : [MPublic.Score] = [];
            switch (games.get(game)) {
                case (null) { []; };
                case (? gc) {
                    label l for (i in Iter.range(o, o + c)) {
                        switch (gc.players.getValue(i)) {
                            case null break l;
                            case (?p) result := Array.append(result, [(p.player, p.score)]);
                        };
                    };
                    result;
                };
            };
        };

        public func getMetascores (
            count : ?Nat,
            offset : ?Nat,
        ) : [Nat] {
            // TODO: We need a Metascore data structure, then make this.
            [];
        };

        public func getPercentileMetascore (
            percentile : Float,
        ) : Nat {
            // TODO: We need a Metascore data structure, then make this.
            // Should return the metascore at the given percentile.
            1;
        };

        public func getPlayerCount() : Nat {
            // TODO: Develop a simple counter for this;
            1;
        };

        public func getScoreCount() : Nat {
            // TODO: Develop a simple counter for this;
            1;
        };

        public func getAccount(id : Nat) : Result.Result<AR.AccountRecord, ()> {
            switch (accounts.get(id)) {
                case (?account) { #ok(account) };
                case null #err(());
            };
        };

        // TODO: updateAccount

        public func authenticateAccount(
            request : AR.AuthRequest,
            caller  : Principal
        ) : async AR.AuthResponse {
            switch (request) {

                // Get or create account with caller principal.
                case (#authenticate(request)) {
                    let principal = unpackPrincipal(request);
                    if (not Principal.equal(principal, caller)) return #err({
                        message = "Forbidden";
                    });
                    let (account, created) = getOrCreateAccount(request);
                    return #ok({
                        message = switch (created) {
                            case true "Created new account.";
                            case false "Retrieved existing account.";
                        };
                        account = account;
                    });
                };

                // Sign intent to link principals in one account.
                case (#link(request)) {
                    let sisterWallet = request;
                    let sisterPrincipal = unpackPrincipal(request);
                    let callerPrincipal = caller;
                    let { callerWallet; stoicAddress; plugAddress; } = switch (sisterWallet) {
                        // Assume the caller made a sane request i.e. two different wallets.
                        // NOTE: Opens the way for developer mistakes on the frontend. 
                        case (#stoic(_)) ({
                            callerWallet = #plug(caller);
                            stoicAddress = caller;
                            plugAddress = sisterPrincipal;
                        });
                        case (#plug(_)) ({
                            callerWallet = #stoic(caller);
                            stoicAddress = sisterPrincipal;
                            plugAddress = caller;
                        });
                    };
                    switch (linkSignatures.get(caller)) {
                        case null {
                            // Sister principal hasn't signed yet, register intent and return.
                            linkSignatures.put(sisterPrincipal, callerPrincipal);
                            return #pendingConfirmation({
                                message = "Awaiting confirmation from second principal.";
                            });
                        };
                        case (?pending) {
                            switch (Principal.equal(pending, sisterPrincipal)) {
                                case false {
                                    // Pending principal wasn't sister, register intent and return.
                                    linkSignatures.put(sisterPrincipal, callerPrincipal);
                                    return #pendingConfirmation({
                                        message = "Awaiting confirmation from second principal.";
                                    });
                                };
                                case true {
                                    // Both principals signed, link them under one account.
                                    switch (
                                        principalAccountMap.get(callerPrincipal),
                                        principalAccountMap.get(sisterPrincipal),
                                    ) {
                                        case (null, null) {
                                            // Neither principal had an account. Create one.
                                            // I don't think this will ever happen, but...
                                            let account = createAccount(request);
                                            // Disolve pending signatures
                                            linkSignatures.delete(sisterPrincipal);
                                            linkSignatures.delete(callerPrincipal);
                                            return #ok({
                                                message = "Principals linked in new account.";
                                                account;
                                            });
                                        };
                                        case (?callerAccountId, null) {
                                            // Account exists for first principal, consolidate.
                                            switch (accounts.get(callerAccountId)) {
                                                case null return #err({
                                                    message = "Internal error. Please contact the developer."
                                                });
                                                case (?account) {
                                                    // Disolve pending signatures
                                                    linkSignatures.delete(sisterPrincipal);
                                                    linkSignatures.delete(callerPrincipal);
                                                    return #ok({
                                                        account = putAccount({
                                                            id = account.id;
                                                            primaryWallet = callerWallet;
                                                            alias = null;
                                                            avatar = null;
                                                            flavorText = null;
                                                            stoicAddress = ?stoicAddress;
                                                            plugAddress = ?plugAddress;
                                                        });
                                                        message = ""
                                                    });
                                                };
                                            }
                                        };
                                        case (null, ?sisterAccountId) {
                                            // Account exists for sister principal, consolidate.
                                            switch (accounts.get(sisterAccountId)) {
                                                case null return #err({
                                                    message = "Internal error. Please contact the developer."
                                                });
                                                case (?account) {
                                                    // Disolve pending signatures
                                                    linkSignatures.delete(sisterPrincipal);
                                                    linkSignatures.delete(callerPrincipal);
                                                    return #ok({
                                                        account = putAccount({
                                                            id = account.id;
                                                            primaryWallet = sisterWallet;
                                                            alias = null;
                                                            avatar = null;
                                                            flavorText = null;
                                                            stoicAddress = ?stoicAddress;
                                                            plugAddress = ?plugAddress;
                                                        });
                                                        message = ""
                                                    });
                                                };
                                            }
                                        };
                                        case (?callerAccountId, ?sisterAccountId) {
                                            // Accounts exist for both principals
                                            // Attempt to merge them (for now just brute)
                                            switch (accounts.get(callerAccountId)) {
                                                case null return #err({
                                                    message = "Internal error. Please contact the developer."
                                                });
                                                case (?account) {
                                                    // Disolve pending signatures
                                                    linkSignatures.delete(sisterPrincipal);
                                                    linkSignatures.delete(callerPrincipal);
                                                    return #ok({
                                                        account = putAccount({
                                                            id = account.id;
                                                            primaryWallet = callerWallet;
                                                            alias = null;
                                                            avatar = null;
                                                            flavorText = null;
                                                            stoicAddress = ?stoicAddress;
                                                            plugAddress = ?plugAddress;
                                                        });
                                                        message = ""
                                                    });
                                                };
                                            }
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
                // case (#dedupe(request)) {
                //     // get with caller AR.PendingAccountPrincipalRecord or #err
                //     // update chosen account with payload, dissolve unchosen account, dissolve AR.PendingAccountPrincipalRecord
                //     // return #ok
                // };
            };
        };

        private func unpackPrincipal (player : MPlayer.Player) : Principal {
            switch (player) {
                case (#stoic(p)) p;
                case (#plug(p)) p;
            }
        };

        // Helper to add to denormalized maps
        private func putAccount(account : AR.AccountRecord) : AR.AccountRecord {
            accounts.put(account.id, account);
            switch (account.stoicAddress) {
                case (?p) principalAccountMap.put(p, account.id);
                case null ();
            };
            switch (account.plugAddress) {
                case (?p) principalAccountMap.put(p, account.id);
                case null ();
            };
            return account;
        };

        private func createAccount (primaryWallet : MPlayer.Player) : AR.AccountRecord {
            let account : AR.AccountRecord = {
                id = nextAccountId;
                primaryWallet = primaryWallet;
                alias = null;
                avatar = null;
                flavorText = null;
                stoicAddress = switch (primaryWallet) {
                    case (#stoic(address)) ?address;
                    case (#plug(address)) null;
                };
                plugAddress = switch (primaryWallet) {
                    case (#plug(address)) ?address;
                    case (#stoic(address)) null;
                };
            };
            ignore putAccount(account);
            nextAccountId := nextAccountId + 1;
            account;
        };

        private func getOrCreateAccount (player : MPlayer.Player) : (AR.AccountRecord, Bool) {
            let principal = unpackPrincipal(player);
            switch (principalAccountMap.get(principal)) {
                case (?accountId) {
                    switch (accounts.get(accountId)) {
                        case (?account) return (account, false);
                        case null ();
                    };
                };
                case null ();
            };
            let account = createAccount(player);
            (account, true);
        };
    };
}