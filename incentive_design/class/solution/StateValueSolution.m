classdef StateValueSolution < Solution
  % 状態価値関数の解を保持するためのクラス。Solutionクラスを継承している。

  % constructor
  methods
    function obj = StateValueSolution(arg)
      obj@Solution(arg);
    end
  end

  % static methods
  methods (Static)
    function obj = to_solution(variables, values)
      obj = Solution.to_solution( ...
        variables, ...
        values, ...
        'StateValueSolution' ...
      );
    end
  end
end