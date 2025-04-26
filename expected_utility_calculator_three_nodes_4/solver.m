clc; clear;
addpath('./class')
addpath('./func')
mkdir 'result'
mkdir 'func'

% 0. すでに計算結果がある場合はロードする
if exist('result/data.mat', 'file')
  disp('すでに計算結果が存在します。計算を続行しますか？ (y/n): ')
  data_regenerate = input('', 's');
else
  data_regenerate = 'y';
end

% 1. ベルマン最適方程式を数値的に解く
if data_regenerate == 'y'
  disp('計算結果を再生成します。');
  disp("STEP1: ベルマン最適方程式を数値的に解く");
  optimal_state_value_solution = EquationStateValueFunction.solve_bellman_optimal_numeric()
  optimal_policy = Policy.get_policy_from_optimal_state_value_solution(optimal_state_value_solution);

  % 2. 全ての方策ごとに、ベルマン方程式と期待効用方程式を解く
  disp("STEP2: 全ての方策ごとに、ベルマン方程式と期待効用方程式を解く");
  policies = Policy.get_all_possible_policies();
  state_value_solutions = cell(length(policies), 1);
  expected_utility_solutions = cell(length(policies), 1);
  is_optimal = false(length(policies), 1);
  for i = 1:length(policies)
    policy = policies{i};
    fprintf('Policy %d: %s\n', i, policy.label);
    disp("STEP2-1: ベルマン方程式を解く");
    state_value_solution = EquationStateValueFunction.solve_bellman_with_policy_numeric(policy)
    disp("STEP2-2: 期待効用方程式を解く");
    expected_utility_solution = EquationExpectedUtility.solve_expected_utility_with_policy_numeric(policy)
    state_value_solutions{i} = state_value_solution;
    expected_utility_solutions{i} = expected_utility_solution;
    if isequal(policy, optimal_policy)
      is_optimal(i) = true;
    end
  end

  % 3. 結果の保存
  delete('result/data.mat');
  save('result/data.mat', 'optimal_state_value_solution', 'optimal_policy', 'state_value_solutions', 'expected_utility_solutions', 'is_optimal');
else
  data = load('result/data.mat');
  policies = Policy.get_all_possible_policies();
  optimal_state_value_solution = data.optimal_state_value_solution;
  optimal_policy = data.optimal_policy;
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;
  is_optimal = data.is_optimal;
end

% 4. 結果の表示
% 4-1. プレイヤ集合の状態価値関数をグラフとして表示
ResultVisualizer.display_state_values_as_graphs(state_value_solutions, policies, is_optimal);

% 4-2. プレイヤ集合の状態価値関数を棒グラフとして表示
ResultVisualizer.display_state_values_as_bar(state_value_solutions, is_optimal);

% 4-3. プレイヤ/プレイヤ集合の期待効用をグラフとして表示
ResultVisualizer.display_expected_utilities_as_bar(expected_utility_solutions, is_optimal);
