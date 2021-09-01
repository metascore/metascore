import MS "../MetaScore";

module {
    public type Interface = actor {
        // Endpoint that returns the scores.
        scores       : query () -> async [(Text, Nat)];
        // Function so the actor can register itself.
        registerSelf : shared (MS.RegisterCallback) -> async ();
    };
};
