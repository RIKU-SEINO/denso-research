clear;

addpath('./class');

disp('Generate expected utility matrix (y/n): ')
generate_x = input('','s') == 'y';
if generate_x
  x = ExpectedUtilityHelper.generate_expected_utility_matrix();
  save('data/data.mat', 'x');
end

all_player_sets = PlayerSet.get_all_player_sets();
for i = 1:length(all_player_sets)
  player_set = all_player_sets{i};
  
  player_sets_after_one_step = player_set.get_all_player_sets_after_one_step();
  for j = 1:length(player_sets_after_one_step)
    player_set_after_one_step = player_sets_after_one_step{j};
    
    player_matchings = player_set_after_one_step.get_all_player_matchings();
    for k = 1:length(player_matchings)
      player_matching = player_matchings{k};
      
      expected_utilities = player_matching.calculate_expected_utilities();
      disp(expected_utilities);
    end
  end
end
