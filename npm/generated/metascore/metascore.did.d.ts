import type { Principal } from '@dfinity/principal';
export interface AccountDetails {
  'id' : AccountId,
  'alias' : [] | [string],
  'flavorText' : [] | [string],
  'avatar' : [] | [string],
}
export type AccountId = bigint;
export type DetailedScore = [AccountDetails, bigint];
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
export interface Metadata {
  'name' : string,
  'playUrl' : string,
  'flavorText' : [] | [string],
}
export interface Metascore {
  'addAdmin' : (arg_0: Principal) => Promise<undefined>,
  'cron' : () => Promise<undefined>,
  'drainScoreUpdateLog' : () => Promise<Array<[GamePrincipal, Score__1]>>,
  'getDetailedGameScores' : (
      arg_0: GamePrincipal,
      arg_1: [] | [bigint],
      arg_2: [] | [bigint],
    ) => Promise<Array<DetailedScore>>,
  'getGameScores' : (
      arg_0: GamePrincipal,
      arg_1: [] | [bigint],
      arg_2: [] | [bigint],
    ) => Promise<Array<Score__1>>,
  'getGames' : () => Promise<Array<[GamePrincipal, Metadata]>>,
  'getPercentile' : (arg_0: GamePrincipal, arg_1: AccountId) => Promise<
      [] | [number]
    >,
  'getPlayerCount' : () => Promise<bigint>,
  'getRanking' : (arg_0: GamePrincipal, arg_1: AccountId) => Promise<
      [] | [bigint]
    >,
  'getScoreCount' : () => Promise<bigint>,
  'getTop' : (arg_0: GamePrincipal, arg_1: bigint) => Promise<Array<Score__1>>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'isAdmin' : (arg_0: Principal) => Promise<boolean>,
  'loadAccountScores' : (
      arg_0: GamePrincipal,
      arg_1: Array<Score__1>,
    ) => Promise<undefined>,
  'loadGameScores' : (arg_0: GamePrincipal, arg_1: Array<Score>) => Promise<
      undefined
    >,
  'loadGames' : (arg_0: Array<[GamePrincipal, Metadata]>) => Promise<undefined>,
  'queryGameScores' : (arg_0: GamePrincipal) => Promise<undefined>,
  'register' : (arg_0: GamePrincipal) => Promise<Result>,
  'registerGame' : (arg_0: Metadata) => Promise<undefined>,
  'removeAdmin' : (arg_0: Principal) => Promise<undefined>,
  'scoreUpdate' : (arg_0: Array<Score>) => Promise<undefined>,
  'setAccountsCanister' : (arg_0: Principal) => Promise<Principal>,
  'unregister' : (arg_0: GamePrincipal) => Promise<undefined>,
}
export type Player = { 'plug' : Principal } |
  { 'stoic' : Principal };
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Score = [Player, bigint];
export type Score__1 = [AccountId, bigint];
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
