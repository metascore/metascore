import Array "mo:base/Array";
import AssetStorage "mo:http/AssetStorage";
import Blob "mo:base/Blob";
import Float "mo:base/Float";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";

import Debug "mo:base/Debug";

import G "game/Game";
import MS "Metascore";
import Player "Player";

shared ({caller = owner}) actor class Metascore() : async MS.Interface {

    // DISCLAIMER:
    // Ignoring stable variables for now.

    // Time since last cron call.
    private var lastCron : Int = Time.now();
    // Map of registered game canisters.
    private let gameCanisters = HashMap.HashMap<Principal, Record>(
        0, Principal.equal, Principal.hash,
    );

    private type Record = {
        name          : Text;
        rawScores     : MS.Scores;
        playerRanking : HashMap.HashMap<Player.Player, Nat>;
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
        Debug.print("Registering " # name # " (" # Principal.toText(caller) # ")...");
        let scores = await getScores(caller);
        gameCanisters.put(caller, {
            name          = name;
            rawScores     = scores;
            playerRanking = scoresToRanking(scores);
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
            let scores = await getScores(p);
            gameCanisters.put(p, {
                name          = g.name;
                rawScores     = scores;
                playerRanking = scoresToRanking(scores);
            });
        };
    };

    private func getScores(id : Principal) : async MS.Scores {
        let game : G.Interface = actor(Principal.toText(id));
        Array.sort(
            await game.metascoreScores(),
            // Sort from high to low.
            func (a : MS.Score, b : MS.Score) : Order.Order {
                let (x, y) = (a.1, b.1);
                if      (x < y)  { #greater; }
                else if (x == y) { #equal;   }
                else             { #less;    };
            },
        );
    };

    public func getPercentile(
        game    : Principal,
        player  : Player.Player,
    ) : async ?Float {
        switch (gameCanisters.get(game)) {
            case (null) { null; };
            case (? gc) {
                switch (gc.playerRanking.get(player)) {
                    case (null) { null; };
                    case (? r)  {
                        let n = Float.fromInt(gc.playerRanking.size());
                        ?((n - Float.fromInt(r - 1)) / n);
                    };
                };
            };
        };
    };

    public func getRanking(
        game    : Principal,
        player  : Player.Player,
    ) : async ?Nat {
        switch (gameCanisters.get(game)) {
            case (null) { null; };
            case (? gc) {
                switch (gc.playerRanking.get(player)) {
                    case (null) { null; };
                    case (? r)  { ?r    };
                };
            };
        };
    };

    public func getGameScoreComponent (
        game    : Principal,
        player  : Player.Player,
    ) : async ?Nat {
        // To drive people to try all games, 1/2 of points awarded for participation.
        var score : Float = 0.5;
        // NOTE: Unpacking options is my second least favourite thing in Motoko.
        switch (await getPercentile(game, player)) {
            case (null) return null;
            case (?percentile) {
                switch (await getRanking(game, player)) {
                    case (null) return null;
                    case (?ranking) {
                        // Players get up to 1/4 of available points based on performance.
                        score := score + 0.25 * percentile;
                        // To encourage podium battles, 1/4 of points reserved for top three.
                        if (ranking == 3) {
                            score := score + 0.25 / 4;
                        };
                        if (ranking == 2) {
                            score := score + 0.25 / 2;
                        };
                        if (ranking == 2) {
                            score := score + 0.25;
                        };
                        // To retain resolution and make scores cool, we multiply by a trillion.
                        score := score * 1_000_000_000_000;
                        // NOTE: Converting types is my least favourite thing in Motoko.
                        return ?Int.abs(Float.toInt(score));
                    };
                };
            };
        };
    };

    public func getMetascore (player : Player.Player) : async Nat {
        var score = 0;
        for ((p, _) in gameCanisters.entries()) {
            switch (await getGameScoreComponent(p, player)) {
                case (null) ();
                case (?component) score := score + component;
            };
        };
        score;
    };

    public func getOverallRanking(
        game : Principal,
    ) : async [Player.Player] {
        switch (gameCanisters.get(game)) {
            case (null) { return []; };
            case (? gc) {
                Array.tabulate<Player.Player>(
                    gc.rawScores.size(),
                    func (i : Nat) : Player.Player { 
                        let (p, _) = gc.rawScores[i];
                        p;
                    },
                );
            };
        };
    };

    // Assumes that the incoming scores are sorted (high to low).
    private func scoresToRanking(scores : MS.Scores) : HashMap.HashMap<Player.Player, Nat> {
        let m = HashMap.HashMap<Player.Player, Nat>(scores.size(), Player.equal, Player.hash);
        for (i in scores.keys()) {
            let (p, _) = scores[i];
            m.put(p, i + 1);
        };
        m;
    };

    public query func http_request(
        r : AssetStorage.HttpRequest,
    ) : async AssetStorage.HttpResponse {
        var text = "<h1>Hello world!</h1>";
        for ((p, r) in gameCanisters.entries()) {
            text #= "<div>";
            text #= "<h2>" # r.name # " (" # Principal.toText(p) # ")</h2>";
            text #= "<h3>Top 3</h3>";
            text #= "<ol>";
            for (i in Iter.range(0, Nat.min(2, r.rawScores.size() - 1))) {
                text #= "<li>" # Player.toText(r.rawScores[i].0) # "</li>";
            };
            text #= "</ol>";
            text #= "</div>";
        };
        {
            body               = Blob.toArray(Text.encodeUtf8(text));
            headers            = [("Content-Type", "text/html; charset=UTF-8")];
            streaming_strategy = null;
            status_code        = 200;
        };
    };
};
