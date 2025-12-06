clc; clear; close all;
addpath('./class')
addpath('./func')
mkdir 'simulation_result';

player_set_initial = PlayerSet({
  Player('v', 1, 0, 0)
});

all_possible_policies = Policy.get_all_possible_policies();
M = length(all_possible_policies); % M=12（方策の総数）

passengers = Player.get_all_possible_passengers();

% --- Run Simulation ---
simulation_results = cell(1, M);

for policy_index = 1:length(all_possible_policies)
  policy = all_possible_policies{policy_index};
  result = simulate(policy, player_set_initial);
  simulation_results{policy_index} = result;
end

% --- Visualize Results ---
ResultVisualizer.display_simulation_results(simulation_results, all_possible_policies, passengers);

function result = simulate(policy, player_set_initial)
  player_set = player_set_initial;

  taxi = player_set.get_taxi(); % タクシーは1台で固定
  passengers = Player.get_all_possible_passengers();

  utilities_social = 0;
  utilities_taxi = 0;
  utilities_passengers = containers.Map;
  for i = 1:length(passengers)
    utilities_passengers(passengers{i}.label) = 0;
  end

  t_max = 200;
  for i = 1:t_max
    % fprintf('方策π_%d, Time Step %d/%d\n', policy.index, i, t_max)

    % 方策に従いマッチングを決定
    player_matching = policy.get_player_matching_by_player_set(player_set);

    % 即時報酬を獲得
    utilities_social = [utilities_social, player_matching.get_utility_sum('numeric')];
    utilities_taxi = [utilities_taxi, player_matching.get_utility_of_player(taxi, 'numeric')];
    for j = 1:length(passengers)
      passenger = passengers{j};
      utilities_passenger = utilities_passengers(passenger.label);
      if player_set.has(passenger)
        utilities_passenger = [utilities_passenger, player_matching.get_utility_of_player(passenger, 'numeric')];
      else
        utilities_passenger = [utilities_passenger, 0];
      end

      utilities_passengers(passenger.label) = utilities_passenger;
    end

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
    'utilities_taxi_cumulative', cumsum(utilities_taxi), ...
    'utilities_passengers', utilities_passengers ...
  );
end