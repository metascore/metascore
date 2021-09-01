import Result "mo:base/Result";


module {

    public type InitObject = {
        owners : [Principal];
    };

    public type Player = {
        #stoic : Text;
        #plug : Text;
    };

    public type Score = Nat;

    public type Percentile = Float;

    public type ScoreDump = [(Player, Score)];

    public type GameCanRecord = Principal;

    public type GameCanActor = actor {
        metascoreDump : () -> async ScoreDump;
    };

    public type GameCanQueryResponse = Result.Result<ScoreDump, Text>;

    public type RegistrationResponse = Result.Result<Text, {
        #notfound : {};
        #invalidresponse : {};
    }>;

};