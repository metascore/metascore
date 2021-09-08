import Result "mo:base/Result";

module {
    // Just for readability.
    public type GamePrincipal = Principal;

    // Represents the interface of a game canister what wants to interact with 
    // the Metascore canister.
    public type GameInterface = actor {
        // Endpoint that returns the scores of the game.
        // This will be called once a day to sync all scores. Games are 
        // responsible to update the scores in the Metascore canister 
        // themselves, by calling the 'scoreUpdate' endpoint. 
        metascoreScores : query () -> async [Score];

        // Function so the game (actor) can register itself.
        metascoreRegisterSelf : shared (RegisterCallback) -> async ();
    };

    // Callback on which new games should register.
    public type RegisterCallback = shared (
        // Metadata of the game itself.
        metadata : Metadata
    ) -> async ();

    // Metadata of a game.
    public type Metadata = {
        name : Text; // Name of the game.
        // TODO: add more fields (e.g. genre, ...)
    };

    // Represents a player.
    // Supported: Stoic and Plug.
    public type Player = {
        #stoic : Text;
        #plug  : Text;
    };

    // Score of a player.
    public type Score = (
        Player, // Wallet address of the player.
        Nat,    // Score of the player.
    );

    // Represents the (minimal) interface of the Metascore canister.
    public type MetascoreInterface = actor {
        // Methods that needs to be called to register a new game.
        // Can be called by any principal account. a game canister will register
        // itself by calling the callback given in 'metascoreRegisterSelf'.
        register : (GamePrincipal) -> async Result.Result<(), Text>;

        // Endpoint to send score updates to.
        scoreUpdate : shared ([Score]) -> async ();
    };
};
