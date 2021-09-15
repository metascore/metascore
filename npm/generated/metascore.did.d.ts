import type { Principal } from '@dfinity/principal';
export type GamePrincipal = Principal;
export type HeaderField = [string, string];
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export interface Metadata { 'name' : string }
export interface Metascore {
  'addAdmin' : (arg_0: Principal) => Promise<undefined>,
  'cron' : () => Promise<undefined>,
  'getGames' : () => Promise<Array<[GamePrincipal, Metadata]>>,
  'getMetascore' : (arg_0: GamePrincipal, arg_1: Player) => Promise<bigint>,
  'getOverallMetascore' : (arg_0: Player) => Promise<bigint>,
  'getPercentile' : (arg_0: GamePrincipal, arg_1: Player) => Promise<
      [] | [number]
    >,
  'getRanking' : (arg_0: GamePrincipal, arg_1: Player) => Promise<
      [] | [bigint]
    >,
  'getTop' : (arg_0: bigint) => Promise<Array<Score>>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'isAdmin' : (arg_0: Principal) => Promise<boolean>,
  'register' : (arg_0: GamePrincipal) => Promise<Result>,
  'registerGame' : (arg_0: Metadata) => Promise<undefined>,
  'removeAdmin' : (arg_0: Principal) => Promise<undefined>,
  'scoreUpdate' : (arg_0: Array<Score>) => Promise<undefined>,
  'unregister' : (arg_0: GamePrincipal) => Promise<undefined>,
}
export type Player = { 'plug' : Principal } |
  { 'stoic' : Principal };
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Score = [Player, bigint];
export interface StreamingCallbackHttpResponse {
  'token' : [] | [StreamingCallbackToken],
  'body' : Array<number>,
}
export interface StreamingCallbackToken {
  'key' : string,
  'sha256' : [] | [Array<number>],
  'index' : bigint,
  'content_encoding' : string,
}
export type StreamingStrategy = {
    'Callback' : {
      'token' : StreamingCallbackToken,
      'callback' : [Principal, string],
    }
  };
export interface _SERVICE extends Metascore {}
