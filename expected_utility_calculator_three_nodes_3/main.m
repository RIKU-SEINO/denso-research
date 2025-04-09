clc; clear;
addpath('./class')
addpath('./func')

% 1. 最適状態価値関数方程式(=ベルマン方程式)を数値的に解く
disp('最適状態価値関数方程式の解を数値的に計算します...');
optimal_state_value_solution = EquationStateValueFunction.solve_equations();
optimal_policy = Policy.get_policy_from_optimal_state_value_solution(optimal_state_value_solution);

% 2. すべてのpolicy(=方策）ごとに、状態価値関数方程式を解く
disp('すべてのpolicyごとに、状態価値関数方程式を解きます...');
policies = Policy.get_all_possible_policies();
state_value_solutions = cell(length(policies), 1);
expected_utility_solutions = cell(length(policies), 1);
is_optimal = false(length(policies), 1);
for i = 1:length(policies)
  policy = policies{i};
  fprintf('Policy %d: %s\n', i, policy.label);
  state_value_solution = EquationStateValueFunction.solve_equations_numeric_with_policy(policy);
  expected_utility_solution = EquationExpectedUtility.solve_equations_numeric_with_policy(policy);
  state_value_solutions{i} = state_value_solution;
  expected_utility_solutions{i} = expected_utility_solution;
  if isequal(policy, optimal_policy)
    is_optimal(i) = true;
  end
end

% 3. 結果の表示
% 3-1. プレイヤ集合の状態価値関数をグラフとして表示
ResultVisualizer.display_state_values_as_graphs(state_value_solutions, policies, is_optimal);

% 3-2. プレイヤ集合の状態価値関数を棒グラフとして表示
ResultVisualizer.display_state_values_as_bar(state_value_solutions, is_optimal);

% 3-3. プレイヤ/プレイヤ集合の期待効用をグラフとして表示
ResultVisualizer.display_expected_utilities_as_bar(expected_utility_solutions, is_optimal);