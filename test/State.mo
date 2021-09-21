import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

import Users "../metascore/Users";
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
        0, [],
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
    assert(state.getMetascore(tarot, player1) == 1_000_000_000_000);
    assert(state.getMetascore(tarot, player2) ==   650_000_000_000);
};

let state = State.State(
    0, [],
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
    assert(state.globalLeaderboard.size() == 2);
    assert(state.gameLeaderboards.size() == 1);
    assert(state.games.size() == 1);

    assert(state.getGameScores(tarot, null, null) == [
        (player1, 10),
        (player2,  8),
    ]);

    assert(state.getGames() == [(tarot, tarotMetadata)]);

    assert(state.getMetascore(tarot, player1) == 1_000_000_000_000);
    assert(state.getMetascore(tarot, player2) ==   650_000_000_000);
    assert(state.getMetascores(null, null) == [
        (player1, 1_000_000_000_000),
        (player2,   650_000_000_000),
    ]);

    assert(state.getOverallMetascore(player1) == 1_000_000_000_000);

    assert(state.getPercentile(player1) == ?1.0);
    assert(state.getPercentile(player2) == ?0.5);

    assert(state.getPercentileMetascore(1.0) == 1_000_000_000_000);
    assert(state.getPercentileMetascore(0.9) ==   650_000_000_000);
    assert(state.getPercentileMetascore(0.5) ==   650_000_000_000);
    assert(state.getPercentileMetascore(0.4) ==                 0);

    assert(state.getPlayerCount() == 2);

    assert(state.getRanking(tarot, player1) == ?1);
    assert(state.getRanking(tarot, player2) == ?2);

    assert(state.getScoreCount() == 2);

    assert(state.getTop(3) == [
        (player1, 1_000_000_000_000),
        (player2,   650_000_000_000),
    ]);
};

testInitialState();
state.updateScore(tarot, (player1, 10)); // Should not change anything.
state.updateScore(tarot, (player2,  8));
testInitialState();

state.updateScore(tarot, (player2,  12));
do {
    assert(state.globalLeaderboard.size() == 2);
    assert(state.gameLeaderboards.size() == 1);
    assert(state.games.size() == 1);

    assert(state.getGameScores(tarot, null, null) == [
        (player2, 12),
        (player1, 10),
    ]);

    assert(state.getGames() == [(tarot, tarotMetadata)]);

    assert(state.getMetascore(tarot, player2) == 1_000_000_000_000);
    assert(state.getMetascore(tarot, player1) ==   666_666_666_666);
    assert(state.getMetascores(null, null) == [
        (player2, 1_000_000_000_000),
        (player1,   666_666_666_666),
    ]);

    assert(state.getOverallMetascore(player2) == 1_000_000_000_000);

    assert(state.getPercentile(player2) == ?1.0);
    assert(state.getPercentile(player1) == ?0.5);

    assert(state.getPercentileMetascore(1.0) == 1_000_000_000_000);
    assert(state.getPercentileMetascore(0.9) ==   666_666_666_666);
    assert(state.getPercentileMetascore(0.5) ==   666_666_666_666);
    assert(state.getPercentileMetascore(0.4) ==                 0);

    assert(state.getPlayerCount() == 2);

    assert(state.getRanking(tarot, player2) == ?1);
    assert(state.getRanking(tarot, player1) == ?2);

    assert(state.getScoreCount() == 2);

    assert(state.getTop(3) == [
        (player2, 1_000_000_000_000),
        (player1,   666_666_666_666),
    ]);
};

let metascore = Principal.fromText("tzvxm-jqaaa-aaaaj-qabga-cai");
let metascoreMetadata = {
    name = "Metascore";
    playUrl = "https://rc775-yyaaa-aaaah-qbi2q-cai.raw.ic0.app/";
    flavorText = null;
};
state.games.put(metascore, metascoreMetadata);
for (score in state.getTop(3).vals()) {
    state.updateScore(metascore, score);
};
do {
    assert(state.globalLeaderboard.size() == 2);
    assert(state.gameLeaderboards.size() == 2);
    assert(state.games.size() == 2);

    assert(state.getGameScores(tarot, null, null) == [
        (player2, 12),
        (player1, 10),
    ]);
    assert(state.getGameScores(metascore, null, null) == [
        (player2, 1_000_000_000_000),
        (player1,   666_666_666_666),
    ]);

    assert(state.getGames() == [
        (tarot, tarotMetadata),
        (metascore, metascoreMetadata),
    ]);

    assert(state.getMetascore(metascore, player2) == 1_000_000_000_000);
    assert(state.getMetascore(metascore, player1) ==   583_333_333_333);
    assert(state.getMetascores(null, null) == [
        (player2, 2_000_000_000_000),
        (player1, 1_249_999_999_999),
    ]);

    assert(state.getOverallMetascore(player2) == 2_000_000_000_000);

    assert(state.getPercentile(player2) == ?1.0);
    assert(state.getPercentile(player1) == ?0.5);

    assert(state.getPercentileMetascore(1.0) == 2_000_000_000_000);
    assert(state.getPercentileMetascore(0.9) == 1_249_999_999_999);
    assert(state.getPercentileMetascore(0.5) == 1_249_999_999_999);
    assert(state.getPercentileMetascore(0.4) ==                 0);

    assert(state.getPlayerCount() == 2);

    assert(state.getRanking(tarot, player2) == ?1);
    assert(state.getRanking(tarot, player1) == ?2);

    assert(state.getScoreCount() == 4);

    assert(state.getTop(3) == [
        (player2, 2_000_000_000_000),
        (player1, 1_249_999_999_999),
    ]);
};
 
Debug.print("Tests: PASSED")
