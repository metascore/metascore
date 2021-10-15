import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

import State "../metascore/State";

let tarot = Principal.fromText("l2jyf-nqaaa-aaaah-qadha-cai");
let tarotMetadata = {
    name = "Saga Tarot";
    playUrl = "https://l2jyf-nqaaa-aaaah-qadha-cai.raw.ic0.app/";
    flavorText = ?"A tarot card game.";
};
let player1 = 1;
let player2 = 2;

do {
    // Empty state.
    let state = State.State(
        [(
            tarot,
            (
                tarotMetadata,
                [],
            )
        )],
    );
    state.updateScores(tarot, [
        (player2,  8),
        (player1, 10),
    ]);
};

let state = State.State(
    [(
        tarot,
        (
            tarotMetadata,
            [
                (player1, 10),
                (player2,  8),
            ],
        )
    )],
);

func testInitialState() {
    assert(state.gameLeaderboards.size() == 1);
    assert(state.games.size() == 1);

    assert(state.getGameScores(tarot, null, null) == [
        (player1, 10),
        (player2,  8),
    ]);

    assert(state.getGames() == [(tarot, tarotMetadata)]);

    assert(state.getPercentile(tarot, player1) == ?1.0);
    assert(state.getPercentile(tarot, player2) == ?0.5);

    assert(state.getRanking(tarot, player1) == ?1);
    assert(state.getRanking(tarot, player2) == ?2);

    assert(state.getScoreCount() == 2);

    assert(state.getTop(tarot, 3) == [
        (player1, 10),
        (player2,  8),
    ]);
};

testInitialState();
state.updateScore(tarot, (player1, 10)); // Should not change anything.
state.updateScore(tarot, (player2,  8));
testInitialState();

state.updateScore(tarot, (player2,  12));
do {
    assert(state.gameLeaderboards.size() == 1);
    assert(state.games.size() == 1);

    assert(state.getGameScores(tarot, null, null) == [
        (player2, 12),
        (player1, 10),
    ]);

    assert(state.getGames() == [(tarot, tarotMetadata)]);

    assert(state.getPercentile(tarot, player2) == ?1.0);
    assert(state.getPercentile(tarot, player1) == ?0.5);

    assert(state.getRanking(tarot, player2) == ?1);
    assert(state.getRanking(tarot, player1) == ?2);

    assert(state.getScoreCount() == 2);

    assert(state.getTop(tarot, 3) == [
        (player2, 12),
        (player1, 10),
    ]);
};

let metascore = Principal.fromText("tzvxm-jqaaa-aaaaj-qabga-cai");
let metascoreMetadata = {
    name = "Metascore";
    playUrl = "https://rc775-yyaaa-aaaah-qbi2q-cai.raw.ic0.app/";
    flavorText = null;
};
state.games.put(metascore, metascoreMetadata);
for (score in state.getTop(tarot, 3).vals()) {
    state.updateScore(metascore, score);
};
do {
    assert(state.gameLeaderboards.size() == 2);
    assert(state.games.size() == 2);

    assert(state.getGameScores(tarot, null, null) == [
        (player2, 12),
        (player1, 10),
    ]);
    assert(state.getGameScores(metascore, null, null) == [
        (player2, 12),
        (player1, 10),
    ]);

    assert(state.getGames() == [
        (tarot, tarotMetadata),
        (metascore, metascoreMetadata),
    ]);

    assert(state.getPercentile(metascore, player2) == ?1.0);
    assert(state.getPercentile(metascore, player1) == ?0.5);

    assert(state.getRanking(metascore, player2) == ?1);
    assert(state.getRanking(metascore, player1) == ?2);

    assert(state.getScoreCount() == 4);

    assert(state.getTop(metascore, 3) == [
        (player2, 12),
        (player1, 10),
    ]);
};
 
Debug.print("Tests: PASSED")
