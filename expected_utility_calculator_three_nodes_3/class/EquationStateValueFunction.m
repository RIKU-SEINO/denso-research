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
    function diff_expr = diff_expr(obj)
      % obj.player_setで指定されたプレイヤ集合におけるベルマン方程式の右辺と左辺の差を取得する。expr_with_patternと異なり、patternオブジェクトを明示的に指定しないので、piecewise(=区分関数)を含む式を返す
      %
      % Parameters:
      %   obj (EquationStateValueFunction): EquationStateValueFunction インスタンス
      %
      % Returns:
      %   expr (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式の右辺と左辺の差のシンボリック式
      [~, ~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.get_symbolic_params();

      % ベルマン方程式左辺の構築
      left = VariablesHelper.get_state_value(obj.player_set);

      fprintf('現在のプレイヤ集合: %s\n\n', obj.player_set.label());

      % ベルマン方程式右辺の構築
      % 1. 現在のplayer_setから、タクシーの1ステップ遷移と乗客の出現が行われた後のプレイヤ集合として考えられるものを全て列挙（=27通り)
      player_sets_after_transition = obj.player_set.get_all_possible_player_sets_after_transition();

      right = sym(0);
      % 2. 各プレイヤ集合に対して、最適なマッチングの組み合わせを取得
      for i = 1:length(player_sets_after_transition)
        player_set_after_transition = player_sets_after_transition{i};
        fprintf('遷移後のプレイヤ集合-%d: %s\n\n', i, player_set_after_transition.label());
        % 3. 遷移後のプレイヤ集合について、最適マッチングにおける期待効用をpiecewiseで区分的に表現

        expected_utility = player_set_after_transition.get_optimal_expected_utility();

        right = right + q(i) * expected_utility;
        fprintf('遷移後のプレイヤ集合-%dから上記のマッチング後における期待効用: %s\n\n', i, char(expected_utility));
      end

      diff_expr = left - right;
    end

    function expr = expr_with_pattern(obj, pattern)
      % 指定したPattern(=最適マッチングの組み合わせ)に基づいて、obj.player_setで指定されたプレイヤ集合におけるベルマン方程式を構築する
      %
      % Parameters:
      %   obj (EquationStateValueFunction): EquationStateValueFunction インスタンス
      %   pattern (Pattern): プレイヤ集合のマッチングの組み合わせ
      %
      % Returns:
      %   expr (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式のシンボリック等式
      [~, ~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.get_symbolic_params();

      % ベルマン方程式左辺の構築
      left = VariablesHelper.get_state_value(obj.player_set);

      fprintf('現在のプレイヤ集合: %s\n\n', obj.player_set.label());

      % ベルマン方程式右辺の構築
      % 1. 現在のplayer_setから、タクシーの1ステップ遷移と乗客の出現が行われた後のプレイヤ集合として考えられるものを全て列挙（=27通り)
      player_sets_after_transition = obj.player_set.get_all_possible_player_sets_after_transition();

      right = sym(0);
      % 2. 各プレイヤ集合に対して、最適なマッチングの組み合わせを取得
      for i = 1:length(player_sets_after_transition)
        player_set_after_transition = player_sets_after_transition{i};
        fprintf('遷移後のプレイヤ集合-%d: %s\n\n', i, player_set_after_transition.label());
        % 3. 遷移後のプレイヤ集合について、patternに基づいて最適マッチングを取得
        
        optimal_player_matching = pattern.get_player_matching_by_player_set(player_set_after_transition);
        fprintf('遷移後のプレイヤ集合-%dにおける最適マッチング: %s\n', i, optimal_player_matching.label());
        % 4. 遷移後のプレイヤ集合における最適マッチングの期待効用を計算し、q(i) * その期待効用を加算
        expected_utility = optimal_player_matching.get_expected_utility_sum();
        right = right + q(i) * expected_utility;
        fprintf('遷移後のプレイヤ集合-%dから上記のマッチング後における期待効用: %s\n\n', i, char(expected_utility));
      end

      expr = right == left;
    end
  end

  % static
  methods (Static)
    function diff_exprs = build_diff_exprs()
      % 全てのプレイヤ集合でベルマン方程式の右辺と左辺の差を計算する
      %
      % Returns:
      %   diff_exprs (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式の右辺と左辺の差のシンボリック式の配列  
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      diff_exprs = sym(zeros(length(all_possible_player_sets), 1));
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        equation = EquationStateValueFunction(player_set);
        diff_exprs(i) = equation.diff_expr();
      end

      disp("ベルマン方程式の構築結果")
      diff_exprs
    end

    function solution = solve_equations()
      % 全てのプレイヤ集合でベルマン方程式の右辺と左辺の差を計算し、数値的に解く
      %
      % Returns:
      %   solution (struct): シンボリックな解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリック表記の解(sym)

      diff_exprs = EquationStateValueFunction.build_diff_exprs();
      V = VariablesHelper.init_state_values();
      [w, c, r, a, p, p_, g, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      [w_v, c_v, r_v, a_v, p_v, p__v, g_v, V_init] = ParamsHelper.get_valued_params();
      all_symbolic_params = [
        w, c, reshape(r.', 1, []), reshape(a.', 1, []), reshape(p.', 1, []), reshape(p_.', 1, []), g
      ];
      all_valued_params = [
        w_v, c_v, reshape(r_v.', 1, []), reshape(a_v.', 1, []), reshape(p_v.', 1, []), reshape(p__v.', 1, []), g_v
      ];

      % 1. ベルマン方程式の右辺と左辺の差のシンボリック式に含まれるパラメータを数値に置き換える
      diff_exprs_evaluated = subs(diff_exprs, all_symbolic_params, all_valued_params);
      % 2. ベルマン方程式の右辺と左辺の差のシンボリック式を数値的に解く
      matlabFunction(diff_exprs_evaluated, 'Vars', {V.'}, 'File', 'func/diff_exprs_func');
      options = optimoptions('fsolve', 'Display', 'iter');
      solution = fsolve(@diff_exprs_func, V_init, options);

      disp('解')
      solution
    end

    function equations = build_equations_with_pattern(pattern)
      % 指定したPattern(=最適マッチングの組み合わせ)に基づいて、全てのプレイヤ集合でベルマン方程式を生成する
      % 
      % Parameters:
      %   pattern (Pattern): プレイヤ集合のマッチングの組み合わせ
      % Returns:
      %   equations (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式のシンボリック等式のセル配列
      fprintf('-------\nパターン %sについてベルマン方程式を構築中...\n', pattern.label);
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      equations = sym(zeros(length(all_possible_player_sets), 1));
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        equation = EquationStateValueFunction(player_set);
        equations(i) = equation.expr_with_pattern(pattern);
      end

      disp("ベルマン方程式の構築結果")
      equations
    end

    function solution = solve_equations_with_pattern(pattern)
      % 指定したPattern(=最適マッチングの組み合わせ)に基づいて、全てのプレイヤ集合でベルマン方程式を生成し、解く
      %
      % Parameters:
      %   pattern (Pattern): プレイヤ集合のマッチングの組み合わせ
      %   solution (struct): シンボリックな解を格納する構造体
      %     - 各フィールドは V に含まれる期待効用変数の名前(string)
      %     - 各フィールドの値は シンボリック表記の解(sym)

      equations = EquationStateValueFunction.build_equations_with_pattern(pattern);
      V = VariablesHelper.init_state_values();
      [w, c, r, a, ~, ~, ~, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      all_vars = symvar(V);
      solution = solve(equations, all_vars);
      for i = 1:length(all_vars)
        varname = char(all_vars(i));
        solution.(varname) = Utils.organize_expr(solution.(varname), [w, c, r(1), r(2), r(3), a(1), a(2), a(3)]);
      end

      disp('解')
      solution
    end
  end
end