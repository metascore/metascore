export const idlFactory = ({ IDL }) => {
  const Metadata = IDL.Record({ 'name' : IDL.Text });
  const RegisterCallback = IDL.Func([Metadata], [], []);
  const Player = IDL.Variant({ 'plug' : IDL.Text, 'stoic' : IDL.Text });
  const Score = IDL.Tuple(Player, IDL.Nat);
  const Scores = IDL.Vec(Score);
  const Game = IDL.Service({
    'metascoreRegisterSelf' : IDL.Func([RegisterCallback], [], []),
    'metascoreScores' : IDL.Func([], [Scores], ['query']),
  });
  return Game;
};
export const init = ({ IDL }) => { return []; };
