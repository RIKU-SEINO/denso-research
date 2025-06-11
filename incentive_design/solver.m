clc; clear; close all;
addpath('./class')
addpath('./func')
mkdir 'result'
mkdir 'func'

% 0. 計算モードの選択
disp('計算モードを選択してください:');
disp('1: 数値計算モード');
disp('2: シンボリック計算モード');
disp('3: 両方実行');
calc_mode = input('モードを選択 (1/2/3): ');

% 0-1. すでに計算結果がある場合はロードする（数値計算モードの場合）
if exist('result/data.mat', 'file')
  disp('すでに数値計算結果が存在します。再計算しますか？ (y/n): ')
  data_regenerate_numeric = input('', 's');
else
  data_regenerate_numeric = 'y';
end

if exist('result/symbolic_data.mat', 'file')
  disp('すでにシンボリック計算結果が存在します。再計算しますか？ (y/n): ')
  data_regenerate_symbolic = input('', 's');
else
  data_regenerate_symbolic = 'y';
end

% 数値計算モード
if calc_mode == 1 || calc_mode == 3
  % 1. ベルマン最適方程式を数値的に解く
  if data_regenerate_numeric == 'y'
    disp('数値計算結果を再生成します。');
    disp("STEP1: ベルマン最適方程式を数値的に解く");
    optimal_state_value_solution = EquationStateValueFunction.solve_bellman_optimal_numeric()
    optimal_policy = Policy.get_policy_from_optimal_state_value_solution(optimal_state_value_solution);

    % 2. 全ての方策ごとに、ベルマン方程式と期待効用方程式を解く
    disp("STEP2: 全ての方策ごとに、ベルマン方程式と期待効用方程式を数値的に解く");
    policies = Policy.get_all_possible_policies();
    state_value_solutions = cell(length(policies), 1);
    expected_utility_solutions = cell(length(policies), 1);
    is_optimal = false(length(policies), 1);
    for i = 1:length(policies)
      policy = policies{i};
      fprintf('Policy %d: %s\n', i, policy.label);
      disp("STEP2-1: ベルマン方程式を数値的に解く");
      state_value_solution = EquationStateValueFunction.solve_bellman_with_policy_numeric(policy)
      disp("STEP2-2: 期待効用方程式を数値的に解く");
      expected_utility_solution = EquationExpectedUtility.solve_expected_utility_with_policy_numeric(policy)
      state_value_solutions{i} = state_value_solution;
      expected_utility_solutions{i} = expected_utility_solution;
      if isequal(policy, optimal_policy)
        is_optimal(i) = true;
      end
    end

    % 3. 結果の保存
    if exist('result/data.mat', 'file')
      delete('result/data.mat');
    end
    save('result/data.mat', 'optimal_state_value_solution', 'optimal_policy', 'state_value_solutions', 'expected_utility_solutions', 'is_optimal');
  else
    data = load('result_g_095/data.mat');
    policies = Policy.get_all_possible_policies();
    optimal_state_value_solution = data.optimal_state_value_solution;
    optimal_policy = data.optimal_policy;
    state_value_solutions = data.state_value_solutions;
    expected_utility_solutions = data.expected_utility_solutions;
    is_optimal = data.is_optimal;
  end
end

% シンボリック計算モード
if calc_mode == 2 || calc_mode == 3
  if data_regenerate_symbolic == 'y'
    disp("シンボリック計算モードを実行します。");
    policies = Policy.get_all_possible_policies();
    state_value_solutions_symbolic = cell(length(policies), 1);
    expected_utility_solutions_symbolic = cell(length(policies), 1);
    for i = 1:length(policies)
      policy = policies{i};
      fprintf('Policy %d: %s\n', i, policy.label);
      disp("STEP1: ベルマン方程式をシンボリックに解く");
      state_value_solution_symbolic = EquationStateValueFunction.solve_equations_bellman_with_policy_symbolic(policy)
      disp("STEP2: 期待効用方程式をシンボリックに解く");
      expected_utility_solution_symbolic = EquationExpectedUtility.solve_expected_utility_with_policy_symbolic(policy)
      state_value_solutions_symbolic{i} = state_value_solution_symbolic;
      expected_utility_solutions_symbolic{i} = expected_utility_solution_symbolic;
    end
  
    % シンボリック計算結果の保存
    if exist('result/symbolic_data.mat', 'file')
      delete('result/symbolic_data.mat');
    end
    save('result/symbolic_data.mat', 'state_value_solutions_symbolic', 'expected_utility_solutions_symbolic');
  else
    data = load('result_g_095/symbolic_data.mat');
    state_value_solutions_symbolic = data.state_value_solutions_symbolic;
    expected_utility_solutions_symbolic = data.expected_utility_solutions_symbolic;
  end
end

% 4. 数値計算結果の表示（数値計算モードが選択された場合のみ）
if calc_mode == 1 || calc_mode == 3
  % 4-1. プレイヤ集合の状態価値関数をグラフとして表示
  ResultVisualizer.display_state_values_as_graphs(state_value_solutions, policies, is_optimal);

  % 4-2. プレイヤ集合の状態価値関数を棒グラフとして表示
  ResultVisualizer.display_state_values_as_bar(state_value_solutions, is_optimal);

  % 4-3. プレイヤ/プレイヤ集合の期待効用をグラフとして表示
  ResultVisualizer.display_expected_utilities_as_bar(expected_utility_solutions, is_optimal);
end

% % 5. シンボリック計算結果の表示（シンボリック計算モードが選択された場合のみ）
% if calc_mode == 2 || calc_mode == 3
%   ResultVisualizer.display_max_state_value_with_policy_color_p2_p3(state_value_solutions_symbolic);
% end

