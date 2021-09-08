import Bool "mo:base/Bool";
import Hash "mo:base/Hash";
import Text "mo:base/Text";

import MPublic "../src/Metascore";

module {
    public let equal = func (a : MPublic.Player, b : MPublic.Player) : Bool {
        switch (a, b) {
            case (#stoic(a), #stoic(b)) { Text.equal(a, b); };
            case (#plug(a) , #plug(b) ) { Text.equal(a, b); };
            case (_) { false; };
        };
    };

    public let hash = func (player : MPublic.Player) : Hash.Hash {
        switch (player) {
            case (#stoic(player)) { Text.hash(player); };
            case (#plug(player))  { Text.hash(player); };
        };
    };

    public let toText = func (player : MPublic.Player) : Text {
        switch (player) {
            case (#stoic(player)) { player; };
            case (#plug(player))  { player; };
        };
    };
};
