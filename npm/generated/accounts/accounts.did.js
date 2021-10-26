export const idlFactory = ({ IDL }) => {
  const Player = IDL.Variant({
    'plug' : IDL.Principal,
    'stoic' : IDL.Principal,
  });
  const AuthenticationRequest = IDL.Variant({
    'authenticate' : Player,
    'link' : IDL.Tuple(Player, Player),
  });
  const AccountId = IDL.Nat;
  const Account = IDL.Record({
    'id' : AccountId,
    'alias' : IDL.Opt(IDL.Text),
    'plugAddress' : IDL.Opt(IDL.Principal),
    'stoicAddress' : IDL.Opt(IDL.Principal),
    'primaryWallet' : Player,
    'flavorText' : IDL.Opt(IDL.Text),
    'discord' : IDL.Opt(IDL.Text),
    'avatar' : IDL.Opt(IDL.Text),
  });
  const AuthenticationResponse = IDL.Variant({
    'ok' : IDL.Record({ 'message' : IDL.Text, 'account' : Account }),
    'err' : IDL.Record({ 'message' : IDL.Text }),
    'forbidden' : IDL.Null,
    'pendingConfirmation' : IDL.Record({ 'message' : IDL.Text }),
  });
  const Result_1 = IDL.Variant({ 'ok' : Account, 'err' : IDL.Null });
  const AccountDetails = IDL.Record({
    'id' : AccountId,
    'alias' : IDL.Opt(IDL.Text),
    'flavorText' : IDL.Opt(IDL.Text),
    'avatar' : IDL.Opt(IDL.Text),
  });
  const Result = IDL.Variant({ 'ok' : AccountDetails, 'err' : IDL.Null });
  const Score__1 = IDL.Tuple(AccountId, IDL.Nat);
  const DetailedScore = IDL.Tuple(AccountDetails, IDL.Nat);
  const Score = IDL.Tuple(Player, IDL.Nat);
  const UpdateRequest = IDL.Record({
    'alias' : IDL.Opt(IDL.Text),
    'primaryWallet' : IDL.Opt(Player),
    'flavorText' : IDL.Opt(IDL.Text),
    'discord' : IDL.Opt(IDL.Text),
    'avatar' : IDL.Opt(IDL.Text),
  });
  const UpdateResponse = IDL.Variant({ 'ok' : Account, 'err' : IDL.Text });
  const Accounts = IDL.Service({
    'addAdmin' : IDL.Func([IDL.Principal], [], []),
    'authenticateAccount' : IDL.Func(
        [AuthenticationRequest],
        [AuthenticationResponse],
        [],
      ),
    'getAccount' : IDL.Func([AccountId], [Result_1], ['query']),
    'getAccountByPrincipal' : IDL.Func([IDL.Principal], [IDL.Opt(Account)], []),
    'getAccountCount' : IDL.Func([], [IDL.Nat], ['query']),
    'getAccountDetails' : IDL.Func([AccountId], [Result], ['query']),
    'getAccountDetailsFromScores' : IDL.Func(
        [IDL.Vec(Score__1)],
        [IDL.Vec(DetailedScore)],
        ['query'],
      ),
    'getAccountsById' : IDL.Func([IDL.Nat, IDL.Nat], [IDL.Vec(Account)], []),
    'getAccountsFromScores' : IDL.Func(
        [IDL.Vec(Score)],
        [IDL.Vec(Score__1)],
        [],
      ),
    'getNextId' : IDL.Func([], [IDL.Nat], ['query']),
    'isAdmin' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'loadAccounts' : IDL.Func([IDL.Vec(Account)], [], []),
    'removeAdmin' : IDL.Func([IDL.Principal], [], []),
    'setNextId' : IDL.Func([IDL.Nat], [], []),
    'updateAccount' : IDL.Func([UpdateRequest], [UpdateResponse], []),
  });
  return Accounts;
};
export const init = ({ IDL }) => { return []; };
