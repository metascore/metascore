export const idlFactory = ({ IDL }) => {
  const GamePrincipal = IDL.Principal;
  const AccountId = IDL.Nat;
  const Score__1 = IDL.Tuple(AccountId, IDL.Nat);
  const AccountDetails = IDL.Record({
    'id' : AccountId,
    'alias' : IDL.Opt(IDL.Text),
    'flavorText' : IDL.Opt(IDL.Text),
    'avatar' : IDL.Opt(IDL.Text),
  });
  const DetailedScore = IDL.Tuple(AccountDetails, IDL.Nat);
  const Metadata = IDL.Record({
    'name' : IDL.Text,
    'playUrl' : IDL.Text,
    'flavorText' : IDL.Opt(IDL.Text),
  });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const StreamingCallbackToken = IDL.Record({
    'key' : IDL.Text,
    'sha256' : IDL.Opt(IDL.Vec(IDL.Nat8)),
    'index' : IDL.Nat,
    'content_encoding' : IDL.Text,
  });
  const StreamingCallbackHttpResponse = IDL.Record({
    'token' : IDL.Opt(StreamingCallbackToken),
    'body' : IDL.Vec(IDL.Nat8),
  });
  const StreamingStrategy = IDL.Variant({
    'Callback' : IDL.Record({
      'token' : StreamingCallbackToken,
      'callback' : IDL.Func(
          [StreamingCallbackToken],
          [StreamingCallbackHttpResponse],
          ['query'],
        ),
    }),
  });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'streaming_strategy' : IDL.Opt(StreamingStrategy),
    'status_code' : IDL.Nat16,
  });
  const Player = IDL.Variant({
    'plug' : IDL.Principal,
    'stoic' : IDL.Principal,
  });
  const Score = IDL.Tuple(Player, IDL.Nat);
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Metascore = IDL.Service({
    'addAdmin' : IDL.Func([IDL.Principal], [], []),
    'cron' : IDL.Func([], [], []),
    'drainScoreUpdateLog' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(GamePrincipal, Score__1))],
        ['query'],
      ),
    'getDetailedGameScores' : IDL.Func(
        [GamePrincipal, IDL.Opt(IDL.Nat), IDL.Opt(IDL.Nat)],
        [IDL.Vec(DetailedScore)],
        [],
      ),
    'getGameScores' : IDL.Func(
        [GamePrincipal, IDL.Opt(IDL.Nat), IDL.Opt(IDL.Nat)],
        [IDL.Vec(Score__1)],
        ['query'],
      ),
    'getGames' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(GamePrincipal, Metadata))],
        ['query'],
      ),
    'getPercentile' : IDL.Func(
        [GamePrincipal, AccountId],
        [IDL.Opt(IDL.Float64)],
        ['query'],
      ),
    'getPlayerCount' : IDL.Func([], [IDL.Nat], []),
    'getRanking' : IDL.Func(
        [GamePrincipal, AccountId],
        [IDL.Opt(IDL.Nat)],
        ['query'],
      ),
    'getScoreCount' : IDL.Func([], [IDL.Nat], ['query']),
    'getTop' : IDL.Func(
        [GamePrincipal, IDL.Nat],
        [IDL.Vec(Score__1)],
        ['query'],
      ),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'isAdmin' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'loadAccountScores' : IDL.Func([GamePrincipal, IDL.Vec(Score__1)], [], []),
    'loadGameScores' : IDL.Func([GamePrincipal, IDL.Vec(Score)], [], []),
    'loadGames' : IDL.Func(
        [IDL.Vec(IDL.Tuple(GamePrincipal, Metadata))],
        [],
        [],
      ),
    'queryGameScores' : IDL.Func([GamePrincipal], [], []),
    'register' : IDL.Func([GamePrincipal], [Result], []),
    'registerGame' : IDL.Func([Metadata], [], []),
    'removeAdmin' : IDL.Func([IDL.Principal], [], []),
    'scoreUpdate' : IDL.Func([IDL.Vec(Score)], [], []),
    'setAccountsCanister' : IDL.Func([IDL.Principal], [IDL.Principal], []),
    'unregister' : IDL.Func([GamePrincipal], [], []),
  });
  return Metascore;
};
export const init = ({ IDL }) => { return []; };
