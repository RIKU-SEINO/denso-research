clc; clear; close;
addpath('./class')
addpath('./func')

player_set_initial = PlayerSet({
  Player('v', 1, 0, 0)
});

all_possible_policies = Policy.get_all_possible_policies();
colors = jet(length(all_possible_policies));

% --- Social Utility Figure ---
figure(1); hold on;
title('Cumulative Social Utility');
xlabel('Time Step'); ylabel('Social Utility');

% --- Taxi Utility Figure ---
figure(2); hold on;
title('Cumulative Taxi Utility');
xlabel('Time Step'); ylabel('Taxi Utility');

% --- Passenger Utility Figures ---
% WIP

for policy_index = 1:length(all_possible_policies)
  policy = all_possible_policies{policy_index};
  result = simulate(policy, player_set_initial);

  cs = result.utilities_social_cumulative;
  ct = result.utilities_taxi_cumulative;
  tspan = 0:length(cs)-1;

  % 図1：Social Utility
  figure(1);
  plot(tspan, cs, 'LineWidth', 2, 'Color', colors(policy_index, :));

  % 図2：Taxi Utility
  figure(2);
  plot(tspan, ct, 'LineWidth', 2, 'Color', colors(policy_index, :));

  % 図3〜: Passenger Utility  
  % WIP
end

legend_labels = "Policy " + (1:length(all_possible_policies));
figure(1); legend(legend_labels, 'Location', 'best');
figure(2); legend(legend_labels, 'Location', 'best');


function result = simulate(policy, player_set_initial)
  player_set = player_set_initial;

  taxi = player_set.get_taxi(); % タクシーは1台で固定

  utilities_social = 0;
  utilities_taxi = 0;

  t_max = 200;
  for i = 1:t_max
    fprintf('Policy %d, Step %d/%d\n', policy.index, i, t_max)

    % 方策に従いマッチングを決定
    player_matching = policy.get_player_matching_by_player_set(player_set);

    % 即時報酬を獲得
    utilities_social = [utilities_social, player_matching.get_utility_sum('numeric')];
    utilities_taxi = [utilities_taxi, player_matching.get_utility_of_player(taxi, 'numeric')];

    % マッチングを採用
    player_set_after_matching = player_matching.get_player_set_after_matching();
    taxi_after_matching = player_matching.get_player_after_matching(taxi);

    % 1ステップ経過
    player_set_one_step_elapsed = player_set_after_matching.one_step_elapsed();
    taxi_after_one_step_elapsed = taxi_after_matching.one_step_elapsed();

    % 乗客が出現
    player_set_after_passenger_emerged = player_set_one_step_elapsed.passenger_emerged();

    player_set = player_set_after_passenger_emerged;
    taxi = taxi_after_one_step_elapsed;
  end

  % 結果
  result = struct( ...
    'utilities_social_cumulative', cumsum(utilities_social), ...
    'utilities_taxi_cumulative', cumsum(utilities_taxi)...
  );
end