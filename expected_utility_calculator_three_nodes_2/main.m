clear;

addpath('./class');
warning('off', 'all');

disp('Generate expected utility matrix (y/n): ')
generate_x = input('', 's') == 'y';
disp('Generate condition candidates (y/n): ')
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

all_player_sets = PlayerSet.get_all_player_sets();
all_players = Player.get_all_players();

if construct_expected_utility_matrix
  condition_candidates_set = {};
  equations_set = {};

  for i = 1:length(all_players)
    player = all_players{i};
    for j = 1:length(all_player_sets)
      disp(strcat(num2str(i), '/', num2str(length(all_players)), ', ', num2str(j), '/', num2str(length(all_player_sets)), ': 条件分岐式を構築中...'));
      player_set = all_player_sets{j};

      if ~player_set.is_present(player)
        continue;
      end
      
      if ~player_set.is_all_taxis_empty_after_just_m_steps(0)
        continue;
      end

      all_player_matching_candidates = player_set.get_all_player_matchings();
      player_matching_set = PlayerMatchingSet(all_player_matching_candidates);
      [~, condition_candidates] = player_matching_set.calculate_expected_utility_candidates_of_player(player, x);

      if ~ismember_condition_candidates(condition_candidates, condition_candidates_set) && ~isequal(condition_candidates{1}, symtrue)
        condition_candidates_set{end+1, 1} = condition_candidates;
        for k = 1:length(condition_candidates)
          condition = condition_candidates{k};
          player_matching = player_matching_set.player_matchings{k};
          % matching_set_id -> matching_id: conditionというフォーマットで保存
          fid = fopen('data/condition_candidates.txt', 'a');
          fprintf(fid, '%s -> %s: %s\n\n', player_matching_set.id(), player_matching.id(), char(condition));
          fclose(fid);
        end
      end
    end
  end

  all_conditions = generate_all_matching_combinations(condition_candidates_set);

  save('data/all_conditions.mat', 'all_conditions');
else
  disp('Load all conditions from all_conditions.mat');
  data = load('data/all_conditions.mat', 'all_conditions');
  all_conditions = data.all_conditions;
end


for i = 1:length(all_conditions)
  % equations = {};
  equations_v1 = {};
  equations_ps2 = {};
  equations_ps3 = {};
  conditions = all_conditions{i};
  for j = 1:length(all_player_sets)
    player_set = all_player_sets{j};
    for k = 1:length(all_players)
      player = all_players{k};
      if ~player_set.is_present(player)
        continue;
      end

      if ~player_set.is_all_taxis_empty_after_just_m_steps(0)
        continue;
      end

      equation = Equation(player, player_set);
      if player.is_taxi()
        equations_v1{end+1, 1} = equation;
      elseif player.is_passenger() && player.node == 2
        equations_ps2{end+1, 1} = equation;
      elseif player.is_passenger() && player.node == 3
        equations_ps3{end+1, 1} = equation;
      end
    end
  end
  disp("マッチング集合" + num2str(i) + "の条件下での解を計算中...")
  disp("条件")
  for j = 1:length(conditions)
    disp(conditions(j));
  end
  % sol = Equation.solve_equations(equations, x, conditions);
  sol_v1 = Equation.solve_equations(equations_v1, x, conditions);
  sol_v1
  sol_ps2 = Equation.solve_equations(equations_ps2, x, conditions);
  sol_ps2
  sol_ps3 = Equation.solve_equations(equations_ps3, x, conditions);
  sol_ps3
  % Equation.validate_sol(sol, conditions);
  disp('---------------------------------')
end

function combinations = generate_all_matching_combinations(condition_candidates_set)
  num_sets = length(condition_candidates_set);
  num_choices = zeros(1, num_sets);
  
  % 各要素の選択肢の数を取得
  for i = 1:num_sets
    num_choices(i) = length(condition_candidates_set{i});
  end
  
  % すべての組み合わせを生成
  total_combinations = prod(num_choices);
  combinations = cell(total_combinations, 1);
  choice_indices = ones(1, num_sets);
  
  for i = 1:total_combinations
    current_combination = {};
    for j = 1:num_sets
      current_combination = [current_combination; condition_candidates_set{j}{choice_indices(j)}];
    end
    combinations{i} = current_combination;

    % 選択肢のインデックスを更新
    choice_indices(1) = choice_indices(1) + 1;
    for j = 1:num_sets
      if choice_indices(j) > num_choices(j)
        choice_indices(j) = 1;
        if j < num_sets
          choice_indices(j + 1) = choice_indices(j + 1) + 1;
        end
      end
    end
  end

  % combined_combinations = cell(total_combinations, 1);
  % for i = 1:total_combinations
  %     combined_expression = combinations{i}(1); % 最初の要素で初期化
  %     for j = 2:length(combinations{i})
  %         combined_expression = and(combined_expression, combinations{i}(j)); % 論理積で結合
  %     end
  %     combined_combinations{i} = simplify(combined_expression);
  % end
  % combinations = combined_combinations;
end

function result = ismember_condition_candidates(condition_candidates, condition_candidates_set)
  result = false;
  for i = 1:length(condition_candidates_set)
    if isequal(condition_candidates, condition_candidates_set{i})
      result = true;
      return;
    end
  end
end