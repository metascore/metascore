import Principal "mo:base/Result";
import Result "mo:base/Result";

module {
    public type Score = (
        Principal, // Principal of the player.
        Nat,       // Score of the player.
    );
    public type Scores = [Score];

    // Callback on which new games should register
    public type RegisterCallback = shared (
        Text // Name of the game.
    ) -> async ();

    public type Interface = actor {
        // Methods that needs to be called to register a new game.
        // Can be called by any principal account.
        register : (Principal) -> async Result.Result<(), Text>;

        // Callback to register games.
        registerGame : RegisterCallback;
    };
};
