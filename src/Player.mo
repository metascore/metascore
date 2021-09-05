import Bool "mo:base/Bool";
import Hash "mo:base/Hash";
import Text "mo:base/Text";

module {
    public type Player = {
        #stoic : Text;
        #plug  : Text;
    };

    public let equal = func (a : Player, b : Player) : Bool {
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

    public let hash = func (player : Player) : Hash.Hash {
        switch (player) {
            case (#stoic(player)) Text.hash(player);
            case (#plug(player)) Text.hash(player);
        };
    };

    public let toText = func (player : Player) : Text {
        switch (player) {
            case (#stoic(player)) player;
            case (#plug(player)) player;
        };
    };
};