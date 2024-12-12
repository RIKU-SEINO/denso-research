addpath(genpath('./classes'));

% 乗客の出現確率ベクトル
p_i = [0.1; 0.2; 0.3];

% 遷移確率行列
p_jk = [
  0,   0.2, 0.8;
  0.4, 0,   0.6;
  0.7, 0.3, 0
];

% 遷移確率ベクトルを計算
transitionProbabilityVector = TransitionHelper.calculateTransitionProbabilityVector(p_i, p_jk);

% for situationNumber = 0:63
%   situation = Situation(situationNumber, "situationNumber");
%   a = situation.enumerateAllSituations(); 
%   fprintf('presencePair: %s -> %d\n', mat2str(situation.presencePair), length(a));
% end

situationNumber = 1;
situation = Situation(situationNumber, "situationNumber");

[reachableSituations, transition] = situation.enumerateAllSituations();
