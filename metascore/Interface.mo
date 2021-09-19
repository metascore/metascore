import Result "mo:base/Result";

import MPlayer "../src/Player";
import MPublic "../src/Metascore";
import AR "AccountRecord";

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

        getPercentile         : query (MPublic.GamePrincipal, MPlayer.Player) -> async ?Float;
        getRanking            : query (MPublic.GamePrincipal, MPlayer.Player) -> async ?Nat;
        getMetascore          : query (MPublic.GamePrincipal, MPlayer.Player) -> async Nat;
        getOverallMetascore   : query (MPlayer.Player)                        -> async Nat;
        getGames              : query ()                                      -> async [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                : query (n : Nat)                               -> async [MPublic.Score];

        // Internal Interface (used in main.mo).
        registerGame : shared MPublic.Metadata -> async ();
        // @auth: admin
        cron         : shared ()               -> async ();
        addAdmin     : shared (Principal)      -> async ();
        removeAdmin  : shared (Principal)      -> async ();
        isAdmin      : query  (Principal)      -> async Bool;

        // Accounts interface
        getAccount          : query  (Nat)              -> async Result.Result<AR.AccountRecord, ()>;
        updateAccount       : shared (AR.UpdateRequest) -> async AR.UpdateResponse;
        authenticateAccount : shared (AR.AuthRequest)   -> async AR.AuthResponse;

        // CHORE: add functions whenever it is public.
    };
};
