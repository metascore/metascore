export const idlFactory = ({ IDL }) => {
  const GameCanRecord = IDL.Principal;
  const Player = IDL.Variant({ 'plug' : IDL.Text, 'stoic' : IDL.Text });
  const Score = IDL.Nat;
  const Percentile = IDL.Float64;
  const RegistrationResponse = IDL.Variant({
    'ok' : IDL.Text,
    'err' : IDL.Variant({
      'notfound' : IDL.Record({}),
      'invalidresponse' : IDL.Record({}),
    }),
  });
  const Metascore = IDL.Service({
    'canister_heartbeat' : IDL.Func([], [], []),
    'getGameCans' : IDL.Func([], [IDL.Vec(GameCanRecord)], ['query']),
    'getPlayerMetascores' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(Player, GameCanRecord, Score))],
        ['query'],
      ),
    'getPlayerPercentiles' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(Player, GameCanRecord, Percentile))],
        ['query'],
      ),
    'getPlayerScores' : IDL.Func(
        [],
        [IDL.Vec(IDL.Tuple(Player, GameCanRecord, Score))],
        ['query'],
      ),
    'queryAllGameCans' : IDL.Func([], [], []),
    'registerGameCan' : IDL.Func([GameCanRecord], [RegistrationResponse], []),
  });
  return Metascore;
};
export const init = ({ IDL }) => { return []; };
