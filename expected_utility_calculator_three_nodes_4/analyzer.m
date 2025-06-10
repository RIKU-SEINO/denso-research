clc; clear; close all;
addpath('./class')
addpath('./func')

target_datas = {...
  'result/data.mat', ...
  'result_g_000/data.mat', ...
  'result_g_095/data.mat', ...
  'result/symbolic_data.mat'};

% 0. 分析対象データの選択
disp('分析対象データを選択してください:');
for i = 1:length(target_datas)
  fprintf('%d: %s\n', i, target_datas{i});
end
target_data_index = input('データを選択 (1/2/3/4): ');
if ismember(target_data_index, [1, 2, 3])
  is_symbolic = false;
else
  is_symbolic = true;
end

% 1. 分析対象データの読み込み
if exist(target_datas{target_data_index}, 'file')
  data = load(target_datas{target_data_index});
  policies = Policy.get_all_possible_policies();
  if is_symbolic
    state_value_solutions = data.state_value_solutions_symbolic;
    expected_utility_solutions = data.expected_utility_solutions_symbolic;
  else
    optimal_state_value_solution = data.optimal_state_value_solution;
    optimal_policy = data.optimal_policy;
    is_optimal = data.is_optimal;
    state_value_solutions = data.state_value_solutions;
    expected_utility_solutions = data.expected_utility_solutions;
  end
else
  error('データが存在しません');
end

% 2. 対象データの分析
for i = 1:length(policies)
  policy = policies{i};
  bp_stability_condition_expr = policy.bp_stability_condition(expected_utility_solutions);
  if is_symbolic
    disp('------ Plotting BP stability region ------');
    title_str = ['BP stability region of \pi_{', num2str(policy.index()), '}'];
    Utils.plot_inequality_region_with_inputs( ...
      bp_stability_condition_expr, ...
      ParamsHelper.all_symbolic_params(), ...
      ParamsHelper.all_valued_params(), ...
      ParamsHelper.params_condition(), ...
      [0, 1], [0, 1], ...
      'p_2', 'p_3', ...
      title_str, ...
      'Always BP-stable', ...
      'Never BP-stable', ...
      500 ...
    );
  else
    disp('------ Checking BP stability ------');
    if bp_stability_condition_expr == symtrue
      fprintf('policy: %d is BP stable\n', policy.index());
    else
      fprintf('policy: %d is not BP stable\n', policy.index());
    end
  end
  disp('-----------------------------');
end


