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

        getPercentile          : query (MPublic.GamePrincipal, MPlayer.Player) -> async ?Float;
        getRanking             : query (MPublic.GamePrincipal, MPlayer.Player) -> async ?Nat;
        getMetascore           : query (MPublic.GamePrincipal, MPlayer.Player) -> async Nat;
        getOverallMetascore    : query (MPlayer.Player)                        -> async Nat;
        getGames               : query ()                                      -> async [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                 : query (n : Nat)                               -> async [MPublic.Score];
        getGameScores          : query (MPublic.GamePrincipal, ?Nat, ?Nat)     -> async [MPublic.Score];
        getMetascores          : query (?Nat, ?Nat)                            -> async [MPublic.Score];
        getPercentileMetascore : query (Float)                                 -> async Nat;
        getPlayerCount         : query ()                                      -> async Nat;
        getScoreCount          : query ()                                      -> async Nat;

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
        getPercentile          : (MPublic.GamePrincipal, MPlayer.Player) -> ?Float;
        getRanking             : (MPublic.GamePrincipal, MPlayer.Player) -> ?Nat;
        getMetascore           : (MPublic.GamePrincipal, MPlayer.Player) -> Nat;
        getOverallMetascore    : (MPlayer.Player)                        -> Nat;
        getGames               : ()                                      -> [(MPublic.GamePrincipal, MPublic.Metadata)];
        getTop                 : (n : Nat)                               -> [MPublic.Score];
        getGameScores          : (MPublic.GamePrincipal, ?Nat, ?Nat)     -> [MPublic.Score];
        getMetascores          : (?Nat, ?Nat)                            -> [MPublic.Score];
        getPercentileMetascore : (Float)                                 -> Nat;
        getPlayerCount         : ()                                      -> Nat;
        getScoreCount          : ()                                      -> Nat;
    };
};
