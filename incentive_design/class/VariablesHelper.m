classdef VariablesHelper
  methods(Static)
    function V = init_state_values()
      % 状態価値関数の初期化
      %
      % Parameters: None
      %
      % Returns:
      %   V (symbolic): 状態価値関数のシンボリック変数の配列
      
      persistent V_cache;

      if isempty(V_cache)
        all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
        V_cache = sym(zeros(length(all_possible_player_sets), 1));
        for i = 1:length(all_possible_player_sets)
          player_set = all_possible_player_sets{i};
          varname = strcat('V_', player_set.label());
          varname = matlab.lang.makeValidName(varname);
          syms(varname)
          V_cache(i) = eval(varname);
          assume(V_cache(i), 'real');
          fprintf('Created variable: %s\n', varname);
        end
      end

      V = V_cache;
    end

    function state_value = get_state_value(player_set)
      % プレイヤセットに対する状態価値関数を取得する
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤセット
      %
      % Returns:
      %   state_value (symbolic): プレイヤセットに対する状態価値関数
      V = VariablesHelper.init_state_values();
      state_value = V(player_set.index());
    end

    function x = init_expected_utilities()
      % 期待効用の初期化
      %
      % Parameters: None
      %
      % Returns:
      %   x (symbolic): 期待効用のシンボリック変数の配列
      
      persistent x_cache;

      if isempty(x_cache)
        all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
        all_possible_players = Player.get_all_possible_players();
        x_cache = sym(zeros(length(all_possible_player_sets), length(all_possible_players)));
        for i = 1:length(all_possible_player_sets)
          player_set = all_possible_player_sets{i};
          for j = 1:length(all_possible_players)
            player = all_possible_players{j};
            varname = strcat('x_', player_set.label(), '_', player.label());
            varname = matlab.lang.makeValidName(varname);
            syms(varname)
            x_cache(i, j) = eval(varname);
            assume(x_cache(i, j), 'real');
            fprintf('Created expected utility variable: %s\n', varname);
          end
        end
      end

      x = x_cache;
    end

    function expected_utility = get_expected_utility(player_set, player)
      % プレイヤセットとプレイヤに対する期待効用を取得する
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤセット
      %   player (Player): プレイヤ
      %
      % Returns:
      %   expected_utility (symbolic): プレイヤセットとプレイヤに対する期待効用
      x = VariablesHelper.init_expected_utilities();
      expected_utility = x(player_set.index(), player.index());
    end

    function expected_utility = get_solution_expected_utility(player_set, player, solution)
      % プレイヤ集合とプレイヤに対する期待効用の解を取得する
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤセット
      %   player (Player): プレイヤ
      %   solution (ExpectedUtilitySolution): 解
      % Returns:
      %   expected_utility (symbolic | numeric): プレイヤセットとプレイヤに対する期待効用の解

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
