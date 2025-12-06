clc; clear;
addpath('./class')
addpath('./class/solution')
addpath('./class/visualizer')

%%%% EDIT HERE %%%%
target_data = 'result/symbolic_data.mat';
stability_type = 'EBP'; % 'BP' または 'EBP'
policy_index = 8;
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

% 3. 可視化の準備
variables = ParamsHelper.get_all_incentives_as_vector();
n = length(variables);

policy = policies{policy_index};

% 制約条件1. policyが安定となるための不等式制約
% ※ ここで複数の式（OR条件）が返ってくる可能性があります
stability_ineqs = MathUtils.expand_or_optimized( ...
  policy.stability_condition('EBP', expected_utility_solutions) ...
);

% 制約条件2. インセンティブの収支を満たすための等式制約
incentive_eq = ParamsHelper.incentive_condition();

% デフォルト値の設定
default_vals = [
  -88.168581, ... % u__v1_0__ps2_1___v1_0_
  0.956012, ... % u__v1_0__ps3_1___v1_0_
  101.326738, ... % u__v1_0__ps2_1__ps3_1___v1_0_
  88.168581, ... % u__v1_0__ps2_1___ps2_1_
  -262.506189, ... % u__v1_0__ps2_1__ps3_1___ps2_1_
  -0.956012, ... % u__v1_0__ps3_1___ps3_1_
  161.179451, ... % u__v1_0__ps2_1__ps3_1___ps3_1_
];

% 4. Visualizerの設定と描画
viz = ConstraintVisualizer(n, default_vals);
viz.Bounds = 500; % 描画範囲を大きめに設定
viz.ObjectiveFunction = @(x) sum(x.^2, 2);
viz.ContourLevels = 250;

% stability_ineqs の各要素を個別に addInequalitySet することで、
% Visualizer側でこれらを「OR条件（和集合）」として重ねて描画させます。
for j = 1:length(stability_ineqs)
  [A, b] = EqualityInequalityHelper.get_inequality_matrix(variables, stability_ineqs{j});
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

% 描画実行
viz.plot([3,5,7]);