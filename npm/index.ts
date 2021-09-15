import { Actor, ActorConfig, HttpAgent, HttpAgentOptions } from "@dfinity/agent";
import { idlFactory } from './generated';
import {
    Metascore,
} from './generated/metascore.did.js';
import type {
    GamePrincipal,
    Metadata,
    Player,
    Result,
    Score,
} from './generated/metascore.did.d';

const STAGING_PRINCIPAL = 'rl4ub-oqaaa-aaaah-qbi3a-cai';

// Satisfy dfx generated code
// ...and vite (because it statically replaces things? wtf???)
const process : any = (window as any).process = { env: {}};
process.env['NODE_ENV'] = 'production';
process.env.METASCORE_CANISTER_ID = STAGING_PRINCIPAL;

// Represents the public API of the Metascore canister that serves all data.
interface MetascoreQuery {
    getPercentile: Metascore['getGames'];
    // Returns the ranking of a player in the given game;
    getRanking: Metascore['getRanking'];
    // Returns the Metascore of a player in the given game;
    getMetascore: Metascore['getMetascore'];
    // Returns the overall Metascore of a player.
    getOverallMetascore: Metascore['getOverallMetascore'];
    // Returns a list of all games.
    getGames: Metascore['getGames'];
    // Returns scores for a game.
    getGamesScores: Metascore['getGameScores'];
};

const queryIdlFactory = ({ IDL } : any) => {
    const base = idlFactory({ IDL });
    return IDL.Service({
        getGames: base.getGames,
        getMetascore: base.getMetascore,
        getOverallMetascore: base.getOverallMetascore,
        getPercentile: base.getPercentile,
        getRanking: base.getRanking,
    });
};

const createActor = () => {
    const options : {
        agentOptions : HttpAgentOptions;
        actorOptions : ActorConfig;
    } = {
        agentOptions: {host: 'https://raw.ic0.app'},
        actorOptions: {
            canisterId: STAGING_PRINCIPAL
        },
    };
    const agent = new HttpAgent({ ...options?.agentOptions });
    return Actor.createActor<MetascoreQuery>(idlFactory, {
        agent,
        ...options?.actorOptions,
    });
};

export {
    queryIdlFactory as idlFactory,
    createActor,
    STAGING_PRINCIPAL,

    GamePrincipal,
    Metadata,
    MetascoreQuery,
    Player,
    Result,
    Score,
};