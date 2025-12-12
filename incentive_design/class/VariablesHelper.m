classdef VariablesHelper
  methods(Static)
    function V = init_state_values()
      % 状態価値のシンボリック変数を初期化／キャッシュ
      % Args: なし
      % Returns:
      %   V (symbolic vector): 全プレイヤセット分の状態価値シンボル
      persistent V_cache;
      if isempty(V_cache)
        sets = PlayerSet.get_all_possible_player_sets();
        V_cache = sym(zeros(length(sets), 1));
        for i = 1:length(sets)
          ps = sets{i};
          varname = matlab.lang.makeValidName(strcat('V_', ps.label()));
          syms(varname);
          V_cache(i) = eval(varname);
          assume(V_cache(i), 'real');
        end
      end
      V = V_cache;
    end

    function state_value = get_state_value(player_set)
      % プレイヤセットに対応する状態価値を返す
      % Args:
      %   player_set (PlayerSet)
      % Returns:
      %   state_value (symbolic)
      V = VariablesHelper.init_state_values();
      state_value = V(player_set.index());
    end

    function x = init_expected_utilities()
      % 期待効用のシンボリック変数を初期化／キャッシュ
      % Args: なし
      % Returns:
      %   x (symbolic matrix): (player_set, player) の期待効用シンボル
      persistent x_cache;
      if isempty(x_cache)
        sets = PlayerSet.get_all_possible_player_sets();
        players = Player.get_all_possible_players();
        x_cache = sym(zeros(length(sets), length(players)));
        for i = 1:length(sets)
          ps = sets{i};
          for j = 1:length(players)
            pl = players{j};
            varname = matlab.lang.makeValidName(strcat('x_', ps.label(), '_', pl.label()));
            syms(varname);
            x_cache(i, j) = eval(varname);
            assume(x_cache(i, j), 'real');
          end
        end
      end
      x = x_cache;
    end

    function expected_utility = get_expected_utility(player_set, player)
      % プレイヤセット×プレイヤの期待効用シンボルを返す
      % Args:
      %   player_set (PlayerSet)
      %   player (Player)
      % Returns:
      %   expected_utility (symbolic)
      x = VariablesHelper.init_expected_utilities();
      expected_utility = x(player_set.index(), player.index());
    end

    function expected_utility = get_solution_expected_utility(player_set, player, solution)
      % 解オブジェクトから期待効用の値を取得する
      % Args:
      %   player_set (PlayerSet)
      %   player (Player)
      %   solution (ExpectedUtilitySolution)
      % Returns:
      %   expected_utility (symbolic | numeric)
      key = char(VariablesHelper.get_expected_utility(player_set, player));
      expected_utility = [];
      for i = 1:length(solution.variables)
        if strcmp(solution.variables{i}, key)
          expected_utility = solution.values{i};
          break;
        end
      end
      if isempty(expected_utility)
        error('solutionから変数名%sの期待効用を取得できませんでした', key);
      end
    end
  end
end
