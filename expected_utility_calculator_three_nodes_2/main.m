clear;

addpath('./class');

disp('Generate expected utility matrix (y/n): ')
generate_x = input('','s') == 'y';
if generate_x
  x = ExpectedUtilityHelper.generate_expected_utility_matrix();
  save('data/data.mat', 'x');
end

% 考えられる全てのプレイヤ集合を取得
all_player_sets = PlayerSet.get_all_player_sets();
for i = 1:length(all_player_sets)
  player_set = all_player_sets{i};

  if isempty(player_set.get_empty_taxis())
    continue;
  end
  disp("--------------------");
  disp(string(i) + "/" + string(length(all_player_sets)));

    
  [player_matching_candidates, expected_utility_sum_candidates] = player_set.get_player_matching_candidates();
  for k = 1:length(player_matching_candidates)
    player_matching = player_matching_candidates{k};
    expected_utility_sum = expected_utility_sum_candidates(k);
    % player_matching.idはchar
    % expected_utility_sumはsymであることに注意。doubleには変換できない。
    % disp(player_matching.id + ": " + expected_utility_sum);だとエラーになる
    disp(player_matching.id + ": " + char(expected_utility_sum));
  end
end
