clc; clear;
addpath('./class')
addpath('./func')

if exist('result_g_095/data.mat', 'file')
  data = load('result_g_095/data.mat');
  policies = Policy.get_all_possible_policies();
  optimal_state_value_solution = data.optimal_state_value_solution;
  optimal_policy = data.optimal_policy;
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;
  is_optimal = data.is_optimal;
else
  error('result_g_095/data.matが存在しません');
end

for i = 1:length(policies)
  policy = policies{i};
  bp_stability_condition_expr = policy.bp_stability_condition(expected_utility_solutions);
  disp('------ Stability Check ------');
  if bp_stability_condition_expr == symtrue
    fprintf('policy: %d is BP stable\n', policy.index());
  else
    fprintf('policy: %d is not BP stable\n', policy.index());
  end
  disp('-----------------------------');
end


