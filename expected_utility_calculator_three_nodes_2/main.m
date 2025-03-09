clear;

addpath('./class');

disp('Generate expected utility matrix (y/n): ')
generate_x = input('','s') == 'y';
if generate_x
  x = ExpectedUtilityHelper.generate_expected_utility_matrix();
  save('data/data.mat', 'x');
  writematrix(string(x), 'data/x.csv');
end

% all_player_sets = PlayerSet.get_all_player_sets();
% all_players = Player.get_all_players();
% for i = length(all_player_sets):-1:1
%   player_set = all_player_sets{i};
%   for j = length(all_players):-1:1
%     player = all_players{j};
%     disp(num2str(i) + " / " + num2str(length(all_player_sets)) +", "+ num2str(j) + " / " + num2str(length(all_players)))
%     disp(player.id + " in " + player_set.id);
%     equation = Equation(player, player_set);
%   end
% end


% % 考えられる全てのプレイヤ集合を取得
% all_player_sets = PlayerSet.get_all_player_sets();
% for i = 1:length(all_player_sets)
%   player_set = all_player_sets{i};

%   if isempty(player_set.get_empty_taxis())
%     continue;
%   end
%   disp("--------------------");
%   disp(string(i) + "/" + string(length(all_player_sets)));

    
%   [player_matching_candidates, expected_utility_sum_candidates] = player_set.get_player_matching_candidates();
%   for k = 1:length(player_matching_candidates)
%     player_matching = player_matching_candidates{k};
%     expected_utility_sum = expected_utility_sum_candidates(k);
%     % player_matching.idはchar
%     % expected_utility_sumはsymであることに注意。doubleには変換できない。
%     % disp(player_matching.id + ": " + expected_utility_sum);だとエラーになる
%     disp(player_matching.id + ": " + char(expected_utility_sum));
%   end
% end
