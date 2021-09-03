export const idlFactory = ({ IDL }) => {
  const Player = IDL.Variant({ 'plug' : IDL.Text, 'stoic' : IDL.Text });
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
  const Metadata = IDL.Record({ 'name' : IDL.Text });
  const Metascore = IDL.Service({
    'cron' : IDL.Func([], [], []),
    'getGameScoreComponent' : IDL.Func(
        [IDL.Principal, Player],
        [IDL.Opt(IDL.Nat)],
        ['query'],
      ),
    'getMetascore' : IDL.Func([Player], [IDL.Nat], ['query']),
    'getOverallRanking' : IDL.Func(
        [IDL.Principal],
        [IDL.Vec(Player)],
        ['query'],
      ),
    'getPercentile' : IDL.Func(
        [IDL.Principal, Player],
        [IDL.Opt(IDL.Float64)],
        ['query'],
      ),
    'getRanking' : IDL.Func(
        [IDL.Principal, Player],
        [IDL.Opt(IDL.Nat)],
        ['query'],
      ),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'register' : IDL.Func([IDL.Principal], [Result], []),
    'registerGame' : IDL.Func([Metadata], [], []),
  });
  return Metascore;
};
export const init = ({ IDL }) => { return []; };
