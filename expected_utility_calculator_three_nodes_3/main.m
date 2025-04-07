clc; clear;
addpath('./class')
addpath('./func')

% 1-1. 最適状態価値関数方程式(=ベルマン方程式)を数値的に解く
disp('最適状態価値関数方程式の解を数値的に計算します...');
optimal_solution = EquationStateValueFunction.solve_equations();
optimal_policy = Policy.get_policy_from_optimal_solution(optimal_solution);

% 1-2. 最適方策に基づいて、期待効用方程式を数値的に解く
sol = EquationExpectedUtility.solve_equations_numeric_with_policy(optimal_policy);

% % 2. すべてのpolicy(=方策）ごとに、状態価値関数方程式を解く
% disp('すべてのpolicyごとに、状態価値関数方程式を解きます...');
% policies = Policy.get_all_possible_policies();
% solutions = cell(length(policies), 1);
% is_optimal = false(length(policies), 1);
% for i = 1:length(policies)
%   policy = policies{i};
%   fprintf('Policy %d: %s\n', i, policy.label);
%   solution = EquationStateValueFunction.solve_equations_numeric_with_policy(policy);
%   solutions{i} = solution;
%   if isequal(policy, optimal_policy)
%     is_optimal(i) = true;
%   end
% end