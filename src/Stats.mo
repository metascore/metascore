import MAccount "Account";
import MPublic "Metascore";

module {
    // Represents the public API of the Metascore canister that serves all data.
    // It should only be used by front-end code.
    public type PublicInterface = actor {
        // Returns the percentile of a player in a game game.
        getPercentile : query (MAccount.AccountId) -> async ?Float;
        // Returns the ranking of a player in the given game;
        getRanking : query (MPublic.GamePrincipal, MAccount.AccountId) -> async ?Nat;
        // Returns the Metascore of a player in the given game;
        getMetascore : query (MPublic.GamePrincipal, MAccount.AccountId) -> async Nat;
        // Returns the overall Metascore of a player.
        getOverallMetascore : query (MAccount.AccountId) -> async Nat;
        // Returns a list of all games.
        getGames : query () -> async [(MPublic.GamePrincipal, MPublic.Metadata)];
        // Returns the top n overall players.
        getTop : query (Nat) -> async [MAccount.Score];
        // Returns a list of scores for a game.
        getGameScores : query (MPublic.GamePrincipal, ?Nat, ?Nat) -> async [MAccount.Score];
        // Returns a detailed list of scores for a game.
        getDetailedGameScores : query (MPublic.GamePrincipal, ?Nat, ?Nat) -> async [MAccount.DetailedScore];
        // Returns a list of metascores.
        getMetascores : query (?Nat, ?Nat) -> async [MAccount.Score];
        // Returms a detailed list of metascores.
        getDetailedMetascores : query (?Nat, ?Nat) -> async [MAccount.DetailedScore];
        // Returns metascore at given percentile.
        getPercentileMetascore : query (Float) -> async Nat;
        // Returns total number of players.
        getPlayerCount : query () -> async Nat;
        // Returns total number of scores.
        getScoreCount : query () -> async Nat;
    };
};