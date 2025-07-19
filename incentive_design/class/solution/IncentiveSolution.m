classdef IncentiveSolution < Solution
  % インセンティブを保持するためのクラス。Solutionクラスを継承している。

  % constructor
  methods
    function obj = IncentiveSolution(arg)
      obj@Solution(arg);
    end
  end

  % static methods
  methods (Static)
    function obj = to_solution(variables, values)
      obj = Solution.to_solution( ...
        variables, ...
        values, ...
        'IncentiveSolution' ...
      );
    end
  end
end