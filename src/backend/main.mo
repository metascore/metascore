import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Int "mo:base/Bool";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Types "./types";


// shared ({ caller = creator }) actor class Metascore (init : ?Types.InitObject) = canister {
shared ({ caller = creator }) actor class Metascore () = canister {


    ////////////
    // State //
    //////////

    stable var owners : [Principal] = [];
    stable var gameCanDir : [Types.GameCanRecord] = [];
    // I'm sure theres a better data model to use. Tries?
    stable var playerScores : [(Types.Player, Types.GameCanRecord, Types.Score)] = [];
    stable var playerPercentiles : [(Types.Player, Types.GameCanRecord, Types.Percentile)] = [];
    stable var playerMetascores : [(Types.Player, Types.GameCanRecord, Types.Score)] = [];
    stable var lastCron : Int = 0;
    

    ///////////////
    // Upgrades //
    /////////////

    system func preupgrade () {};
    system func postupgrade () {};


    /////////////////////
    // Initialization //
    ///////////////////

    // switch (init) {
    //     case (?init) {
    //         owners := init.owners;
    //     };
    //     case (null) {
    //         owners := [creator];
    //     };
    // };


    //////////
    // API //
    ////////

    public shared func registerGameCan (can : Types.GameCanRecord) : async Types.RegistrationResponse {
        ignore queryGameCan(can);
        gameCanDir := Array.append(gameCanDir, [can]);
        #ok("Success.");
    };

    public func canister_heartbeat () : async () {
        await cron();
    };

    public query func getGameCans () : async [Types.GameCanRecord] {
        gameCanDir;
    };

    public query func getPlayerScores () : async [(Types.Player, Types.GameCanRecord, Types.Score)] {
        playerScores;
    };

    public query func getPlayerPercentiles () : async [(Types.Player, Types.GameCanRecord, Types.Percentile)] {
        playerPercentiles;
    };

    public query func getPlayerMetascores () : async [(Types.Player, Types.GameCanRecord, Types.Score)] {
        playerMetascores;
    };


    ////////////////
    // Internals //
    //////////////

    private func cron () : async () {
        // Debounce requests based on desired interval.
        let interval : Int = 1 * 60 * Float.toInt(1e9); // 1 minute in nano seconds.
        let now = Time.now();
        if (now - lastCron < interval) {
            return;
        };
        // Run our tasks.
        lastCron := now;
        await queryAllGameCans();
    };

    private func queryGameCan (principal : Types.GameCanRecord) : async Types.GameCanQueryResponse {     
        let can : Types.GameCanActor = actor(Principal.toText(principal));
        let scores = await can.metascoreDump();
        #ok(scores);
    };

    // Public for ease of dev
    public func queryAllGameCans () : async () {
        Debug.print("Querying game canisters...");
        var scores : [(Types.Player, Types.GameCanRecord, Types.Score)] = [];
        for (can in Iter.fromArray(gameCanDir)) {
            Debug.print("Querying can" # Principal.toText(can));
            switch (await queryGameCan(can)) {
                case (#ok(canScores)) {
                    for ((player, score) in Iter.fromArray(canScores)) {
                        scores := Array.append(scores, [(player, can, score)]);
                    };
                };
                case (#err(error)) {
                    Debug.print("Error query" # error);
                };
            };
        };
        // Wipe record clean on scores for now. TODO: smart replace.
        playerScores := scores;
        calculatePercentiles();
    };

    private func calculatePercentiles () : () {
        Debug.print("Calculating player percentiles...");
        calculateMetascores();
    };

    private func calculateMetascores () : () {
        Debug.print("Calculating player metascores...");
        ();
    };

};