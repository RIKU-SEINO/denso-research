classdef Solution
  % 変数と、その式または値のマッピングを保持するための基底クラス。
  % このクラスを継承して、状態価値関数や期待効用、最適化結果などの解を保持するためのクラスを作成することを想定している。
  % それぞれのクラスは以下のようになる。
  %   1. 状態価値関数を保持するクラス: StateValueSolution < Solution
  %   2. 期待効用を保持するクラス: ExpectedUtilitySolution < Solution
  %   3. 最適化結果を保持するクラス: IncentiveSolution < Solution

  properties
    % 変数のcell配列 （cell<char>）
    variables

    % 変数とその値のマッピング（cell<sym | double>）
    values
  end

  % constructor
  methods
    function obj = Solution(arg)
      Solution.validate_arg(arg);

      obj.variables = fieldnames(arg);
      obj.values = struct2cell(arg);

      obj = obj.format();
      obj.validate_obj();
    end
  end

  methods
    function value = get_value(obj, variable)
      % 変数に対応する値を取得する
      %
      % Parameters:
      %   variable (char): 変数
      %
      % Returns:
      %   value (sym or double): 変数に対応する値

      value = obj.values{strcmp(obj.variables, variable)};
    end

    function obj = eval_by_key_value(obj, variables, actual_values)
      % objを、変数variableに対応する値をactual_valueで評価したものを返す
      %
      % Parameters:
      %   variables (cell<char>): 変数の配列
      %   actual_values (cell<sym or double>): 変数に対応する値の配列
      %
      % Returns:
      %   obj (Solution): 評価されたSolution

      for i = 1:length(obj.variables)
        value = subs(obj.values{i}, variables, actual_values);
        obj.values{i} = value;
      end

      obj = obj.format();
      obj.validate_obj();
    end

    function obj_evaluated = eval_by_solution(obj, obj2)
      % objを、別のSolutionインスタンスobj2で評価する。
      % 例. obj1 = Solution({'x', 'y'}, {'p^2', 'q^2'});
      %     obj2 = Solution({'p', 'q'}, {'1', '2'});
      %     obj_evaluated = obj1.eval_by_solution(obj2);
      %     obj_evaluatedはSolution({'x', 'y'}, {'1', '4'})となる。
      %
      % Parameters:
      %   obj2 (Solution): 評価に使用するSolutionインスタンス
      %
      % Returns:
      %   obj_evaluated (Solution): 評価されたSolution

      if ~obj2.has_only_numeric_values()
        error('評価に使用する値は全て数値である必要があります');
      end

      obj_evaluated = obj.eval_by_key_value(obj2.variables, obj2.values);

    end

    function result = has_only_numeric_values(obj)
      % objの値が全て数値であるかどうかを返す。
      % ただし、valuesにsymが含まれていても、そのsymが数値になる場合はtrueを返す。
      %
      % Returns:
      %   result (logical): objの値が全て数値であるかどうか

      result = true;

      for i = 1:length(obj.values)
        value = obj.values{i};
        if ~Utils.isnumeric(value)
          result = false;
          break;
        end
      end
    end

    function strct = to_struct(obj)
      % objをstructに変換する
      %
      % Returns:
      %   struct (struct): objをstructに変換したもの

      strct = struct();

      for i = 1:length(obj.variables)
        strct.(obj.variables{i}) = obj.values{i};
      end
    end

    function obj = format(obj)
      % objの形式をフォーマットする
      %
      % Parameters:
      %   obj (Solution): フォーマットを行うSolutionインスタンス
      %
      % Returns:
      %   obj (Solution): フォーマットされたSolutionインスタンス

      if obj.has_only_numeric_values()
        obj.values = cellfun(@(x) double(x), obj.values, 'UniformOutput', false);
      end
    end
  end

  % validate obj
  methods
    function validate_obj(obj)
      % objのバリデーションを行う。
      %
      % Parameters:
      %   obj (Solution): バリデーションを行うSolutionインスタンス

      if length(obj.variables) ~= length(obj.values)
        error('変数と値の数が一致しません');
      end

      if ~iscell(obj.variables) || ~iscell(obj.values)
        error('変数と値はcell配列である必要があります');
      end

      for i = 1:length(obj.variables)
        if ~isa(obj.variables{i}, 'char')
          error('変数がcharである必要があります');
        end

        if ~isa(obj.values{i}, 'sym') && ~isa(obj.values{i}, 'double')
          error('値はsymまたはdoubleである必要があります');
        end
      end
    end
  end

  methods (Static)
    function validate_arg(arg)
      if ~isstruct(arg)
        error('引数argはstructである必要があります');
      end
    end

    function obj = to_solution(variables, values, classname)
      % 変数と値のマッピングをSolutionインスタンスに変換する
      %
      % Parameters:
      %   variables: 変数の配列
      %   values: 変数に対応する値の配列
      %   classname（optional）: 変換するクラス名
      %
      % Returns:
      %   obj (Solution | ExpectedUtilitySolution | StateValueSolution | IncentiveSolution): 変換されたSolutionインスタンス
      %    - classnameが指定されない場合は、Solutionインスタンスが返される
      %    - classnameが指定される場合は、classnameに対応するクラスのインスタンスが返される

      if nargin < 3
        classname = 'Solution';
      elseif strcmp(classname, 'ExpectedUtilitySolution')
        classname = 'ExpectedUtilitySolution';
      elseif strcmp(classname, 'StateValueSolution')
        classname = 'StateValueSolution';
      elseif strcmp(classname, 'IncentiveSolution')
        classname = 'IncentiveSolution';
      else
        error('指定されたクラス名 %s はSolutionクラスのサブクラスではありません', classname);
      end

      if length(variables) ~= length(values)
        error('変数と値の数が一致しません');
      end

      if iscell(variables)
        variables = variables(:);
      end
      if iscell(values)
        values = values(:);
      end

      arg = struct();
      for i = 1:length(variables)
        arg.(char(variables(i))) = values(i);
      end

      obj = eval([classname '(arg)']);
    end
  end
end
