import Result "mo:base/Result";

import Player "Player";

module {
    public type Score = (AccountId, Nat);

    public type AccountId = Nat;

    public type Account = {
        alias         : ?Text;
        avatar        : ?Text;
        flavorText    : ?Text;
        id            : AccountId;
        plugAddress   : ?Principal;
        primaryWallet : Player.Player;
        stoicAddress  : ?Principal;
    };

    // Represents the public API of the Metascore canister to authenticate users.
    public type PublicInterface = actor {
        // Returns the account associated with the given identifier.
        getAccount          : query  (AccountId)               -> async Result.Result<Account, ()>;
        // Updates an existing account.
        updateAccount       : shared (UpdateRequest)           -> async UpdateResponse;
        // Authentication of an account.
        authenticateAccount : shared (AuthenticationRequest)   -> async AuthenticationResponse;
    };

    // Account authentication request.
    public type AuthenticationRequest = {
        #authenticate : Player.Player;
        #link         : (Player.Player, Player.Player);
    };

    // Account authentication response.
    public type AuthenticationResponse = {
        #forbidden;
        #ok                     : { message : Text; account : Account; };
        #err                    : { message : Text; };
        #pendingConfirmation    : { message : Text; };
    };

    // Account profile update request.
    public type UpdateRequest = {
        alias         : ?Text;
        avatar        : ?Text;
        flavorText    : ?Text;
        primaryWallet : ?Player.Player;
    };

    // Account profile update response.
    public type UpdateResponse = Result.Result<Account, Text>;
};
