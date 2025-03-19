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

  fid = fopen('data/condition_candidates.txt', 'w');
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
          fprintf(fid, '%s -> %s: %s\n\n', player_matching_set.id(), player_matching.id(), char(condition));
        end
      end
    end
  end
  fclose(fid);

  all_conditions = generate_all_matching_combinations(condition_candidates_set);

  save('data/all_conditions.mat', 'all_conditions');
else
  disp('Load all conditions from all_conditions.mat');
  data = load('data/all_conditions.mat', 'all_conditions');
  all_conditions = data.all_conditions;
end

fid = fopen('data/solutions.txt', 'w');
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
  fprintf(fid, "マッチング集合" + num2str(i) + "の条件下での解\n");
  disp("条件")
  fprintf(fid, "条件\n");
  for j = 1:length(conditions)
    disp(j + ":  " + string(conditions(j)));
    fprintf(fid, j + ":  " + string(conditions(j)) + "\n");
    fprintf(fid, "\n");
  end
  disp("期待効用方程式")
  fprintf(fid, "期待効用方程式\n");
  disp("v1")
  fprintf(fid, "v1\n");
  [eqs_v1, all_vars_v1] = Equation.build_equations(equations_v1, x, conditions);
  for j = 1:length(eqs_v1)
    disp(eqs_v1(j));
    fprintf(fid, string(eqs_v1(j)) + "\n");
  end
  sol_v1 = Equation.solve_equations(eqs_v1, all_vars_v1)

  disp("ps2")
  fprintf(fid, "ps2\n");
  [eqs_ps2, all_vars_ps2] = Equation.build_equations(equations_ps2, x, conditions);
  for j = 1:length(eqs_ps2)
    disp(eqs_ps2(j));
    fprintf(fid, string(eqs_ps2(j)) + "\n");
  end
  sol_ps2 = Equation.solve_equations(eqs_ps2, all_vars_ps2)
  sol = merge_structs(sol_v1, sol_ps2);

  disp("ps3")
  fprintf(fid, "ps3\n");
  [eqs_ps3, all_vars_ps3] = Equation.build_equations(equations_ps3, x, conditions);
  for j = 1:length(eqs_ps3)
    disp(eqs_ps3(j));
    fprintf(fid, string(eqs_ps3(j)) + "\n");
  end
  sol_ps3 = Equation.solve_equations(eqs_ps3, all_vars_ps3)
  sol = merge_structs(sol, sol_ps3);
  is_valid = Equation.is_valid_sol(sol);
  fields = fieldnames(sol);
  fprintf(fid, "\n解: %s\n", string(is_valid));
  for ii = 1:numel(fields)
    value = sol.(fields{ii});  % フィールドの値を取得
    fprintf(fid, '%s: %s\n', fields{ii}, string(value));  
  end
  constraints = Equation.validate_sol(sol, conditions);
  disp("制約条件")
  fprintf(fid, "\n制約条件\n");
  for j = 1:length(constraints)
    disp(constraints{j});
    fprintf(fid, string(constraints{j}) + "\n");
  end
  ExpectedUtilityHelper.show_result(x, sol, conditions);
  fprintf(fid, "---------------------------------\n\n\n");
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

function merged = merge_structs(s1, s2)
  merged = s1;
  fields = fieldnames(s2);
  for i = 1:numel(fields)
      merged.(fields{i}) = s2.(fields{i});
  end
end