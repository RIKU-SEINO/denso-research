clc; clear; close all;
addpath('./class')
addpath('./class/solution')

%%%% EDIT HERE %%%%
target_data = 'result/symbolic_data.mat';
stability_type = 'EBP'; % 'BP' または 'EBP' のいずれか
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
  state_value_solutions{i} = state_value_solutions{i}.eval_all_params();
  expected_utility_solutions{i} = expected_utility_solutions{i}.eval_all_params();
end
fprintf('パラメータを数値的に評価したSolutionを作成しました\n');

% 3. 最適化問題の実行
variables = ParamsHelper.get_all_incentives_as_vector(); % 決定変数
f_sym = sum(arrayfun(@(x) x^2, variables)); % 目的関数
for i = 8:length(policies)
  policy = policies{i};
  % 制約条件1. policyが最適方策となるための不等式制約
  optimality_ineq = policy.optimality_condition(state_value_solutions);
  % 制約条件2. policyが安定となるための不等式制約
  stability_ineqs = MathUtils.expand_or_optimized( ...
    policy.stability_condition(stability_type, expected_utility_solutions) ...
  );
  % 制約条件3. インセンティブの収支を満たすための等式制約
  incentive_eq = ParamsHelper.incentive_condition();

  fprintf('方策%dについてインセンティブ最適化を行います\n', i);
  problems = cell(length(stability_ineqs), 1);
  for j = 1:length(stability_ineqs)
    ineq = and(optimality_ineq, stability_ineqs{j});
    problems{j} = OptimizationProblem( ...
      variables, ... % 決定変数
      f_sym, ... % 目的関数
      true, ... % trueなので最小化問題
      incentive_eq, ... % 等式制約条件
      ineq ... % 不等式制約条件
    );
  end
  result = OptimizationProblem.execute_all(problems, 'fmincon');
  OptimizationProblem.show_result(variables, result);

  if OptimizationProblem.is_success(result)
    incentive_solution = Solution.to_solution(variables, result.x);
    % 最適化されたインセンティブを用いて、全ての方策について期待効用を計算する
    evaluated_expected_utility_solutions_without_incentive = cell(length(policies), 1);
    evaluated_expected_utility_solutions_with_optimized_incentive = cell(length(policies), 1);
    for j = 1:length(policies)
      evaluated_expected_utility_solutions_without_incentive{j} = ...
        expected_utility_solutions{j}.set_incentive_to_zero();

      evaluated_expected_utility_solutions_with_optimized_incentive{j} = ...
        expected_utility_solutions{j}.eval_by_solution(incentive_solution);
    end
    ExpectedUtilitySolution.visualize(evaluated_expected_utility_solutions_without_incentive);
    ExpectedUtilitySolution.visualize(evaluated_expected_utility_solutions_with_optimized_incentive);

    fprintf('最適化されたインセンティブを用いて、全ての方策について期待効用を計算しました\n');
    fprintf('次の方策に進む場合は、Enterキーを押してください\n');
    pause;
  end
end


