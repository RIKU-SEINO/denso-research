clc; clear; close all;
addpath('./class')
addpath('./class/solution')
warning('off', 'all');

%%%% EDIT HERE %%%%
target_data = 'result/symbolic_data.mat';
stability_type = 'EBP'; % 'BP' または 'EBP' のいずれか
should_analyze_stabilizability = true; % 安定化可能条件の導出を行うかどうか
should_analyze_self_stability = false; % 自律的安定条件の導出を行うかどうか
params_to_evaluate = {'g', 'p_2', 'p_3'}; % 数値的に評価するパラメータを文字列のcell配列で指定。
use_positive_incentive_condition = true; % マッチしないプレイヤに対して、インセンティブが0以上であることを制約する場合は true, そうでない場合は false
%%%%%%%%%%%%%%%%%%%

% 1. データの読み込み
if exist(target_data, 'file')
  fprintf('データを読み込みます\n');
  data = load(target_data);
  policies = Policy.get_all_possible_policies();
  expected_utility_solutions = data.expected_utility_solutions;
  disp('データを読み込みました');
else
  error('データが存在しません');
end

% 2. パラメータを数値的に評価したSolutionを作成する
fprintf('パラメータを数値的に評価したSolutionを作成します\n');
for i = 1:length(policies)
  expected_utility_solutions{i} = expected_utility_solutions{i}.eval_params(params_to_evaluate);
end
fprintf('パラメータを数値的に評価したSolutionを作成しました\n');

% 3. 各方策ごとに安定化可能条件の導出
if should_analyze_stabilizability
  variables = ParamsHelper.get_all_incentives_as_vector();
  for policy_index = 5:length(policies)
    policy = policies{policy_index};
    stability_ineqs = MathUtils.expand_or_optimized( ...
      policy.stability_condition(stability_type, expected_utility_solutions) ...
    );
    disp(['policy', num2str(policy.index())]);
    fprintf('安定条件制約数: %d\n', length(stability_ineqs));
    
    % 各stability_ineqに対する条件を格納（各要素はAND結合された条件の配列）
    all_conditions = cell(length(stability_ineqs), 1);
    
    for stability_ineq_index = 1:length(stability_ineqs)
      [incentive_eq, incentive_ineq] = ParamsHelper.incentive_condition( ...
        policy, ...
        use_positive_incentive_condition ...
      );
      stability_ineq = stability_ineqs{stability_ineq_index};

      [A_eq, b_eq] = EqualityInequalityHelper.get_equality_matrix( ...
        variables, ...
        incentive_eq ...
      );
      [A_ineq, b_ineq] = EqualityInequalityHelper.get_inequality_matrix( ...
        variables, ...
        and(stability_ineq, incentive_ineq) ...
      );
      [A_reduced, b_reduced] = EqualityInequalityHelper.get_reduced_matrix( ...
        A_eq, ...
        b_eq, ...
        A_ineq, ...
        b_ineq ...
      );
      all_conditions{stability_ineq_index} = ...
        EqualityInequalityHelper.get_inequality_feasibility_condition_MPT3( ...
          A_reduced, ...
          b_reduced ...
        );
      % all_conditions{stability_ineq_index} =  ...
      %   EqualityInequalityHelper.get_inequality_feasibility_condition_FourierMotzkin( ...
      %     vpa(A_reduced), ...
      %     vpa(b_reduced) ...
      %   );
    end
    
    % 結果の表示
    fprintf('方策%dをインセンティブ安定化することが可能な条件:\n', policy_index);
    fprintf('（以下の条件群のいずれか1つを満たせばよい - OR結合）\n');
    
    valid_condition_count = 0;
    for condition_set_index = 1:length(all_conditions)
      % condition_set の各要素はANDで繋がれる関係にある
      % e.g., condition_set = [logical expression 1, logical expression 2, ...]であれば
      %       logical expression 1 AND logical expression 2 AND ... を意味する
      condition_set = all_conditions{condition_set_index};
      valid_condition_count = valid_condition_count + 1;
      
      % もし、condition_setの各要素がsymtrueのみであれば無条件で実行可能
      if all(isAlways(condition_set))
        fprintf('  [条件群 %d] 無条件で実行可能\n', valid_condition_count);
      % もし、condition_setの各要素のうち、symfalseが1つでもあれば実行不可能
      elseif any(isAlways(~condition_set))
        fprintf('  [条件群 %d] 実行不可能\n', valid_condition_count);
      else
        fprintf('  [条件群 %d] （以下すべてを満たす - AND結合）:\n', valid_condition_count);
        for cond_index = 1:length(condition_set)
          disp(EqualityInequalityHelper.normalize_inequality(condition_set(cond_index), 'c', 3));
        end
      end
    end
    
    disp('-----------------------------');
    pause;
  end
end
