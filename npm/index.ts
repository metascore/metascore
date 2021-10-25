import { Actor, ActorConfig, HttpAgent, HttpAgentOptions } from "@dfinity/agent";
import { idlFactory as metascoreIdl } from './generated/metascore';
import { idlFactory as accountsIdl } from './generated/accounts';
import {
    Accounts,
} from './generated/accounts/accounts.did.d';
import type {
    Player,
    GamePrincipal,
    Metadata,
    Result,
    Score,
    Metascore,
} from './generated/metascore/metascore.did.d';

const STAGING_PRINCIPAL = 'rl4ub-oqaaa-aaaah-qbi3a-cai';
const PRODUCTION_PRINCIPAL = 'tzvxm-jqaaa-aaaaj-qabga-cai';
const ACCOUNTS_PRINCIPAL = 'upsxs-oyaaa-aaaah-qcaua-cai';

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
    // Returns a list of all games.
    getGames: Metascore['getGames'];
    // Returns scores for a game.
    getGameScores: Metascore['getGameScores'];
    // Returns total number of scores.
    getScoreCount: Metascore['getScoreCount'];
    // Returns total number of players.
    getPlayerCount: Metascore['getPlayerCount'];
    // Get game scores with account data
    getDetailedGameScores: Metascore['getDetailedGameScores'];
};

interface AccountsQuery {
  authenticateAccount : Accounts['authenticateAccount'];
  getAccount : Accounts['getAccount'];
  getAccountCount : Accounts['getAccountCount'];
  getAccountDetails : Accounts['getAccountDetails'];
  updateAccount : Accounts['updateAccount'];
};

const createMetascoreActor = (agent?: HttpAgent, canisterId = STAGING_PRINCIPAL) => {
    const options : {
        agentOptions : HttpAgentOptions;
        actorOptions : ActorConfig;
    } = {
        agentOptions: {host: 'https://raw.ic0.app'},
        actorOptions: {
            canisterId
        },
    };
    agent = agent || new HttpAgent({ ...options?.agentOptions });
    return Actor.createActor<MetascoreQuery>(metascoreIdl, {
        agent,
        ...options?.actorOptions,
    });
};

const createAccountsActor = (agent?: HttpAgent, canisterId = ACCOUNTS_PRINCIPAL) => {
    const options : {
        agentOptions : HttpAgentOptions;
        actorOptions : ActorConfig;
    } = {
        agentOptions: {host: 'https://raw.ic0.app'},
        actorOptions: {
            canisterId
        },
    };
    agent = agent || new HttpAgent({ ...options?.agentOptions });
    return Actor.createActor<AccountsQuery>(accountsIdl, {
        agent,
        ...options?.actorOptions,
    });
};

export {
    createMetascoreActor,
    createAccountsActor,
    STAGING_PRINCIPAL,
    PRODUCTION_PRINCIPAL,
    ACCOUNTS_PRINCIPAL,

    GamePrincipal,
    Metadata,
    MetascoreQuery,
    Player,
    Result,
    Score,

    AccountsQuery,

    accountsIdl,
    metascoreIdl,
};