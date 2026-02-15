clc; clear; close all;
addpath('./class')
addpath('./class/solution')
warning('off', 'all');

%%%% EDIT HERE %%%%
target_data = 'result/symbolic_data.mat';
params_to_evaluate = {'g', 'p_2', 'p_3'}; % 数値的に評価するパラメータを文字列のcell配列で指定。
%%%%%%%%%%%%%%%%%%%

% 1. データの読み込み
if exist(target_data, 'file')
  fprintf('データを読み込みます\n');
  data = load(target_data);
  policies = Policy.get_all_possible_policies();
  state_value_solutions = data.state_value_solutions;
  disp('データを読み込みました');
else
  error('データが存在しません');
end

% 2. パラメータを数値的に評価したSolutionを作成する
fprintf('パラメータを数値的に評価したSolutionを作成します\n');
for i = 1:length(policies)
  state_value_solutions{i} = state_value_solutions{i}.eval_params(params_to_evaluate);
end
fprintf('パラメータを数値的に評価したSolutionを作成しました\n');

% 3. 各方策ごとの最適性条件の導出
variables = ParamsHelper.get_all_incentives_as_vector();
for policy_index = 1:length(policies)
  policy = policies{policy_index};
  optimality_condition = policy.optimality_condition(state_value_solutions);
  disp(['policy', num2str(policy.index())]);

  % 状態価値関数はインセンティブ収支制約を適用するとインセンティブが消えるので、それを適用して簡略化する
  [incentive_eq, incentive_ineq] = ParamsHelper.incentive_condition(policy, true);
  state_value_solutions{policy_index} = state_value_solutions{policy_index}.apply_incentive_eq( ...
    incentive_eq ...
  );

  [A_eq, b_eq] = EqualityInequalityHelper.get_equality_matrix( ...
    variables, ...
    incentive_eq ...
  );

  [A_ineq, b_ineq] = EqualityInequalityHelper.get_inequality_matrix( ...
    variables, ...
    and(optimality_condition, incentive_ineq) ...
  );

  [A_reduced, b_reduced] = EqualityInequalityHelper.get_reduced_matrix( ...
    A_eq, ...
    b_eq, ...
    A_ineq, ...
    b_ineq ...
  );

  condition = ...
    EqualityInequalityHelper.get_inequality_feasibility_condition_MPT3( ...
      A_reduced, ...
      b_reduced ...
    );
  
  % 結果の表示
  fprintf('方策%dの最適性条件:\n', policy_index);
  % もし、conditionが全てsymtrueなら無条件
  if all(isAlways(condition))
    fprintf('  無条件で実行可能\n');
  % もし、conditionの中にsymfalseがあれば実行不可能
  elseif any(isAlways(~condition))
    fprintf('  実行不可能\n');
  else
    fprintf('  （以下すべてを満たす - AND結合）:\n');
    for cond_index = 1:length(condition)
      disp(EqualityInequalityHelper.normalize_inequality(condition(cond_index), 'c', 3));
    end
  end

  disp('-----------------------------');
  pause;
end
