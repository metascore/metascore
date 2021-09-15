export const idlFactory = ({ IDL }) => {
  const GamePrincipal = IDL.Principal;
  const Metadata = IDL.Record({
    'name' : IDL.Text,
    'playUrl' : IDL.Text,
    'flavorText' : IDL.Opt(IDL.Text),
  });
  const Player = IDL.Variant({
    'plug' : IDL.Principal,
    'stoic' : IDL.Principal,
  });
  const Score = IDL.Tuple(Player, IDL.Nat);
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
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : IDL.Text });
  const Metascore = IDL.Service({
    'addAdmin' : IDL.Func([IDL.Principal], [], []),
    'cron' : IDL.Func([], [], []),
    'getGames' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(GamePrincipal, Metadata))],
        ['query'],
      ),
    'getMetascore' : IDL.Func([GamePrincipal, Player], [IDL.Nat], ['query']),
    'getOverallMetascore' : IDL.Func([Player], [IDL.Nat], ['query']),
    'getPercentile' : IDL.Func(
        [GamePrincipal, Player],
        [IDL.Opt(IDL.Float64)],
        ['query'],
      ),
    'getRanking' : IDL.Func(
        [GamePrincipal, Player],
        [IDL.Opt(IDL.Nat)],
        ['query'],
      ),
    'getTop' : IDL.Func([IDL.Nat], [IDL.Vec(Score)], ['query']),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'isAdmin' : IDL.Func([IDL.Principal], [IDL.Bool], ['query']),
    'register' : IDL.Func([GamePrincipal], [Result], []),
    'registerGame' : IDL.Func([Metadata], [], []),
    'removeAdmin' : IDL.Func([IDL.Principal], [], []),
    'scoreUpdate' : IDL.Func([IDL.Vec(Score)], [], []),
    'unregister' : IDL.Func([GamePrincipal], [], []),
  });
  return Metascore;
};
export const init = ({ IDL }) => { return []; };
