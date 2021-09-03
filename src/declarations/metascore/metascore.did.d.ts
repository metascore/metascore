import type { Principal } from '@dfinity/principal';
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
  'cron' : () => Promise<undefined>,
  'getGameScoreComponent' : (arg_0: Principal, arg_1: Player) => Promise<
      [] | [bigint]
    >,
  'getMetascore' : (arg_0: Player) => Promise<bigint>,
  'getOverallRanking' : (arg_0: Principal) => Promise<Array<Player>>,
  'getPercentile' : (arg_0: Principal, arg_1: Player) => Promise<[] | [number]>,
  'getRanking' : (arg_0: Principal, arg_1: Player) => Promise<[] | [bigint]>,
  'http_request' : (arg_0: HttpRequest) => Promise<HttpResponse>,
  'register' : (arg_0: Principal) => Promise<Result>,
  'registerGame' : (arg_0: Metadata) => Promise<undefined>,
}
export type Player = { 'plug' : string } |
  { 'stoic' : string };
export type Result = { 'ok' : null } |
  { 'err' : string };
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
