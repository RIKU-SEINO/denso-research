clc; clear;
addpath('./class')
addpath('./func')

processAllPatterns(@(pattern) EquationStateValueFunction.solve_equations_with_pattern(pattern));