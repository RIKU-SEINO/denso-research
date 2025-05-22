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
    function diff_expr = diff_expr_with_policy(obj, policy)
      % obj.player_setで指定されたプレイヤ集合と、obj.playerで指定されたプレイヤにおける、方策policyに従った場合の期待効用方程式の右辺と左辺の差を取得する
      %
      % Parameters:
      %   obj (EquationExpectedUtility): EquationExpectedUtility インスタンス
      %   policy (Policy): 方策
      %
      % Returns:
      %   exprs (sym): obj.player_setで指定されたプレイヤ集合と、obj.playerで指定されたプレイヤにおける期待効用方程式の右辺と左辺の差のシンボリック式をすべてのプレイヤについてまとめたcell配列

      [~, ~, ~, ~, ~, ~, g, ~, ~, q] = ParamsHelper.get_symbolic_params();

      % 期待効用方程式の左辺の構築
      left = VariablesHelper.get_expected_utility(obj.player_set, obj.player);
      fprintf('現在のプレイヤ集合: %s\n\n', obj.player_set.label());
      fprintf('現在のプレイヤ: %s\n\n', obj.player.label());

      % 期待効用方程式の右辺の構築
      % 1. 現在のplayer_setから、タクシーの1ステップ遷移と乗客の出現が行われた後のプレイヤ集合として考えられるものを全て列挙（=27通り)
      player_sets_after_transition = obj.player_set.get_all_possible_player_sets_after_transition();

      right = sym(0);
      if obj.player_set.has(obj.player)
        % 2. 各プレイヤ集合に対して、次の処理を行う
        for i = 1:length(player_sets_after_transition)
          player_set_after_transition = player_sets_after_transition{i};
          player_after_transition = obj.player.one_step_elapsed();
          % 3. 遷移後のプレイヤ集合について、policyに基づいて採用されたマッチングを取得
          player_matching = policy.get_player_matching_by_player_set(player_set_after_transition);
          fprintf('遷移後のプレイヤ集合-%dにおける採用されたマッチング: %s\n', i, player_matching.label());
          % 4. 遷移後のプレイヤ集合について、期待効用を取得
          % 即時報酬（=R）
          utility = player_matching.get_utility_of_player(player_after_transition, 'symbolic');
          % マッチが組まれた後のプレイヤ集合における期待効用（=x）
          player_after_matching = player_matching.get_player_after_matching(player_after_transition);
          if ~isempty(player_after_matching)
            player_set_after_matching = player_matching.get_player_set_after_matching();
            expected_utility_after = VariablesHelper.get_expected_utility(player_set_after_matching, player_after_matching);
          else
            expected_utility_after = sym(0);
          end
          % R + γ * x
          expected_utility = utility + g * expected_utility_after;
          right = right + q(i) * expected_utility;
          fprintf('遷移後のプレイヤ集合-%dから上記のマッチング後における期待効用: %s\n\n', i, char(expected_utility));
        end
      end

      % 期待効用方程式の右辺と左辺の差を計算
      diff_expr = left - right;
    end
  end

  methods (Static)
    function diff_exprs = build_diff_exprs_with_policy(policy)
      % 指定したPolicyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式の右辺と左辺の差を取得する
      %
      % Parameters:
      %   policy (Policy): 方策
      %
      % Returns:
      %   diff_exprs (cell): すべてのプレイヤ集合における期待効用方程式の右辺と左辺の差のシンボリック式をすべてのプレイヤについてまとめたcell配列

      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      all_possible_players = Player.get_all_possible_players();
      diff_exprs = sym(zeros(length(all_possible_player_sets) * length(all_possible_players), 1));
      index = 1;
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        for j = 1:length(all_possible_players)
          player = all_possible_players{j};
          equation_expected_utility = EquationExpectedUtility(player_set, player);
          diff_exprs(index) = equation_expected_utility.diff_expr_with_policy(policy);
          index = index + 1;
        end
      end

      % disp("期待効用方程式の構築結果")
      % diff_exprs
    end

    function solution = solve_equations_numeric_with_policy(policy)
      % Policyに基づいて、すべてのプレイヤ集合、プレイヤにおける期待効用方程式を数値的に解く
      %
      % Parameters:
      %   policy (Policy): 方策
      %
      % Returns:
      %   solution (struct): 期待効用方程式の数値的な解を格納する構造体
      %     - 各フィールドは x に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は 数値的な解(double)

      diff_exprs = EquationExpectedUtility.build_diff_exprs_with_policy(policy);
      x = VariablesHelper.init_expected_utilities();
      xt = x.';
      [w, c, r, a, p, p_, g, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      [w_v, c_v, r_v, a_v, p_v, p__v, g_v, ~, ~, ~, ~, x_init] = ParamsHelper.get_valued_params();
      all_symbolic_params = [
        w, c, reshape(r.', 1, []), reshape(a.', 1, []), reshape(p.', 1, []), reshape(p_.', 1, []), g
      ];
      all_valued_params = [
        w_v, c_v, reshape(r_v.', 1, []), reshape(a_v.', 1, []), reshape(p_v.', 1, []), reshape(p__v.', 1, []), g_v
      ];

      % 1. 期待効用方程式の右辺と左辺の差のシンボリック式に含まれるパラメータを数値に置き換える
      diff_exprs_evaluated = subs(diff_exprs, all_symbolic_params, all_valued_params);
      % 2. 期待効用方程式の右辺と左辺の差のシンボリック式に含まれる期待効用変数を数値に置き換える
      matlabFunction(diff_exprs_evaluated, 'Vars', {xt(:)}, 'File', 'func/diff_exprs_evaluated_func_with_policy_expected_utility');
      options = optimoptions('fsolve', 'Display', 'iter');
      assignin('base', 'x_init', x_init);
      assignin('base', 'diff_exprs_evaluated', diff_exprs_evaluated);
      assignin('base', 'x', x);
      solution_array = fsolve(@diff_exprs_evaluated_func_with_policy_expected_utility, x_init.', options);
      solution = struct();
      index = 1;
      for i = 1:size(x, 1)
        for j = 1:size(x, 2)
          varname = char(x(i, j));
          solution.(varname) = solution_array(index);
          index = index + 1;
        end
      end

      % disp('期待効用方程式の解')
      % disp(solution)
    end
  end
end