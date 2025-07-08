classdef OptimizationProblem
  % 最適化問題を表すクラス
  % 最適化問題は、説明変数・目的関数・制約条件からなる

  % properties
  properties
    variables % 説明変数
    objective_function % 目的関数
    is_minimization % 最小化問題かどうか
    eq_constraint % 等式制約条件
    ineq_constraint % 不等式制約条件
  end

  % constructor
  methods
    function obj = OptimizationProblem(variables, objective_function, is_minimization, eq_constraint, ineq_constraint)
      % OptimizationProblem クラスのコンストラクタ
      % 最適化問題は、説明変数・目的関数・制約条件（等式制約条件・不等式制約条件）からなる
      %
      % Parameters:
      %   variables (sym[]): 説明変数
      %   objective_function (sym): 目的関数
      %   is_minimization (logical): 最小化問題かどうか
      %   eq_constraint (sym | 'none'): 等式制約条件
      %     複数の等式制約は、ANDで繋いで渡すこと。OR条件はサポートしていない
      %     また、eq_constraintが'none'の場合、eq_constraintは空として扱う
      %   ineq_constraint (sym | 'none'): 不等式制約条件
      %     複数の不等式制約は、ANDで繋いで渡すこと。OR条件はサポートしていない
      %     また、ineq_constraintが'none'の場合、ineq_constraintは空として扱う
      %
      % Returns:
      %   obj (OptimizationProblem): 生成された OptimizationProblem インスタンス
      
      obj.variables = variables;
      obj.objective_function = simplify(objective_function);
      obj.is_minimization = is_minimization;
      obj.eq_constraint = eq_constraint;
      obj.ineq_constraint = ineq_constraint;
      obj.validate();
    end
  end

  methods
    function label = label(obj)
      % 最適化問題のラベル（文字列表現）を返す
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   label (char): 最適化問題のラベル（文字列表現）
      %     ・目的関数が最大化問題の場合は 'max' を、最小化問題の場合は 'min' を返す
      %     ・等式制約条件がある場合は、それを含む文字列を返す
      %     ・不等式制約条件がある場合は、それを含む文字列を返す
      
      if obj.is_minimization
        label = 'min';
      else
        label = 'max';
      end

      label = sprintf('%s %s', label, char(obj.objective_function));

      if ~isequal(obj.eq_constraint, 'none')
        constraint_label = char(obj.eq_constraint);
      else
        constraint_label = '';
      end

      if ~isequal(obj.ineq_constraint, 'none')
        constraint_label = sprintf('%s and %s', constraint_label, char(obj.ineq_constraint));
      end

      label = sprintf('%s subject to %s', label, constraint_label);
    end

    function fun = get_objective_function_for_fmincon(obj)
      % シンボリックな目的関数を、fminconの引数に渡せるようにdouble型のベクトルに変換する
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   A_f (double[]): 目的関数の係数行列

      if obj.is_minimization
        f = obj.objective_function;
      else
        f = -obj.objective_function;
      end

      fun_raw = matlabFunction(f, 'Vars', obj.variables);
      % == Assumption: 7 variables to optimize ==
      if ParamsHelper.get_num_of_incentives() == 7
        fun = @(x) fun_raw(x(1), x(2), x(3), x(4), x(5), x(6), x(7));
      else
        error('Assumption: 7 variables to optimize. Please check number of incentive variables.');
      end
    end

    function [A_fun, b_fun] = get_objective_function_for_linprog(obj)
      % シンボリックな目的関数を、linprogの引数に渡せるようにdouble型のベクトルに変換する
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   A_fun (double[]): 目的関数の係数行列

      if obj.is_minimization
        f = obj.objective_function;
      else
        f = -obj.objective_function;
      end

      [A_fun, b_fun] = equationsToMatrix(f, obj.variables);
      b_fun = double(b_fun);
      A_fun = double(A_fun);
    end

    function [A, b] = get_linear_equality_constraint(obj)
      % シンボリックな等式制約を、線形等式制約に変換する
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   A (sym[]): 線形制約の係数行列
      %   b (sym[]): 線形制約の定数項

      if isequal(obj.eq_constraint, 'none')
        A = [];
        b = [];
        return;
      end

      if contains(char(obj.eq_constraint), '&')
        constraints = children(obj.eq_constraint);
      else
        constraints = {obj.eq_constraint};
      end

      [A, b] = equationsToMatrix(constraints, obj.variables);
      A = double(A);
      b = double(b);
    end

    function [A, b] = get_linear_inequality_constraint(obj)
      % シンボリックな不等式制約を、線形不等式制約に変換する
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   A (sym[]): 線形不等式制約の係数行列
      %   b (sym[]): 線形不等式制約の定数項

      if isequal(obj.ineq_constraint, 'none')
        A = [];
        b = [];
        return;
      end

      if contains(char(obj.ineq_constraint), '&')
        constraints = children(obj.ineq_constraint);
      else
        constraints = {obj.ineq_constraint};
      end

      % 各constraintを、lhs-rhsの形式に変換する
      constraints = cellfun(@(c) lhs(c) - rhs(c) == 0, constraints, 'UniformOutput', false);

      [A, b] = equationsToMatrix(constraints, obj.variables);
      A = double(A);
      b = double(b);
    end

    function result = execute_fmincon(obj)
      % fminconを用いて最適化問題を実行する
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   result (struct): 最適化問題の実行結果
      %     ・result.x (sym[]): 最適化問題の解
      %     ・result.fval (double): 最適化問題の目的関数値
      %     ・result.exitflag (int): 最適化問題の終了フラグ
      %     ・result.output (struct): 最適化問題の実行結果の詳細

      fun = obj.get_objective_function_for_fmincon();
      [A_eq, b_eq] = obj.get_linear_equality_constraint();
      [A_ineq, b_ineq] = obj.get_linear_inequality_constraint();

      x0 = zeros(1, length(obj.variables));
      options = optimoptions('fmincon', 'Display', 'iter');

      [x, fval, exitflag, output] = fmincon( ...
        fun, ... % 目的関数
        x0, ... % 初期値
        A_ineq, b_ineq, ... % 不等式制約
        A_eq, b_eq, ... % 等式制約
        [], [], [], ... % 非線形制約
        options ... % オプション
      );

      result = struct('x', x, 'fval', fval, 'exitflag', exitflag, 'output', output);
    end

    function result = execute_linprog(obj)
      % linprogを用いて最適化問題を実行する
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   result (struct): 最適化問題の実行結果
      %     ・result.x (sym[]): 最適化問題の解
      %     ・result.fval (double): 最適化問題の目的関数値
      %     ・result.exitflag (int): 最適化問題の終了フラグ
      %     ・result.output (struct): 最適化問題の実行結果の詳細

      [A_fun, b_fun] = obj.get_objective_function_for_linprog();
      [A_eq, b_eq] = obj.get_linear_equality_constraint();
      [A_ineq, b_ineq] = obj.get_linear_inequality_constraint();

      num_incentives = ParamsHelper.get_num_of_incentives();

      options = optimoptions('linprog', 'Display', 'iter');

      [x, fval, exitflag, output] = linprog( ...
        A_fun, ... % 目的関数の係数行列
        A_ineq, b_ineq, ... % 不等式制約
        A_eq, b_eq, ... % 等式制約
        -inf(num_incentives, 1), ... % 下界
        inf(num_incentives, 1), ... % 上界
        options ... % オプション
      );

      result = struct('x', x, 'fval', fval+b_fun, 'exitflag', exitflag, 'output', output);
    end
  end

  % validation
  methods
    function validate(obj)
      % 最適化問題のバリデーション
      %
      % Parameters:
      %   obj (OptimizationProblem): 最適化問題
      %
      % Returns:
      %   obj (OptimizationProblem): 生成された OptimizationProblem インスタンス

      % 型チェック
      if ~isa(obj.variables, 'sym')
        error('variables must be a symbolic expression');
      end

      if ~isa(obj.objective_function, 'sym')
        error('objective_function must be a symbolic expression');
      end

      if ~islogical(obj.is_minimization)
        error('is_minimization must be a logical value');
      end

      if ~isequal(obj.eq_constraint, 'none') && ~isa(obj.eq_constraint, 'sym')
        error('eq_constraint must be a symbolic expression or ''none''');
      end

      if ~isequal(obj.ineq_constraint, 'none') && ~isa(obj.ineq_constraint, 'sym')
        error('ineq_constraint must be a symbolic expression or ''none''');
      end

      % OR条件のチェック
      if contains(char(obj.eq_constraint), '|')
        error('eq_constraint must not contain OR conditions');
      end

      if contains(char(obj.ineq_constraint), '|')
        error('ineq_constraint must not contain OR conditions');
      end
    end
  end
end