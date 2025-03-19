classdef ExpectedUtilityHelper
  methods (Static)
    % シンボリック変数の期待効用行列を生成する関数
    function x = generate_expected_utility_matrix()
      all_player_sets = PlayerSet.get_all_player_sets();
      all_players = Player.get_all_players();
      x = sym(zeros(length(all_player_sets), length(all_players)));
      var_names = {};

      % Step 1: その場に存在しており、タクシーが空車状態における期待効用を計算
      disp('Step 1: その場に存在しており、タクシーが空車状態における期待効用を計算');
      for i = 1:length(all_player_sets)
        player_set = all_player_sets{i};
        disp(strcat('Step 1: ', num2str(i), '/', num2str(length(all_player_sets))));
        for j = 1:length(all_players)
          player = all_players{j};

          if ~player_set.is_present(player)
            continue;
          end

          if player_set.is_all_taxis_empty_after_just_m_steps(0)
            var_name = strcat('x_', sprintf('%02d', j), '_', sprintf('%02d', i));
            var_names{end+1} = var_name;
            syms(var_name, 'positive');
            x(i, j) = eval(var_name);
          end
        end
      end

      % Step 2: その場に存在しており、タクシーが1ステップ後に空車である状態における期待効用は、1ステップ経過後の状態における期待効用と等しい
      disp('Step 2: その場に存在しており、タクシーが1ステップ後に空車である状態における期待効用を計算');
      for i = 1:length(all_player_sets)
        player_set = all_player_sets{i};
        disp(strcat('Step 2: ', num2str(i), '/', num2str(length(all_player_sets))));
        for j = 1:length(all_players)
          player = all_players{j};

          if ~player_set.is_present(player)
            continue;
          end

          if player_set.is_all_taxis_empty_after_just_m_steps(1)
            player_set_one_step_elapsed = player_set.one_step_elapsed();
            player_one_step_elapsed = player.one_step_elapsed();
            ii = player_set_one_step_elapsed.index();
            jj = player_one_step_elapsed.index();
            if isAlways(x(ii, jj) == 0)
              disp("expected utility is not calculated for " + player_one_step_elapsed.id + " in " + player_set_one_step_elapsed.id);
              error('期待効用が計算されていない変数を参照しようとしています');
            end
            x(i, j) = x(ii, jj);
          end
        end
      end

      % Step 3: その場に存在しており、タクシーがm>=2ステップ後に空車になる状態における期待効用を計算
      disp('Step 3: その場に存在しており、タクシーがm>=2ステップ後に空車になる状態における期待効用を計算');
      for m = 2:4
        for i = 1:length(all_player_sets)
          disp(strcat('Step 3: ', num2str(m), '/4, ', num2str(i), '/', num2str(length(all_player_sets))));
          player_set = all_player_sets{i};
          for j = 1:length(all_players)
            player = all_players{j};

            if ~player_set.is_present(player)
              continue;
            end
  
            if player_set.is_all_taxis_empty_after_just_m_steps(m)
              equation = Equation(player, player_set);
              value = equation.calculate_right_side(x);
              if isAlways(value == 0)
                disp("expected utility is 0 for " + player.id + " in " + player_set.id);
                error('プレイヤは存在しているが、期待効用が0です');
              end
              % x(i,j)の数式から、x_%d+_%d+にマッチする部分を全て取得する
              matched_vars = regexp(char(value), 'x_\d+_\d+', 'match');
              if isempty(matched_vars)
                assignin('base', 'value', value);
                assignin('base', 'x', x);
                assignin('base', 'i', i);
                assignin('base', 'j', j);
                error('未定義の変数が参照されている可能性があります');
              end
              %  matched_varsのうち、一つでもvar_namesに含まれていないものがあればエラー
              for k = 1:length(matched_vars)
                if ~ismember(matched_vars{k}, var_names)
                  assignin('base', 'x', x);
                  assignin('base', 'i', i);
                  assignin('base', 'j', j);
                  assignin('base', 'player', player);
                  assignin('base', 'player_set', player_set);
                  disp(matched_vars{k} + " is not in " + strjoin(var_names, ', '));
                  error('未定義の変数が参照されています');
                end
              end
              x(i, j) = value;
            end            
          end
        end
      end

      % Step 4: その場に存在しないプレイヤの期待効用は0で、存在するプレイヤの期待効用は既に計算済みかを確認
      disp('Step 4: その場に存在しないプレイヤの期待効用は0');
      for i = 1:length(all_player_sets)
        player_set = all_player_sets{i};
        disp(strcat('Step 0: ', num2str(i), '/', num2str(length(all_player_sets))));
        for j = 1:length(all_players)
          player = all_players{j};

          if player_set.is_present(player)
            if isAlways(x(i, j) == 0)
              disp(player.id + "is in " + player_set.id + " but expected utility is 0");
              error('期待効用が計算されていないプレイヤが存在します');
            end

            % x(i,j)の数式から、x_%d+_%d+_euにマッチする部分を全て取得する
            matched_vars = regexp(char(x(i, j)), 'x_\d+_\d+', 'match');
            if isempty(matched_vars)
              assignin('base', 'x', x);
              assignin('base', 'i', i);
              assignin('base', 'j', j);
              error('未定義の変数が参照されている可能性があります');
            end
            %  matched_varsのうち、一つでもvar_namesに含まれていないものがあればエラー
            for k = 1:length(matched_vars)
              if ~ismember(matched_vars{k}, var_names)
                disp(matched_vars{k} + " is not in " + strjoin(var_names, ', '));
                error('未定義の変数が参照されています');
              end
            end
          else
            if isAlways(x(i, j) ~= 0)
              disp(player.id + "is not in " + player_set.id + " but expected utility is not 0");
              error('期待効用が0であるべきだが、0でないケースが存在します');
            end
          end
        end
      end
    end

    % player_setにおけるplayerの期待効用変数を取得する関数
    function expected_utility = get_expected_utility(player, player_set, x)
      player_index = player.index();
      player_set_index = player_set.index();
      expected_utility = x(player_set_index, player_index);
    end

    % 期待効用の計算結果を表示する関数
    function show_result(x, sol, conditions)
      [w, c, r_0, a, p, p_] = ParamsHelper.getSymbolicParams();
      params = [w, c, r_0(1), r_0(2), r_0(3), a(1), a(2), a(3), p(1), p(2), p(3), ...
                p_(1,1), p_(1,2), p_(1,3), p_(2,1), p_(2,2), p_(2,3), p_(3,1), p_(3,2), p_(3,3)];
      [w_v, c_v, r_0_v, a_, p_v, p__v] = ParamsHelper.getValuedParams();
      params_valued = [w_v, c_v, r_0_v(1), r_0_v(2), r_0_v(3), a_(1), a_(2), a_(3), p_v(1), p_v(2), p_v(3), ...
                       p__v(1,1), p__v(1,2), p__v(1,3), p__v(2,1), p__v(2,2), p__v(2,3), p__v(3,1), p__v(3,2), p__v(3,3)];
  
      is_valid = Equation.is_valid_sol(sol);
      if ~is_valid
          return;
      end
  
      constraints = Equation.validate_sol(sol, conditions);
      for i = 1:length(constraints)
        constraint = constraints{i};
        constraint_evaluated = subs(constraint, params, params_valued);
        if ~isAlways(constraint_evaluated)
          fprintf('条件%d: %sは満たされていません\n', i, char(constraint));
          fprintf(char(constraint_evaluated));
          return;
        end
      end

      disp(fprintf('次の解は次の条件を満たすことを確認しました'));
      disp(sol);
      disp(conditions);
  
      x_valued = subs(subs(x, sol), params, params_valued);
  
      all_player_sets = PlayerSet.get_all_player_sets();
      all_players = Player.get_all_players();
      num_players = length(all_players);
      num_player_sets = length(all_player_sets);
      
      % 1つのfigureを作成
      figure;
      
      % サブプロットの行数・列数を決定（できるだけ正方形に近づける）
      num_cols = 5;
      num_rows = ceil(num_player_sets / num_cols);
  
      for i = 1:num_player_sets
        player_set = all_player_sets{i};
        
        % 各 player_set に対する期待効用を格納
        expected_utilities = zeros(1, num_players);
        
        for j = 1:num_players
            expected_utilities(j) = x_valued(i, j);
        end
        
        % subplot でグラフを配置
        subplot(num_rows, num_cols, i);
        bar(expected_utilities);
        
        % 軸とタイトルの設定
        title(sprintf('%s', player_set.id()));
        xticklabels(Player.ids(all_players));
        xtickangle(45);
        ylim([0, 5000]);
        grid on;

        for j = 1:num_players
          if (expected_utilities(j) == 0)
            continue;
          end
          text(j, expected_utilities(j) + 0.02, sprintf('%.3f', expected_utilities(j)), ...
               'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10);
        end
      end
    end
  end
end
