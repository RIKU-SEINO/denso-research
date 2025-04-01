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
  end
end
