import Result "mo:base/Result";

import MPlayer "../src/Player";
import MPublic "../src/Metascore";

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
        getGames              : query ()                                      -> async [MPublic.Metadata];
        getTop                : query (n : Nat)                               -> async [MPublic.Score];

        // Internal Interface (used in main.mo).
        registerGame : shared MPublic.Metadata -> async ();
        // @auth: admin
        cron         : shared ()               -> async ();
        addAdmin     : shared (Principal)      -> async ();
        removeAdmin  : shared (Principal)      -> async ();
        isAdmin      : query  (Principal)      -> async Bool;

        // CHORE: add functions whenever it is public.
    };
};