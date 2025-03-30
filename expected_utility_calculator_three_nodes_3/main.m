addpath('./class')

v10 = Player('v', 1, 0, 0);
ps21 = Player('ps', 2, 1, 0);
ps31 = Player('ps', 3, 1, 0);

player_set = PlayerSet({v10; ps31});

player_pair = PlayerPair({v10; ps21});
player_pair2 = PlayerPair({ps31});

player_matching = PlayerMatching({player_pair; player_pair2});

ps = player_matching.get_player_set_after_matching();

player_matching.get_utility_sum()

player_set.label
disp('------------------');
player_sets_t = player_set.get_all_possible_player_sets_after_transition();
for i = 1:length(player_sets_t)
  player_set_t = player_sets_t{i};
  player_set_t.label
end