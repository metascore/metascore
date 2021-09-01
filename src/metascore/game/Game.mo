import MS "../MetaScore";

module {
    public type Interface = actor {
        // Endpoint that returns the scores.
        metascoreScores : query () -> async MS.Scores;
        // Function so the actor can register itself.
        metascoreRegisterSelf : shared (MS.RegisterCallback) -> async ();
    };
};
