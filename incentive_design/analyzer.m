clc; clear; close all;
addpath('./class')
addpath('./class/solution')
warning('off', 'all');

%%%% EDIT HERE %%%%
target_data = 'result/symbolic_data.mat';
stability_type = 'EBP'; % 'BP' または 'EBP' のいずれか
should_analyze_stabilizability = true; % 安定化可能条件の導出を行うかどうか
should_analyze_self_stability = true; % 自律的安定条件の導出を行うかどうか
params_to_evaluate = {'g'}; % 数値的に評価するパラメータを文字列のcell配列で指定。
%%%%%%%%%%%%%%%%%%%

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

% 2. パラメータを数値的に評価したSolutionを作成する
fprintf('パラメータを数値的に評価したSolutionを作成します\n');
for i = 1:length(policies)
  state_value_solutions{i} = state_value_solutions{i}.eval_params(params_to_evaluate);
  expected_utility_solutions{i} = expected_utility_solutions{i}.eval_params(params_to_evaluate);
end
fprintf('パラメータを数値的に評価したSolutionを作成しました\n');

% 3. 各方策ごとに安定化可能条件の導出
if should_analyze_stabilizability
  variables = ParamsHelper.get_all_incentives_as_vector();
  for policy_index = 1:length(policies)
    policy = policies{policy_index};
    stability_ineqs = MathUtils.expand_or_optimized( ...
      policy.stability_condition(stability_type, expected_utility_solutions) ...
    );
    disp(['policy', num2str(policy.index())]);
    fprintf('安定条件制約数: %d\n', length(stability_ineqs));
    condition = symfalse;
    for i = 1:length(stability_ineqs)
      incentive_eq = ParamsHelper.incentive_condition();
      stability_ineq = stability_ineqs{i};

      [A_eq, b_eq] = EqualityInequalityHelper.get_equality_matrix( ...
        variables, ...
        incentive_eq ...
      );
      [A_ineq, b_ineq] = EqualityInequalityHelper.get_inequality_matrix( ...
        variables, ...
        stability_ineq ...
      );

      fprintf('Fourier-Motzkin消去法を用いて、不等式制約の可解条件を導出します\n');
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
    disp('-----------------------------');
  end
end

% 4. 各方策ごとに自律的安定条件の導出
if should_analyze_self_stability
  for policy_index = 1:length(policies)
    policy = policies{policy_index};
    stability_ineqs = MathUtils.expand_or_optimized( ...
      policy.stability_condition(stability_type, expected_utility_solutions) ...
    );

    disp(['policy', num2str(policy.index())]);
    fprintf('安定条件制約数: %d\n', length(stability_ineqs));
    condition = symfalse;
    for i = 1:length(stability_ineqs)
      condition = or( ...
        condition, ...
        ParamsHelper.set_incentive_to_zero(stability_ineqs{i}) ...
      );
    end
    
    fprintf('方策%dが自律的安定である条件: %s\n', policy_index, simplify(condition));
    disp('-----------------------------');
  end
end
