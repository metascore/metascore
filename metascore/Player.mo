import Bool "mo:base/Bool";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

import MPublic "../src/Metascore";

module {
    public let equal = func (a : MPublic.Player, b : MPublic.Player) : Bool {
        switch (a, b) {
            case (#stoic(a), #stoic(b)) { Principal.equal(a, b); };
            case (#plug(a) , #plug(b) ) { Principal.equal(a, b); };
            case (_) { false; };
        };
    };

    public let hash = func (player : MPublic.Player) : Hash.Hash {
        switch (player) {
            case (#stoic(player)) { Principal.hash(player); };
            case (#plug(player))  { Principal.hash(player); };
        };
    };

    public let toText = func (player : MPublic.Player) : Text {
        switch (player) {
            case (#stoic(player)) { Principal.toText(player); };
            case (#plug(player))  { Principal.toText(player); };
        };
    };
};
