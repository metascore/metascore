import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Debug "mo:base/Debug";

import G "game/Game";
import MS "MetaScore";

shared ({caller = owner}) actor class MetaScore() : async MS.Interface {

    // DISCLAIMER:
    // Ignoring stable variables for now.

    // Time since last cron call.
    private var lastCron : Int = Time.now();
    // Map of registered game canisters.
    private let gameCanisters = HashMap.HashMap<Principal, Record>(
        0, Principal.equal, Principal.hash,
    );

    private type Record = {
        name   : Text;
        scores : MS.Scores;
    };

    public func register(
        id : Principal,
    ) : async Result.Result<(), Text> {    
        let game : G.Interface = actor(Principal.toText(id));
        await game.metascoreRegisterSelf(registerGame);
        #ok();
    };

    public shared ({caller}) func registerGame(
        name : Text,
    ) : async () {
        let pID = Principal.toText(caller);
        Debug.print("Registering " # name # " (" # pID # ")...");
        let game : G.Interface = actor(pID);
        ignore await game.metascoreScores();
        gameCanisters.put(caller, {
            name   = name;
            scores = [];
        });
    };

    private let sec = 1_000_000_000;

    // Endpoint to trigger cron-like operations.
    // Fastest interval = 3 sec.
    public shared ({caller}) func cron() : async () {
        assert(caller == owner);

        let now = Time.now();
        if (3 * sec < now - lastCron) {
            await queryAllScores();
            lastCron := now;
        };
    };

    private func queryAllScores() : async () {
        Debug.print("Getting scores...");
        for ((p, g) in gameCanisters.entries()) {
            let game : G.Interface = actor(Principal.toText(p));
            let scores = await game.metascoreScores();
            
            // Sort from high to low.
            let sorted = Array.sort(scores, func (a : MS.Score, b : MS.Score) : Order.Order {
                let (x, y) = (a.1, b.1);
                if      (x < y)  { #greater; }
                else if (x == y) { #equal;   }
                else             { #less;    };
            });
            gameCanisters.put(p, {
                name   = g.name;
                scores = sorted;
            });
        };
    };
};
