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

        getPercentile          : query (MAccount.AccountId)                        -> async ?Float;
        getRanking             : query (MPublic.GamePrincipal, MAccount.AccountId) -> async ?Nat;
        getMetascore           : query (MPublic.GamePrincipal, MAccount.AccountId) -> async Nat;
        getOverallMetascore    : query (MAccount.AccountId)                        -> async Nat;
        getGames               : query ()                                          -> async [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                 : query (n : Nat)                                   -> async [MAccount.Score];
        getGameScores          : query (MPublic.GamePrincipal, ?Nat, ?Nat)         -> async [MAccount.Score];
        getDetailedGameScores  : query (MPublic.GamePrincipal, ?Nat, ?Nat)         -> async [MAccount.DetailedScore];
        getMetascores          : query (?Nat, ?Nat)                                -> async [MAccount.Score];
        getDetailedMetascores  : query (?Nat, ?Nat)                                -> async [MAccount.DetailedScore];
        getPercentileMetascore : query (Float)                                     -> async Nat;
        getPlayerCount         : query ()                                          -> async Nat;
        getScoreCount          : query ()                                          -> async Nat;

        // AccountInterface (see public/Account.mo)
        getAccount          : query  (MAccount.AccountId)             -> async Result.Result<MAccount.Account, ()>;
        getAccountDetails   : query  (MAccount.AccountId)             -> async Result.Result<MAccount.AccountDetails, ()>;
        updateAccount       : shared (MAccount.UpdateRequest)         -> async MAccount.UpdateResponse;
        authenticateAccount : shared (MAccount.AuthenticationRequest) -> async MAccount.AuthenticationResponse;

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
        getPercentile          : (MAccount.AccountId)                        -> ?Float;
        getRanking             : (MPublic.GamePrincipal, MAccount.AccountId) -> ?Nat;
        getMetascore           : (MPublic.GamePrincipal, MAccount.AccountId) -> Nat;
        getOverallMetascore    : (MAccount.AccountId)                        -> Nat;
        getGames               : ()                                          -> [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                 : (Nat)                                       -> [MAccount.Score];
        getGameScores          : (MPublic.GamePrincipal, ?Nat, ?Nat)         -> [MAccount.Score];
        getDetailedGameScores  : (MPublic.GamePrincipal, ?Nat, ?Nat)         -> [MAccount.DetailedScore];
        getMetascores          : (?Nat, ?Nat)                                -> [MAccount.Score];
        getDetailedMetascores  : (?Nat, ?Nat)                                -> [MAccount.DetailedScore];
        getPercentileMetascore : (Float)                                     -> Nat;
        getPlayerCount         : ()                                          -> Nat;
        getScoreCount          : ()                                          -> Nat;
    };
};
