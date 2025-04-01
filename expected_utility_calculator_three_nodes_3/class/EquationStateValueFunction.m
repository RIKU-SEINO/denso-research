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
    function expr = expr_with_pattern(obj, pattern)
      % 指定したPattern(=最適マッチングの組み合わせ)に基づいて、obj.player_setで指定されたプレイヤ集合におけるベルマン方程式を生成する
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

      expr = left == right;
    end
  end

  % static
  methods (Static)
    function exprs = exprs_with_pattern(pattern)
      % 指定したPattern(=最適マッチングの組み合わせ)に基づいて、全てのプレイヤ集合でベルマン方程式を生成する
      % 
      % Parameters:
      %   pattern (Pattern): プレイヤ集合のマッチングの組み合わせ
      % Returns:
      %   exprs (sym): obj.player_setで指定されたプレイヤ集合に関するベルマン方程式のシンボリック等式のセル配列
      fprintf('-------\nパターン %sについてベルマン方程式を構築中...\n', pattern.label);
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      exprs = sym(zeros(length(all_possible_player_sets), 1));
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        equation = EquationStateValueFunction(player_set);
        exprs(i) = equation.expr_with_pattern(pattern);
      end

      disp("ベルマン方程式の構築結果")
      exprs
    end
  end
end