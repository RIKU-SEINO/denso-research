clc; clear; close all;
addpath('./class')
addpath('./class/solution')
addpath('./class/visualizer')

%%%% EDIT HERE %%%%
stability_type = 'BP'; % 'BP' または 'EBP'
policy_index = 8;
use_positive_incentive_condition = true; % マッチしないプレイヤに対して、インセンティブが0以上であることを制約する場合は true, そうでない場合は false
mode = 'optimal_value_projection'; % 'fixed_value_projection' または 'optimal_value_projection'
if use_positive_incentive_condition
  with_or_without = 'with_positive_incentive_cons';
else
  with_or_without = 'without_positive_incentive_cons';
end

if strcmp(mode, 'fixed_value_projection')
  target_optimizer_data = sprintf( ...
    'result/optimizer/policy_%d_%s_%s.mat', ...
    policy_index, ...
    with_or_without, ...
    'EBP' ...
  );
  plot_default_point = false;
elseif strcmp(mode, 'optimal_value_projection')
  target_optimizer_data = sprintf( ...
    'result/optimizer/policy_%d_%s_%s.mat', ...
    policy_index, ...
    with_or_without, ...
    stability_type ...
  );
  plot_default_point = true;
else
  error('mode が不正です: %s', mode);
end
target_symbolic_data = 'result/symbolic_data.mat';
target_plot_dimensions = [3, 5, 7];
plot_bound = 500; % 描画範囲の最大値（絶対値）
label_offset = 550; % 軸線からラベルを離す距離

target_plot_incentives = ...
  ParamsHelper.get_incentives_as_vector(target_plot_dimensions);
target_plot_incentives_latex_labels = cell(1, length(target_plot_incentives));
for i = 1:length(target_plot_incentives)
  [player, player_set] = ...
    ParamsHelper.get_player_and_player_set_from_incentive(target_plot_incentives(i));
  target_plot_incentives_latex_labels{i} = ...
    ParamsHelper.incentive_latex_label(player_set, player);
end
%%%%%%%%%%%%%%%%%%%

% 1. データの読み込み
if exist(target_symbolic_data, 'file') && exist(target_optimizer_data, 'file')
  fprintf('シンボリックデータと最適化データを読み込みます\n');
  data = load(target_symbolic_data);
  policies = Policy.get_all_possible_policies();
  state_value_solutions = data.state_value_solutions;
  expected_utility_solutions = data.expected_utility_solutions;

  optimizer_data = load(target_optimizer_data);
  result = optimizer_data.result;
  disp('シンボリックデータと最適化データを読み込みました');
else
  error('シンボリックデータまたは最適化データが存在しません');
end

% 2. パラメータを数値的に評価したSolutionを作成する
fprintf('パラメータを数値的に評価したSolutionを作成します\n');
for i = 1:length(policies)
  state_value_solutions{i} = state_value_solutions{i}.eval_all_params();
  expected_utility_solutions{i} = expected_utility_solutions{i}.eval_all_params();
end
fprintf('パラメータを数値的に評価したSolutionを作成しました\n');

% 3. 可視化の準備
variables = ParamsHelper.get_all_incentives_as_vector();
n = length(variables);

policy = policies{policy_index};

% 制約条件1. policyが安定となるための不等式制約
% ※ ここで複数の式（OR条件）が返ってくる可能性があります
stability_ineqs = MathUtils.expand_or_optimized( ...
  policy.stability_condition(stability_type, expected_utility_solutions) ...
);

% 制約条件2. インセンティブの収支を満たすための等式制約
[incentive_eq, incentive_ineq] = ParamsHelper.incentive_condition( ...
  policy, ...
  use_positive_incentive_condition ...
);

% 4. Visualizerの設定と描画
viz = ConstraintVisualizer(n, result.x);
viz.ObjectiveFunction = @(x) sum(x.^2, 2);

% stability_ineqs の各要素を個別に addInequalitySet することで、
% Visualizer側でこれらを「OR条件（和集合）」として重ねて描画させます。
for j = 1:length(stability_ineqs)
  [A, b] = EqualityInequalityHelper.get_inequality_matrix( ...
    variables, ...
    and(stability_ineqs{j}, incentive_ineq) ...
  );
  viz = viz.addInequalitySet(double(A), double(b));
end

% --- 等式制約の登録 ---
[A_eq_total, b_eq_total] = EqualityInequalityHelper.get_equality_matrix(variables, incentive_eq);
A_eq_total = double(A_eq_total);
b_eq_total = double(b_eq_total);

% 係数が全て0の行（無意味な制約）を削除
zero_rows = all(A_eq_total == 0, 2);
A_eq_total(zero_rows, :) = [];
b_eq_total(zero_rows) = [];

if ~isempty(A_eq_total)
  viz = viz.setEquality(A_eq_total, b_eq_total);
end

viz.plot(target_plot_dimensions, ...
    'AutoUpdateLabelPosition', true, ... % 回転時にラベル位置を自動更新
    'LabelOffset', 80, ... % 軸の端からの距離 (枠線からのオフセット)
    'PlotDefaultPoint', plot_default_point, ... % 最適解マークを描画するか
    'XLabel', target_plot_incentives_latex_labels{1}, ... % x軸のラベル（LaTeX記法）
    'YLabel', target_plot_incentives_latex_labels{2}, ... % y軸のラベル（LaTeX記法）
    'ZLabel', target_plot_incentives_latex_labels{3}, ... % z軸のラベル（LaTeX記法）
    'DefaultPointMarker', '*', ... % 最適解マーク
    'DefaultPointSize', 250, ...
    'DefaultPointLineWidth', 2.5, ...
    'DefaultPointAlwaysOnTop', true, ...
    'DefaultPointDepthOffset', 10, ... % カメラ方向に少しだけ手前へ（必要なら調整）
    'XLim', [-plot_bound, plot_bound], ... % x軸の範囲
    'YLim', [-plot_bound, plot_bound], ... %y軸の範囲
    'ZLim', [-plot_bound, plot_bound], ... % z軸の範囲
    'Bounds', plot_bound, ...  % 変数範囲の最大値
    'ContourLevels', 250, ...  % カラーマップの段階数
    'ColorbarLimits', [0, 5e5], ...  % カラーバー（=目的関数）の数値範囲
    'ColorbarLabel', 'objective-value');  % カラーバーのラベル

% --- Save .fig ---
stability_tag = lower(stability_type);
filename_base = sprintf('pi_%d_%s', policy_index, stability_tag);
if use_positive_incentive_condition
  filename_base = [filename_base, '_positive_cons'];
end
filename_base = [filename_base, '_', mode];

viz.save( ...
  'BaseName', filename_base, ...
  'Directory', 'result/visualizer' ...
);