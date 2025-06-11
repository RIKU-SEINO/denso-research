clc; clear; close all;
addpath('./class')
addpath('./func')
mkdir 'simulation_result';

player_set_initial = PlayerSet({
  Player('v', 1, 0, 0)
});

all_possible_policies = Policy.get_all_possible_policies();
colors = jet(length(all_possible_policies));

passengers = Player.get_all_possible_passengers();

% --- Social Utility Figure ---
figure(1); hold on;
title('社会全体の効用の累積和の推移');
xlabel('Time Step'); ylabel('Utility');

% --- Taxi Utility Figure ---
figure(2); hold on;
title('タクシーの効用の累積和の推移');
xlabel('Time Step'); ylabel('Utility');

for i = 1:length(passengers)
  passenger = passengers{i};
  figure(2+i);
  title(sprintf('乗客%sの効用の累積和の推移', passenger.label));
  xlabel('Time Step'); ylabel('Utility');
end

% --- Passenger Utility Figures ---
% WIP

for policy_index = 1:length(all_possible_policies)
  policy = all_possible_policies{policy_index};
  result = simulate(policy, player_set_initial);

  cs = result.utilities_social_cumulative;
  ct = result.utilities_taxi_cumulative;
  hp = result.utilities_passengers;
  tspan = 0:length(cs)-1;

  % 図1：Social Utility
  figure(1);
  plot(tspan, cs, 'LineWidth', 2, 'Color', colors(policy_index, :));

  % 図2：Taxi Utility
  figure(2);
  plot(tspan, ct, 'LineWidth', 2, 'Color', colors(policy_index, :));

  % 図3〜: Passenger Utility  
  for i = 1:length(passengers)
    passenger = passengers{i};
    utilities_passenger = hp(passenger.label);
    figure(2+i);
    hold on;
    plot(tspan, cumsum(utilities_passenger), 'LineWidth', 2, 'Color', colors(policy_index, :));
  end
end

% scale
ymax = -inf;
ymin = inf;

figHandles = findall(0, 'Type', 'figure'); % 開いてるすべてのfigureを取得

for i = 1:length(figHandles)
    figure(figHandles(i));
    ax = gca; % 現在のaxes
    lines = findall(ax, 'Type', 'line'); % figure内の全lineオブジェクト
    for j = 1:length(lines)
        ydata = get(lines(j), 'YData');
        ymax = max([ymax, max(ydata)]);
        ymin = min([ymin, min(ydata)]);
    end
end

% --- 全てのfigureのscaleを揃える
for i = 1:length(figHandles)
    figure(figHandles(i));
    ylim([ymin, ymax]);
end

legend_labels = arrayfun(@(i) sprintf('\\pi_{%d}', i), 1:length(all_possible_policies), 'UniformOutput', false);
figure(1); legend(legend_labels, 'Location', 'northwest', 'Interpreter', 'tex'); grid on;
exportgraphics(figure(1), 'simulation_result/social_utility_cumulative.png');
figure(2); legend(legend_labels, 'Location', 'northwest', 'Interpreter', 'tex'); grid on;
exportgraphics(figure(2), 'simulation_result/taxi_utility_cumulative.png');
for i = 1:length(passengers)
  figure(2+i); legend(legend_labels, 'Location', 'northwest', 'Interpreter', 'tex'); grid on;
  exportgraphics(figure(2+i), sprintf('simulation_result/passenger_%s_utility_cumulative.png', passengers{i}.label));
end

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

  t_max = 50;
  for i = 1:t_max
    fprintf('方策π_%d, Time Step %d/%d\n', policy.index, i, t_max)

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