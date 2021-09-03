import type { Principal } from '@dfinity/principal';
export interface Game {
  'metascoreRegisterSelf' : (arg_0: [Principal, string]) => Promise<undefined>,
  'metascoreScores' : () => Promise<Scores>,
}
export interface Metadata { 'name' : string }
export type Player = { 'plug' : string } |
  { 'stoic' : string };
export type RegisterCallback = (arg_0: Metadata) => Promise<undefined>;
export type Score = [Player, bigint];
export type Scores = Array<Score>;
export interface _SERVICE extends Game {}
