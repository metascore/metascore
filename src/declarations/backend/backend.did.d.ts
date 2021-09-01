import type { Principal } from '@dfinity/principal';
export type GameCanRecord = Principal;
export interface Metascore {
  'canister_heartbeat' : () => Promise<undefined>,
  'getGameCans' : () => Promise<Array<GameCanRecord>>,
  'getPlayerMetascores' : () => Promise<Array<[Player, GameCanRecord, Score]>>,
  'getPlayerPercentiles' : () => Promise<
      Array<[Player, GameCanRecord, Percentile]>
    >,
  'getPlayerScores' : () => Promise<Array<[Player, GameCanRecord, Score]>>,
  'queryAllGameCans' : () => Promise<undefined>,
  'registerGameCan' : (arg_0: GameCanRecord) => Promise<RegistrationResponse>,
}
export type Percentile = number;
export type Player = { 'plug' : string } |
  { 'stoic' : string };
export type RegistrationResponse = { 'ok' : string } |
  { 'err' : { 'notfound' : {} } | { 'invalidresponse' : {} } };
export type Score = bigint;
export interface _SERVICE extends Metascore {}
