clc; clear; close all;
addpath('./class')

if exist('result/symbolic_data.mat', 'file')
  disp('すでに計算結果が存在します。再計算しますか？ (y/n): ')
  data_regenerate_symbolic = input('', 's');
else
  data_regenerate_symbolic = 'y';
end

% シンボリック計算モード
if data_regenerate_symbolic == 'y'
  disp("計算を実行します。インセンティブ以外のパラメータは数値的に評価します。");
  policies = Policy.get_all_possible_policies();
  state_value_solutions = cell(length(policies), 1);
  expected_utility_solutions = cell(length(policies), 1);
  for i = 1:length(policies)
    policy = policies{i};
    fprintf('Policy %d: %s\n', i, policy.label);
    disp("STEP1: ベルマン方程式を解く");
    state_value_solution_symbolic = EquationStateValueFunction.solve_equations_bellman_with_policy_symbolic_except_params(policy, [])
    disp("STEP2: 期待効用方程式を解く");
    expected_utility_solution_symbolic = EquationExpectedUtility.solve_expected_utility_with_policy_symbolic_except_params(policy, [])
    state_value_solutions{i} = state_value_solution_symbolic;
    expected_utility_solutions{i} = expected_utility_solution_symbolic;
  end

  % シンボリック計算結果の保存
  if exist('result/symbolic_data.mat', 'file')
    delete('result/symbolic_data.mat');
  end
  save('result/symbolic_data.mat', 'state_value_solutions', 'expected_utility_solutions');
else
  data = load('result/symbolic_data.mat');
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;
end

