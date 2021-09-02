import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Player "Player";

module {

    public type Score = (
        Player.Player,    // Wallet address of the player.
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
