clear;

addpath('./class');
warning('off', 'all');

disp('Generate expected utility matrix (y/n): ')
generate_x = input('', 's') == 'y';
disp('Construct expected utility matrix from scratch? (y/n): ');
construct_expected_utility_matrix = input('', 's') == 'y';
if generate_x
    x = ExpectedUtilityHelper.generate_expected_utility_matrix();
    save('data/data.mat', 'x');
    writematrix(string(x), 'data/x.csv');
else
    disp('Load expected utility matrix from data.mat');
    data = load('data/data.mat', 'x');
    x = data.x;
end

% 全ての期待効用方程式を構築する
if construct_expected_utility_matrix
  equations = {};
  all_player_sets = PlayerSet.get_all_player_sets();
  all_players = Player.get_all_players();

  for i = 1:length(all_players)
    player = all_players{i};
    for j = 1:length(all_player_sets)
      disp(strcat(num2str(i), '/', num2str(length(all_players)), ', ', num2str(j), '/', num2str(length(all_player_sets)), '期待効用方程式を構築中...'));
      player_set = all_player_sets{j};

      if ~player_set.is_present(player)
          continue;
      end
      
      if ~player_set.is_all_taxis_empty_after_just_m_steps(0)
          continue;
      end

      equation = Equation(player, player_set, x);
      equations{end+1} = equation;
    end
  end

  save('data/equations.mat', 'equations');
else
  disp('Load equations from equations.mat');
  data = load('data/equations.mat', 'equations');
  equations = data.equations;
end

