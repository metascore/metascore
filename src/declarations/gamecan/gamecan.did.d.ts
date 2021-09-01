import type { Principal } from '@dfinity/principal';
export type Player = { 'plug' : string } |
  { 'stoic' : string };
export type Score = bigint;
export type ScoreDump = Array<[Player, Score]>;
export interface _SERVICE { 'metascoreDump' : () => Promise<ScoreDump> }
