clc; clear;
addpath('./class')
addpath('./func')
mkdir 'result'
mkdir 'func'

policies = Policy.get_all_possible_policies();
for i = 1:length(policies)
  policy = policies{i};
  fprintf('Policy %d: %s\n', i, policy.label);
  solution = EquationExpectedUtility.solve_expected_utility_with_policy_symbolic(policy)
end