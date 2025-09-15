clc; clear; close all;
addpath('./class')
addpath('./class/solution')
warning('off', 'all');

target_data = 'result/symbolic_data.mat';

% 1. データの読み込み
if exist(target_data, 'file')
  fprintf('データを読み込みます\n');
  data = load(target_data);
  policies = Policy.get_all_possible_policies();
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;
  disp('データを読み込みました');
else
  error('データが存在しません');
end

variables = ParamsHelper.get_all_incentives_as_vector();

% 2. 各方策ごとに安定化可能条件の導出
for policy_index = 1:length(policies)
  policy = policies{policy_index};
  bp_stability_ineqs = MathUtils.expand_or_optimized( ...
    policy.bp_stability_condition(expected_utility_solutions) ...
  );
  disp(['policy', num2str(policy.index())]);
  fprintf('BP安定条件制約数: %d\n', length(bp_stability_ineqs));
  condition = symfalse;
  for i = 1:length(bp_stability_ineqs)
    incentive_eq = ParamsHelper.incentive_condition();
    bp_stability_ineq = bp_stability_ineqs{i};

    [A_eq, b_eq] = EqualityInequalityHelper.get_equality_matrix( ...
      variables, ...
      incentive_eq ...
    );
    [A_ineq, b_ineq] = EqualityInequalityHelper.get_inequality_matrix( ...
      variables, ...
      bp_stability_ineq ...
    );

    condition_ = EqualityInequalityHelper.get_mixed_feasibility_condition( ...
      A_eq, ...
      b_eq, ...
      A_ineq, ...
      b_ineq ...
    );

    condition = or(condition, condition_);

    if isAlways(condition)
      break; % 計算量を節約するため、常に成立するならばここで打ち切る
    end
  end
  fprintf('方策%dをインセンティブ安定化することが可能な条件: %s\n', policy_index, simplify(condition));
  pause;
  disp('-----------------------------');
end

% 3. 各方策ごとに自律的安定条件の導出
for policy_index = 1:length(policies)
  policy = policies{policy_index};
  bp_stability_ineqs = MathUtils.expand_or_optimized( ...
    policy.bp_stability_condition(expected_utility_solutions) ...
  );

  disp(['policy', num2str(policy.index())]);
  fprintf('BP安定条件制約数: %d\n', length(bp_stability_ineqs));
  condition = symfalse;
  for i = 1:length(bp_stability_ineqs)
    condition = or( ...
      condition, ...
      ParamsHelper.set_incentive_to_zero( ...
        subs(bp_stability_ineqs{i}, 'g', 0) ...
      ) ...
    );
  end
  
  fprintf('方策%dが自律的安定である条件: %s\n', policy_index, simplify(condition));
  disp('-----------------------------');
end
