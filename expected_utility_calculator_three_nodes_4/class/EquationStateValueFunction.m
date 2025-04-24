classdef EquationStateValueFunction
  % Markov Decision Process (MDP) の状態価値関数に関する方程式を表すクラス
  % 各状態（＝プレイヤ集合）における期待効用をベルマン方程式として表現する
  %

  % properties
  properties
    % プレイヤ集合
    % PlayerSet
    player_set
  end

  % constructor
  methods
    function obj = EquationStateValueFunction(player_set)
      % EquationStateValueFunction クラスのコンストラクタ
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤ集合
      %
      % Returns:
      %   obj (EquationStateValueFunction): 生成された EquationStateValueFunction インスタンス

      obj.player_set = player_set;
    end
  end

  % other
  methods
    function diff = diff_bellman_optimal(obj)
      % obj.player_setで指定されたプレイヤ集合におけるベルマン最適方程式の左辺と右辺の差
      %
      % Parameters:
      %   obj (EquationStateValueFunction): EquationStateValueFunction インスタンス
      %
      % Returns:
      %   diff (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン最適方程式のシンボリック式

      % 1. ベルマン方程式左辺の構築
      left = VariablesHelper.get_state_value(obj.player_set);

      % 2. ベルマン方程式右辺の構築
      % 2-1. 現在のplayer_setで、考えられる全てのマッチングを列挙する
      all_possible_player_matchings = obj.player_set.get_all_possible_player_matchings();
      % 2-2. 各マッチングの行動価値を最大値をpiecewiseで区分的に表現
      right = PlayerMatching.max_action_value_as_piecewise(all_possible_player_matchings);

      % 3. ベルマン方程式の左辺と右辺の差
      diff = left - right;
    end

    function diff = diff_bellman_with_policy(obj, policy)
      % 指定したPolicyに基づいて、obj.player_setで指定されたプレイヤ集合におけるベルマン方程式の左辺と右辺の差
      %
      % Parameters:
      %   obj (EquationStateValueFunction): EquationStateValueFunction インスタンス
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      %
      % Returns:
      %   diff (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式のシンボリック式

      % 1. ベルマン方程式左辺の構築
      left = VariablesHelper.get_state_value(obj.player_set);

      % 2. ベルマン方程式右辺の構築
      player_matching = policy.get_player_matching_by_player_set(obj.player_set);
      right = player_matching.get_action_value();

      % 3. ベルマン方程式の右辺と左辺の差
      diff = left - right;
    end
  end

  % static
  methods (Static)
    function diffs = build_diffs_bellman_optimal()
      % 全てのプレイヤ集合でベルマン最適方程式の右辺と左辺の差を計算する
      %
      % Returns:
      %   diffs (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式の右辺と左辺の差のシンボリック式の配列  
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      diffs = sym(zeros(length(all_possible_player_sets), 1));
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        equation = EquationStateValueFunction(player_set);
        diffs(i) = equation.diff_bellman_optimal();
      end
    end

    function solution = solve_bellman_optimal_numeric()
      % ベルマン最適方程式を数値的に解く
      %
      % Returns:
      %   solution (struct): 数値解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は 数値解(double)

      diffs = EquationStateValueFunction.build_diffs_bellman_optimal();
      V = VariablesHelper.init_state_values();
      [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, V_init, ~] = ParamsHelper.get_valued_params();

      % 1. ベルマン方程式の右辺と左辺の差のシンボリック式に含まれるパラメータを数値に置き換える
      diffs_evaluated = ParamsHelper.evaluate_params(diffs);
      % 2. ベルマン方程式の右辺と左辺の差のシンボリック式を数値的に解く
      matlabFunction(diffs_evaluated, 'Vars', {V.'}, 'File', 'func/diffs_bellman_optimal');
      options = optimoptions('fsolve', 'Display', 'iter');
      solution_array = fsolve(@diffs_bellman_optimal, V_init, options);
      solution = struct();
      for i = 1:length(V)
        varname = char(V(i));
        solution.(varname) = solution_array(i);
      end
    end

    function equations = build_equations_bellman_with_policy(policy)
      % 方策に基づいて、全てのプレイヤ集合に関するベルマン方程式を構築する
      % 
      % Parameters:
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      % Returns:
      %   equations (sym): 全てのプレイヤ集合に関するベルマン方程式のシンボリック等式のセル配列
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      equations = sym(zeros(length(all_possible_player_sets), 1));
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        equation = EquationStateValueFunction(player_set);
        equations(i) = equation.diff_bellman_with_policy(policy) == 0;
      end
    end

    function solution = solve_equations_bellman_with_policy_analytic(policy)
      % 方策に基づいて、ベルマン方程式を解析的に解く
      %
      % Parameters:
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      %   solution (struct): シンボリックな解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリック表記の解(sym)

      equations = EquationStateValueFunction.build_equations_with_policy(policy);
      V = VariablesHelper.init_state_values();
      [w, c, r, a, ~, ~, ~, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      all_vars = symvar(V);
      solution = solve(equations, all_vars);
      for i = 1:length(all_vars)
        varname = char(all_vars(i));
        solution.(varname) = Utils.organize_expr(solution.(varname), [w, c, r(1), r(2), r(3), a(1), a(2), a(3)]);
      end
    end

    function diffs = build_diffs_bellman_with_policy(policy)
      % 方策に基づいて、全てのプレイヤ集合に関するベルマン方程式の右辺と左辺の差を計算する
      %
      % Parameters:
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      % Returns:
      %   diffs (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式の右辺と左辺の差のシンボリック式の配列 
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets(); 
      diffs = sym(zeros(length(all_possible_player_sets), 1));
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        equation = EquationStateValueFunction(player_set);
        diffs(i) = equation.diff_bellman_with_policy(policy);
      end
    end

    function solution = solve_bellman_with_policy_numeric(policy)
      % 方策に基づいて、数値的にベルマン方程式を解く
      %
      % Parameters:
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      %   solution (struct): 数値解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は 数値解(double)

      diffs = EquationStateValueFunction.build_diffs_bellman_with_policy(policy);
      V = VariablesHelper.init_state_values();
      [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, V_init, ~] = ParamsHelper.get_valued_params();

      % 1. ベルマン方程式の右辺と左辺の差のシンボリック式に含まれるパラメータを数値に置き換える
      diffs_evaluated = ParamsHelper.evaluate_params(diffs);
      % 2. ベルマン方程式の右辺と左辺の差のシンボリック式を数値的に解く
      matlabFunction(diffs_evaluated, 'Vars', {V.'}, 'File', 'func/diffs_bellman_with_policy');
      options = optimoptions('fsolve', 'Display', 'iter');
      solution_array = fsolve(@diffs_bellman_with_policy, V_init, options);
      solution = struct();
      for i = 1:length(V)
        varname = char(V(i));
        solution.(varname) = solution_array(i);
      end
    end
  end
end