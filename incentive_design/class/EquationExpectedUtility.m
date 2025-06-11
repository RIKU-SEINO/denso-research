classdef EquationExpectedUtility
  % EquationExpectedUtility クラス
  %
  % 期待効用方程式を表すクラス。
  % プレイヤとプレイヤ集合によって特徴づけられる期待効用を計算する
  %

  % properties
  properties
    % プレイヤ集合
    % PlayerSet
    player_set
    % プレイヤ
    % Player
    player
  end

  % constructor
  methods
    function obj = EquationExpectedUtility(player_set, player)
      % EquationExpectedUtility クラスのコンストラクタ
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤ集合
      %   player (Player): プレイヤ
      %
      % Returns:
      %   obj (EquationExpectedUtility): 生成された EquationExpectedUtility インスタンス

      obj.player_set = player_set;
      obj.player = player;
    end
  end

  methods
    function diff = diff_expected_utility_with_policy(obj, policy)
      % objで指定されたプレイヤ集合とプレイヤにおける、指定された方策policyに従った場合の期待効用方程式の右辺と左辺の差を取得する
      %
      % Parameters:
      %   obj (EquationExpectedUtility): EquationExpectedUtility インスタンス
      %   policy (Policy): 方策
      %
      % Returns:
      %   diff (sym): obj.player_setで指定されたプレイヤ集合と、obj.playerで指定されたプレイヤにおける期待効用方程式の右辺と左辺の差のシンボリック式

      % 1. ベルマン方程式左辺の構築
      left = VariablesHelper.get_expected_utility(obj.player_set, obj.player);

      % 2. ベルマン方程式右辺の構築
      player_matching = policy.get_player_matching_by_player_set(obj.player_set);
      right = player_matching.get_action_value_of_player(obj.player);

      % 期待効用方程式の右辺と左辺の差を計算
      diff = left - right;
    end

    function equation = build_equation_expected_utility_with_policy(obj, policy)
      % objで指定されたプレイヤ集合とプレイヤにおける、指定された方策policyに従った場合の期待効用方程式を取得する
      %
      % Parameters:
      %   obj (EquationExpectedUtility): EquationExpectedUtility インスタンス
      %   policy (Policy): 方策
      %
      % Returns:
      %   equation (sym): obj.player_setで指定されたプレイヤ集合と、obj.playerで指定されたプレイヤにおける期待効用方程式のシンボリック等式

      diff = obj.diff_expected_utility_with_policy(policy);
      equation = diff == 0;
    end
  end

  methods (Static)
    function diffs = build_diffs_expected_utility_with_policy(policy)
      % 指定したPolicyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式の右辺と左辺の差を取得する
      %
      % Parameters:
      %   policy (Policy): 方策
      %
      % Returns:
      %   diffs (cell): すべてのプレイヤ集合における期待効用方程式の右辺と左辺の差のシンボリック式をすべてのプレイヤについてまとめたcell配列

      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      all_possible_players = Player.get_all_possible_players();
      diffs = sym(zeros(length(all_possible_player_sets) * length(all_possible_players), 1));
      index = 1;
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        for j = 1:length(all_possible_players)
          player = all_possible_players{j};
          equation = EquationExpectedUtility(player_set, player);
          diffs(index) = equation.diff_expected_utility_with_policy(policy);
          index = index + 1;
        end
      end
    end

    function equations = build_equations_expected_utility_with_policy(policy)
      % Policyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式を取得する
      %
      % Parameters:
      %   policy (Policy): 方策
      %
      % Returns:
      %   equations (sym): すべてのプレイヤ集合、プレイヤにおける期待効用方程式のシンボリック式

      diffs = EquationExpectedUtility.build_diffs_expected_utility_with_policy(policy);
      equations = diffs == 0;
    end

    % function [A, B] = build_matrix_expected_utility_with_policy(policy)
    %   % Policyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式を解くための行列AとBを取得する
    %   %
    %   % Parameters:
    %   %   policy (Policy): 方策
    %   %
    %   % Returns:
    %   %   A (sym): 期待効用方程式を数値的に解くための行列A
    %   %   B (sym): 期待効用方程式を数値的に解くための行列B

    %   equations = EquationExpectedUtility.build_equations_expected_utility_with_policy(policy);
    %   x = VariablesHelper.init_expected_utilities();
    %   all_vars = symvar(x);
    %   [A, B] = equationsToMatrix(equations, all_vars);
    % end

    function solution = solve_expected_utility_with_policy_numeric(policy)
      % Policyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式を数値的に解く
      %
      % Parameters:
      %   policy (Policy): 方策
      %
      % Returns:
      %   solution (struct): 期待効用方程式の数値的な解を格納する構造体
      %     - 各フィールドは x に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は 数値的な解(double)

      diffs = EquationExpectedUtility.build_diffs_expected_utility_with_policy(policy);
      x = VariablesHelper.init_expected_utilities();

      % 1. 期待効用方程式の右辺と左辺の差のシンボリック式に含まれるパラメータを数値に置き換える
      diffs_evaluated = ParamsHelper.evaluate_all_params(diffs);
      % 2. 期待効用方程式の右辺と左辺の差のシンボリック式に含まれる期待効用変数を数値に置き換える
      xt = x.';
      matlabFunction(diffs_evaluated, 'Vars', {xt(:)}, 'File', 'func/diffs_expected_utility_with_policy');
      options = optimoptions('fsolve', 'Display', 'iter');
      [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, x_init] = ParamsHelper.get_valued_params();
      solution_array = fsolve(@diffs_expected_utility_with_policy, x_init.', options);
      solution = struct();
      index = 1;
      for i = 1:size(x, 1)
        for j = 1:size(x, 2)
          varname = char(x(i, j));
          solution.(varname) = solution_array(index);
          index = index + 1;
        end
      end
    end

    function solution = solve_expected_utility_with_policy_symbolic(policy)
      % Policyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式をシンボリックに解く
      %
      % Parameters:
      %   policy (Policy): 方策
      %
      % Returns:
      %   solution (struct): 期待効用方程式のシンボリックな解を格納する構造体
      %     - 各フィールドは x に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリックな解(sym)

      equations = EquationExpectedUtility.build_equations_expected_utility_with_policy(policy);
      x = VariablesHelper.init_expected_utilities();
      [w, c, a, ~, ~, r, b, ~, ~, ~, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      all_vars = symvar(x);
      solution = solve(equations, all_vars);
      for i = 1:length(all_vars)
        varname = char(all_vars(i));
        solution.(varname) = collect(solution.(varname), [w, c, a, r(2), r(3), b(2), b(3)]);
      end
    end


    function solution = solve_expected_utility_with_policy_symbolic_except_params(policy, params_to_exclude)
      % Policyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式をシンボリックに解く
      % ただし、指定したパラメータparams_to_exclude以外を数値に置き換える
      %
      % Parameters:
      %   policy (Policy): 方策
      %   params_to_exclude (string[]): 数値に置き換えないパラメータの名前(string)の配列
      %
      % Returns:
      %   solution (struct): 期待効用方程式のシンボリックな解を格納する構造体
      %     - 各フィールドは x に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリックな解(sym)

      equations = EquationExpectedUtility.build_equations_expected_utility_with_policy(policy);
      x = VariablesHelper.init_expected_utilities();
      all_vars = symvar(x);
      equations_evaluated = ParamsHelper.evaluate_except_params(equations, params_to_exclude);
      solution = solve(equations_evaluated, all_vars);
    end
  end
end