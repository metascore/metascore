import Result "mo:base/Result";

import MAccount "../src/Account";
import MPlayer  "../src/Player";
import MPublic  "../src/Metascore";

module {
    // CHORE: make sure this is updated! Ensures some compiler checks. ~ quint
    public type FullInterface = actor {
        // MetascoreInterface (see public/Metascore.mo).

        register    : shared (MPublic.GamePrincipal) -> async Result.Result<(), Text>;
        // @auth: admin/game
        unregister  : shared (MPublic.GamePrincipal) -> async ();
        // @auth: game
        scoreUpdate : shared ([MPublic.Score])       -> async ();

        // PublicInterface (see public/Stats.mo).

        getPercentile          : query  (MPublic.GamePrincipal, MAccount.AccountId) -> async ?Float;
        getRanking             : query  (MPublic.GamePrincipal, MAccount.AccountId) -> async ?Nat;
        getGames               : query  ()                                          -> async [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                 : query  (MPublic.GamePrincipal, n : Nat)            -> async [MAccount.Score];
        getGameScores          : query  (MPublic.GamePrincipal, ?Nat, ?Nat)         -> async [MAccount.Score];
        getPlayerCount         : shared ()                                          -> async Nat;
        getScoreCount          : query  ()                                          -> async Nat;

        // Internal Interface (used in main.mo).
        registerGame : shared MPublic.Metadata -> async ();
        // @auth: admin
        cron         : shared ()               -> async ();
        addAdmin     : shared (Principal)      -> async ();
        removeAdmin  : shared (Principal)      -> async ();
        isAdmin      : query  (Principal)      -> async Bool;

        // CHORE: add functions whenever it is public.
    };

    public type StateInterface = {
        getPercentile          : (MPublic.GamePrincipal, MAccount.AccountId) -> ?Float;
        getRanking             : (MPublic.GamePrincipal, MAccount.AccountId) -> ?Nat;
        getGames               : ()                                          -> [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                 : (MPublic.GamePrincipal, Nat)                -> [MAccount.Score];
        getGameScores          : (MPublic.GamePrincipal, ?Nat, ?Nat)         -> [MAccount.Score];
        getScoreCount          : ()                                          -> Nat;
    };

    public type AccountsInterface = actor {
        getAccount            : query  (MAccount.AccountId)             -> async Result.Result<MAccount.Account, ()>;
        getAccountCount       : query  ()                               -> async Nat;
        getAccountDetails     : query  (MAccount.AccountId)             -> async Result.Result<MAccount.AccountDetails, ()>;
        getAccountsFromScores : query  ([MPublic.Score])                -> async [MAccount.Score];
        updateAccount         : shared (MAccount.UpdateRequest)         -> async MAccount.UpdateResponse;
        authenticateAccount   : shared (MAccount.AuthenticationRequest) -> async MAccount.AuthenticationResponse;
    };
};
