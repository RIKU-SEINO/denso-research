clc; clear;
addpath('./class')
addpath('./func')

% 1. 最適状態価値関数方程式(=ベルマン方程式)を数値的に解く
disp('最適状態価値関数方程式の解を数値的に計算します...');
optimal_solution = EquationStateValueFunction.solve_equations();
optimal_pattern = Pattern.get_pattern_from_optimal_solution(optimal_solution);

% 2. すべてのpattern(=方策）ごとに、状態価値関数方程式を解く
disp('すべてのpatternごとに、状態価値関数方程式を解きます...');
patterns = Pattern.get_all_possible_patterns();
solutions = cell(length(patterns), 1);
is_optimal = false(length(patterns), 1);
for i = 1:length(patterns)
  pattern = patterns{i};
  fprintf('Pattern %d: %s\n', i, pattern.label);
  solution = EquationStateValueFunction.solve_equations_numeric_with_pattern(pattern);
  solutions{i} = solution;
  if isequal(pattern, optimal_pattern)
    is_optimal(i) = true;
  end
end