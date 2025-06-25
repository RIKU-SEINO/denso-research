clc; clear; close all;
addpath('./class')
addpath('./func')

target_data = 'result/symbolic_data.mat';

% 1. 分析対象データの読み込み
if exist(target_data, 'file')
  data = load(target_data);
  policies = Policy.get_all_possible_policies();
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;
else
  error('データが存在しません');
end

% 2. 対象データの分析
for i = 1:length(policies)
  policy = policies{i};
  optimality_condition_ineq = policy.optimality_condition(state_value_solutions);
  bp_stability_condition_ineq = policy.bp_stability_condition(expected_utility_solutions);
  incentive_eq = ParamsHelper.incentive_condition();
  
  
end


