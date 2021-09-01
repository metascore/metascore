export const idlFactory = ({ IDL }) => {
  const Player = IDL.Variant({ 'plug' : IDL.Text, 'stoic' : IDL.Text });
  const Score = IDL.Nat;
  const ScoreDump = IDL.Vec(IDL.Tuple(Player, Score));
  return IDL.Service({ 'metascoreDump' : IDL.Func([], [ScoreDump], []) });
};
export const init = ({ IDL }) => { return []; };
