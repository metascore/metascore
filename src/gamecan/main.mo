import Debug "mo:base/Debug";

import Types "../backend/types";

actor {

    let scores = [
        (#stoic("player1"), 100_000),
        (#stoic("player2"), 80_000),
        (#stoic("player3"), 60_000),
        (#stoic("player4"), 10_000),
        (#stoic("player5"), 1_000),
    ];

    public func metascoreDump () : async Types.ScoreDump {
        Debug.print("GAMECAN: Dumping scores...");
        scores;
    };

};