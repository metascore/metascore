import MPublic "Metascore";

module {
    // Represents the public API of the Metascore canister that serves all data.
    // It should only be used by front-end code.
    public type PublicInterface = {
        // Returns the percentile of a player in a game game.
        getPercentile : (MPublic.GamePrincipal, MPublic.Player) -> ?Float;
        // Returns the ranking of a player in the given game;
        getRanking : (MPublic.GamePrincipal, MPublic.Player) -> ?Nat;
        // Returns the Metascore of a player in the given game;
        getMetascore : (MPublic.GamePrincipal, MPublic.Player) -> Nat;
        // Returns the overall Metascore of a player.
        getOverallMetascore : (MPublic.Player) -> Nat;
        // Returns a list of all games.
        getGames : () -> [MPublic.Metadata];
    };
};