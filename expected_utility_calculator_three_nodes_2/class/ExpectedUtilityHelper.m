classdef ExpectedUtilityHelper
  methods (Static)
    % シンボリック変数の期待効用行列を生成する関数
    function mat = generate_expected_utility_matrix()
      all_player_sets = PlayerSet.get_all_player_sets();
      all_players = Player.get_all_players();
      mat = sym(zeros(length(all_player_sets), length(all_players)));

      for i = 1:length(all_player_sets)
        disp(num2str(i) + " / " + num2str(length(all_player_sets)) + "個目のプレイヤ集合における期待効用変数を生成中...")
        
        for j = 1:length(all_players)
          var_name = strcat('x_', num2str(j), '_', num2str(i));
          
          % シンボリック変数を格納
          mat(i, j) = str2sym(var_name);
          assume(mat(i, j), 'positive');
        end
      end
    end

    % player_setにおけるplayerの期待効用変数を取得する関数
    function expected_utility = get_expected_utility(player, player_set, x)

      player_index = player.index();
      player_set_index = player_set.index();
      expected_utility = x(player_set_index, player_index);
    end
  end
end
