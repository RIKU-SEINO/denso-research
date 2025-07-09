clc; clear; close all;
addpath('./class')

target_data = 'result/symbolic_data.mat';

% 1. データの読み込み
if exist(target_data, 'file')
  fprintf('データを読み込みます\n');
  data = load(target_data);
  policies = Policy.get_all_possible_policies();
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;
else
  error('データが存在しません');
end

variables = ParamsHelper.get_all_incentives_as_vector();

% 2. 最適化問題の実行
for i = 1:length(policies)
  policy = policies{i};
  % 制約条件1. policyが最適方策となるための不等式制約
  optimality_ineq = policy.optimality_condition(state_value_solutions);
  % 制約条件2. policyがBP安定となるための不等式制約
  bp_stability_ineqs = MathUtils.expand_or_optimized( ...
    policy.bp_stability_condition(expected_utility_solutions) ...
  );
  % 制約条件3. インセンティブの収支を満たすための等式制約
  incentive_eq = ParamsHelper.incentive_condition();

  % 目的関数
  state_value_solution = state_value_solutions{i};
  f_sym = sum(cellfun(@(x) x, struct2cell(state_value_solution)));

  fprintf('方策%dについてインセンティブ最適化を行います\n', i);
  problems = cell(length(bp_stability_ineqs), 1);
  for j = 1:length(bp_stability_ineqs)
    ineq = and(optimality_ineq, bp_stability_ineqs{j});
    problems{j} = OptimizationProblem( ...
      variables, ... % 説明変数
      f_sym, ... % 目的関数
      false, ... % falseなので最大化問題
      incentive_eq, ... % 等式制約条件
      ineq ... % 不等式制約条件
    );
  end
  result = OptimizationProblem.execute_linprog_all(problems);
  OptimizationProblem.show_result(variables, result);
end


