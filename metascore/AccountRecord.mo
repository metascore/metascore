import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";

module {

    public type AccountId = Nat;

    // A user account.
    public type AccountRecord = {
        id : Nat;
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
            ?Text,
            ?Text,
            ?Text,
        ),
    );

    public type Accounts = HashMap.HashMap<
        AccountId,
        AccountRecord,
    >;

    public func emptyAccounts(n : Nat) : Accounts {
        HashMap.HashMap<AccountId, AccountRecord>(
            n, Nat.equal, Nat32.fromNat,
        );
    };

    public func fromStable(records : [AccountRecordStable]) : Accounts {
        let accounts = emptyAccounts(records.size());
        for ((accountId, (stoicAddress, plugAddress, alias, flavorText, avatar)) in records.vals()) {
            accounts.put(accountId, {
                id = accountId; stoicAddress; plugAddress; alias; flavorText; avatar;
            });
        };
        accounts;
    };

    public func toStable(records : Accounts) : [AccountRecordStable] {
        var accounts : [AccountRecordStable] = [];
        for ((aID, r) in records.entries()) {
            accounts := Array.append<AccountRecordStable>(accounts, [(
                aID, (
                    r.stoicAddress,
                    r.plugAddress,
                    r.alias,
                    r.flavorText,
                    r.avatar,
                ),
            )]);
        };
        accounts;
    };
};