import Bool "mo:base/Bool";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

module {
    // Represents a player.
    // Supported: Stoic and Plug.
    public type Player = {
        #stoic : Principal;
        #plug  : Principal;
    };

    public let equal = func (a : Player, b : Player) : Bool {
        switch (a, b) {
            case (#stoic(a), #stoic(b)) { Principal.equal(a, b); };
            case (#plug(a) , #plug(b) ) { Principal.equal(a, b); };
            case (_) { false; };
        };
    };

    public let hash = func (player : Player) : Hash.Hash {
        switch (player) {
            case (#stoic(player)) { Principal.hash(player); };
            case (#plug(player))  { Principal.hash(player); };
        };
    };

    public let toText = func (player : Player) : Text {
        switch (player) {
            case (#stoic(player)) { Principal.toText(player); };
            case (#plug(player))  { Principal.toText(player); };
        };
    };
};
