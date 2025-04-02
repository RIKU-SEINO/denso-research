clc; clear;
addpath('./class')
addpath('./func')

% % 解析的に解く
% processAllPatterns(@(pattern) EquationStateValueFunction.solve_equations_with_pattern(pattern));

% 数値的に解く
EquationStateValueFunction.solve_equations();