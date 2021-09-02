import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {
    public type Player = {
        #stoic : Text;
        #plug  : Text;
    };

    public let playerEqual = func (a : Player, b : Player) : Bool {
        switch (a) {
            case (#stoic(a)) {
                switch (b) {
                    case (#stoic(b)) Text.equal(a, b);
                    case (#plug(b)) false;
                };
            };
            case (#plug(a)) {
                switch (b) {
                    case (#plug(b)) Text.equal(a, b);
                    case (#stoic(b)) false;
                };
            }
        };
    };

    public let playerHash = func (player : Player) : Hash.Hash {
        switch (player) {
            case (#stoic(player)) Text.hash(player);
            case (#plug(player)) Text.hash(player);
        };
    };

    public let playerToText = func (player : Player) : Text {
        switch (player) {
            case (#stoic(player)) player;
            case (#plug(player)) player;
        };
    };

    public type Score = (
        Player,    // Wallet address of the player.
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
