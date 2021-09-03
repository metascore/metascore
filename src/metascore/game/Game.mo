import MS "../Metascore";

module {
    public type MetascoreInterface = actor {
        // Endpoint that returns the scores.
        metascoreScores : query () -> async MS.Scores;
        // Function so the actor can register itself.
        metascoreRegisterSelf : shared (MS.RegisterCallback) -> async ();
    };
};
