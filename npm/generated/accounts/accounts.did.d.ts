import type { Principal } from '@dfinity/principal';
export interface Account {
  'id' : AccountId,
  'alias' : [] | [string],
  'plugAddress' : [] | [Principal],
  'stoicAddress' : [] | [Principal],
  'primaryWallet' : Player,
  'flavorText' : [] | [string],
  'discord' : [] | [string],
  'avatar' : [] | [string],
}
export interface AccountDetails {
  'id' : AccountId,
  'alias' : [] | [string],
  'flavorText' : [] | [string],
  'avatar' : [] | [string],
}
export type AccountId = bigint;
export interface Accounts {
  'addAdmin' : (arg_0: Principal) => Promise<undefined>,
  'authenticateAccount' : (arg_0: AuthenticationRequest) => Promise<
      AuthenticationResponse
    >,
  'getAccount' : (arg_0: AccountId) => Promise<Result_1>,
  'getAccountByPrincipal' : (arg_0: Principal) => Promise<[] | [Account]>,
  'getAccountCount' : () => Promise<bigint>,
  'getAccountDetails' : (arg_0: AccountId) => Promise<Result>,
  'getAccountDetailsFromScores' : (arg_0: Array<Score__1>) => Promise<
      Array<DetailedScore>
    >,
  'getAccountsById' : (arg_0: bigint, arg_1: bigint) => Promise<Array<Account>>,
  'getAccountsFromScores' : (arg_0: Array<Score>) => Promise<Array<Score__1>>,
  'getNextId' : () => Promise<bigint>,
  'isAdmin' : (arg_0: Principal) => Promise<boolean>,
  'loadAccounts' : (arg_0: Array<Account>) => Promise<undefined>,
  'removeAdmin' : (arg_0: Principal) => Promise<undefined>,
  'setNextId' : (arg_0: bigint) => Promise<undefined>,
  'updateAccount' : (arg_0: UpdateRequest) => Promise<UpdateResponse>,
}
export type AuthenticationRequest = { 'authenticate' : Player } |
  { 'link' : [Player, Player] };
export type AuthenticationResponse = {
    'ok' : { 'message' : string, 'account' : Account }
  } |
  { 'err' : { 'message' : string } } |
  { 'forbidden' : null } |
  { 'pendingConfirmation' : { 'message' : string } };
export type DetailedScore = [AccountDetails, bigint];
export type Player = { 'plug' : Principal } |
  { 'stoic' : Principal };
export type Result = { 'ok' : AccountDetails } |
  { 'err' : null };
export type Result_1 = { 'ok' : Account } |
  { 'err' : null };
export type Score = [Player, bigint];
export type Score__1 = [AccountId, bigint];
export interface UpdateRequest {
  'alias' : [] | [string],
  'primaryWallet' : [] | [Player],
  'flavorText' : [] | [string],
  'discord' : [] | [string],
  'avatar' : [] | [string],
}
export type UpdateResponse = { 'ok' : Account } |
  { 'err' : string };
export interface _SERVICE extends Accounts {}
