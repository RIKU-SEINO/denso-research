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
      right = player_matching.get_action_value_with_incentive(policy);

      % 3. ベルマン方程式の右辺と左辺の差
      diff = left - right;
    end

    function equation = build_equation_bellman_with_policy(obj, policy)
      % 指定したPolicyに基づいて、obj.player_setで指定されたプレイヤ集合におけるベルマン方程式を構築する
      %
      % Parameters:
      %   obj (EquationStateValueFunction): EquationStateValueFunction インスタンス
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      %
      % Returns:
      %   equation (sym): 指定したPolicyに基づいて、obj.player_setで指定されたプレイヤ集合におけるベルマン方程式のシンボリック等式

      diff = obj.diff_bellman_with_policy(policy);
      equation = diff == 0;
    end
  end

  % static
  methods (Static)
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
        equations(i) = equation.build_equation_bellman_with_policy(policy);
      end
    end

    function solution = solve_equations_bellman_with_policy_symbolic(policy)
      % 方策に基づいて、ベルマン方程式を解析的に解く
      %
      % Parameters:
      %   policy (Policy): プレイヤ集合のマッチングの組み合わせ
      %   solution (struct): シンボリックな解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリック表記の解(sym)

      equations = EquationStateValueFunction.build_equations_bellman_with_policy(policy);
      V = VariablesHelper.init_state_values();
      [w, c, a, ~, ~, r, b, ~, ~, ~, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      all_vars = symvar(V);
      solution = solve(equations, all_vars);
      for i = 1:length(all_vars)
        varname = char(all_vars(i));
        solution.(varname) = collect(solution.(varname), [w, c, a, r(2), r(3), b(2), b(3)]);
      end
    end

    function solution = solve_equations_bellman_with_policy_symbolic_except_params(policy, params_to_exclude)
      % 方策に基づいて、ベルマン方程式をシンボリックに解く
      % ただし、指定したパラメータparams_to_exclude以外を数値に置き換える
      %
      % Parameters:
      %   policy (Policy): 方策
      %   params_to_exclude (string[]): 数値に置き換えないパラメータの名前(string)の配列
      %
      % Returns:
      %   solution (struct): ベルマン方程式のシンボリックな解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリックな解(sym)

      equations = EquationStateValueFunction.build_equations_bellman_with_policy(policy);
      V = VariablesHelper.init_state_values();
      all_vars = symvar(V);
      equations_evaluated = ParamsHelper.evaluate_except_params(equations, params_to_exclude);
      solution = solve(equations_evaluated, all_vars);
    end
  end
end