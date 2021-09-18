import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import MPlayer "../src/Player";

module {

    // State supported by accounts module.
    public type AccountsState = {
        // Map of account records.
        accounts: Accounts;
        // Map from principal to account ID for efficient lookup.
        principalAccountMap : PrincipalAccountMap;
        // Map of principals signing intent to link under one account.
        linkSignatures : LinkSignatures;
    };

    // Accounts state made stable.
    public type AccountsStateStable = [AccountRecordStable];
    // public type AccountsStateStable = {
    //     accounts : [AccountRecordStable];
    //     linkSignatures : [(Principal, Principal)];
    // };

    // ID of an account.
    public type AccountId = Nat;

    // A user account.
    public type AccountRecord = {
        id : AccountId;
        primaryWallet : MPlayer.Player;
        stoicAddress : ?Principal;
        plugAddress : ?Principal;
        alias : ?Text;
        flavorText : ?Text;
        avatar : ?Text;
    };

    // User account made stable.
    public type AccountRecordStable = (
        AccountId,
        (
            ?Principal,
            ?Principal,
            MPlayer.Player,
            ?Text,
            ?Text,
            ?Text,
        ),
    );

    // Map of accounts.
    public type Accounts = HashMap.HashMap<
        AccountId,
        AccountRecord,
    >;

    // Map of principals to account IDs.
    public type PrincipalAccountMap = HashMap.HashMap<
        Principal,
        AccountId,
    >;

    // Map of principal pairs signing intent to link together in the same account.
    // NOTE: Used a hashmap for simplicity and speed, but could allow bad actor to interupt
    // (not intercept) link process by spamming requests to link a principal they don't own.
    public type LinkSignatures = HashMap.HashMap<
        Principal,
        Principal,
    >;

    // Account authentication request.
    public type AuthRequest = {
        #authenticate : MPlayer.Player;
        #link : MPlayer.Player;
        // #dedupe : AccountRecord;
    };

    // Account authentication response.
    public type AuthResponse = {
        #ok                     : { message : Text; account : AccountRecord; };
        #err                    : { message : Text; };
        #pendingConfirmation    : { message : Text; };
        #pendingDuplicate       : { message : Text; accounts : (AccountRecord, AccountRecord); };
    };

    public func emptyAccounts(n : Nat) : Accounts {
        HashMap.HashMap<AccountId, AccountRecord>(
            n, Nat.equal, Nat32.fromNat,
        );
    };

    public func emptyPrincipalAccountMap(n : Nat) : PrincipalAccountMap {
        HashMap.HashMap<Principal, AccountId>(
            n, Principal.equal, Principal.hash,
        );
    };

    public func emptyLinkSignatures(n : Nat) : LinkSignatures {
        HashMap.HashMap<Principal, Principal>(
            n, Principal.equal, Principal.hash,
        );
    };

    public func fromStable(state : AccountsStateStable) : AccountsState {
        // NOTE: Can probably remove link signatures from stable state...
        let accounts = emptyAccounts(state.size());
        let principalAccountMap = emptyPrincipalAccountMap(state.size() * 2);
        let linkSignatures = emptyLinkSignatures(0);
        for (
            (
                accountId,
                (stoicAddress, plugAddress, primaryWallet, alias, flavorText, avatar)
            ) in state.vals()
        ) {
            accounts.put(accountId, {
                id = accountId; primaryWallet; stoicAddress; plugAddress; alias; flavorText; avatar;
            });
            for (principal in Iter.fromArray<?Principal>([stoicAddress, plugAddress])) {
                switch (principal) {
                    case (?principal) principalAccountMap.put(principal, accountId);
                    case null ();
                };
            };
        };
        // for ((p1, p2) in state.linkSignatures.vals()) {
        //     linkSignatures.put(p1, p2);
        // };
        { accounts; principalAccountMap; linkSignatures; }
    };

    public func toStable(
            accountsState : Accounts,
            // linkSigsState : LinkSignatures,
        ) : AccountsStateStable {
        var accounts : [AccountRecordStable] = [];
        for ((aID, r) in accountsState.entries()) {
            accounts := Array.append(accounts, [(
                aID, (
                    r.stoicAddress,
                    r.plugAddress,
                    r.primaryWallet,
                    r.alias,
                    r.flavorText,
                    r.avatar,
                ),
            )]);
        };
        var linkSignatures : [(Principal, Principal)] = [];
        // for (pair in linkSigsState.entries()) {
        //     linkSignatures := Array.append(linkSignatures, [pair]);
        // };
        // { accounts; linkSignatures; }
        accounts;
    };

    public func nextId(records : [AccountRecordStable]) : Nat {
        var nextAccountId : Nat = 1;
        for ((accountId, (stoicAddress, plugAddress, primaryWallet, alias, flavorText, avatar)) in records.vals()) {
            nextAccountId := Nat.max(nextAccountId, accountId +1);
        };
        nextAccountId;
    };
};