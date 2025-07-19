classdef ExpectedUtilitySolution < Solution
  % 期待効用の解を保持するためのクラス。Solutionクラスを継承している。

  % constructor
  methods
    function obj = ExpectedUtilitySolution(arg)
      obj@Solution(arg);
    end
  end

  % static methods
  methods (Static)
    function visualize(objs)
      % 各policyを採用した場合の、プレイヤ集合ごとの各プレイヤの期待効用を棒グラフとして表示する
      %
      % Parameters:
      %   objs (cell<ExpectedUtilitySolution>): 期待効用の解
      %
      % Returns:
      %   None

      if ~all(cellfun(@(x) x.has_only_numeric_values(), objs))
        error('期待効用を棒グラフで表示するためには、全ての解が数値である必要があります');
      end

      strcts = cellfun(@(x) x.to_struct(), objs, 'UniformOutput', false);

      ResultVisualizer.display_expected_utilities_as_bar( ...
        strcts, ...
        zeros(length(objs), 1) ...
      );
    end

    function obj = to_solution(variables, values)
      obj = Solution.to_solution( ...
        variables, ...
        values, ...
        'ExpectedUtilitySolution' ...
      );
    end
  end
end