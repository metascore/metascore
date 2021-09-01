import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Debug "mo:base/Debug";

import G "game/Game";
import MS "MetaScore";

shared ({caller}) actor class MetaScore() : async MS.Interface {

    // DISCLAIMER:
    // Ignoring stable variables for now.

    // Time since last cron call.
    private var lastCron : Int = Time.now();
    // Map of registered game canisters.
    private let gameCanisters = HashMap.HashMap<Text, Principal>(
        0, Text.equal, Text.hash,
    );

    public func register(
        id : Principal,
    ) : async Result.Result<(), Text> {    
        let game : G.Interface = actor(Principal.toText(id));
        await game.registerSelf(registerGame);
        #ok();
    };

    public shared ({caller}) func registerGame(
        name : Text,
    ) : async () {
        let pID = Principal.toText(caller);
        Debug.print("Registering " # name # " (" # pID # ")...");
        let game : G.Interface = actor(pID);
        ignore await game.scores();
        gameCanisters.put(name, caller);
    };

    private let sec = 1_000_000_000;

    // Endpoint to trigger cron-like operations.
    // Fastest interval = 3 sec.
    public func cron() : async () {
        let now = Time.now();
        if (3 * sec < now - lastCron) {
            await queryAllScores();
            lastCron := now;
        };
    };

    private func queryAllScores() : async () {
        Debug.print("Getting scores...");
        for ((_, p) in gameCanisters.entries()) {
            let game : G.Interface = actor(Principal.toText(p));
            let scores = await game.scores();

            // Do something with it.
            let _ = scores;
        };
    };
};
