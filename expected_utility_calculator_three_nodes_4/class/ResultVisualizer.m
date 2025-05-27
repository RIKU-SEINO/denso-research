classdef ResultVisualizer
  % ResultVisualizer クラス
  %
  % シミュレーション結果を可視化する静的メソッドを提供するクラス
  % 

  % 状態価値関数関連の結果表示
  methods (Static)
    function display_state_values_as_graphs(solutions, policies, is_optimal)
      % プレイヤ集合の状態価値関数をグラフとして表示する
      %
      % Parameters:
      %   solutions (cell): 各方策に対する状態価値関数の解
      %   policies (cell): 各方策の情報
      %   is_optimal (logical): 最適な方策かどうかのフラグ
      %
      % Returns:
      %   None

      for i = 1:length(solutions)
        fprintf('π_%d: %s の遷移グラフを作成中...\n', i, policies{i}.label);
        solution = solutions{i};
        policy = policies{i};
        if is_optimal(i)
          optimal_str = 'true';
        else
          optimal_str = 'false';
        end
        
        % グラフを生成
        player_set_graph = PlayerSetGraph(solution, policy);
        
        % グラフを表示
        fig = player_set_graph.plot_graph();
        title(['\pi_{', num2str(i), '} (Optimal: ', optimal_str, ') の下でのマルコフ決定過程の遷移グラフ'], ...
          'Interpreter', 'tex');
        exportgraphics(fig, sprintf('result/policy_%d_state_value_graph.png', i));
      end
    end

    function display_state_values_as_bar(solutions, is_optimal)
      % プレイヤ集合の状態価値関数を棒グラフとして表示する
      %
      % Parameters:
      %   solutions (cell): 各方策に対する状態価値関数の解
      %   is_optimal (logical): 最適な方策かどうかのフラグ
      %
      % Returns:
      %   None

      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      num_cols = ceil(sqrt(length(solutions)));
      num_rows = ceil(length(solutions) / num_cols);
      max_value = max(cell2mat(cellfun(@(x) cell2mat(struct2cell(x)), solutions, 'UniformOutput', false)));
      min_value = min(cell2mat(cellfun(@(x) cell2mat(struct2cell(x)), solutions, 'UniformOutput', false)));
      fig = figure('Units', 'pixels', 'Position', [0, 0, 3000, 2000]);
      for i = 1:length(solutions)
        subplot(num_rows, num_cols, i);
        solution = solutions{i};
        if is_optimal(i)
          optimal_str = 'true';
        else
          optimal_str = 'false';
        end
        
        state_values = cell2mat(struct2cell(solution));
        bar(state_values);
        
        title(['\pi_{', num2str(i), '}（Optimal: ', optimal_str, '）'], ...
          'Interpreter', 'tex');    
        xticks(1:length(all_possible_player_sets));
        xticklabels(PlayerSet.labels(all_possible_player_sets));
        xtickangle(90);
        ylim([min_value*1.2, max_value*1.8]);
        ytickformat('%,.0f');
        grid on;

        adjusted_value = min(max(max(state_values), 0), max_value) + max_value*0.5;
        for j = 1:length(fieldnames(solution))
          text(j+0.4, adjusted_value, sprintf('%.0f', state_values(j)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 7,  'Rotation', 90);
        end
      end
      sgtitle('方策ごとの状態価値関数');
      exportgraphics(fig, 'result/state_value_bar.png', 'Resolution', '300');
    end

    function display_max_state_value_with_policy_color_p2_p3(solutions_symbolic)
      % 方策ごとの状態価値関数をp2, p3の関数として評価し、
      % 最大の状態価値を与える方策ごとに色分けして表示する
  
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      fields = fieldnames(solutions_symbolic{1});
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        disp(player_set.label());
        funcs = cellfun(@(x) x.(fields{i}), solutions_symbolic, 'UniformOutput', false);
        Utils.plot_max_symbolic_funcs_3d(funcs, ["p_2", "p_3"], [0, 1], [0, 1], 500);
        title(sprintf('Player Set: %s', player_set.label()));
      end
    end
  end        

  methods (Static)
    function display_expected_utilities_as_bar(solutions, is_optimal)
      % 各policyを採用した場合の、プレイヤ集合ごとの各プレイヤの期待効用を棒グラフとして表示する
      %
      % Parameters:
      %   solution (struct): 期待効用方程式の解
      %   is_optimal (cell<logical>): 最適な方策かどうかのフラグ
      %
      % Returns:
      %   None

      all_possible_taxi_sets = PlayerSet.get_all_possible_taxis_sets();
      all_possible_passenger_sets = PlayerSet.get_all_possible_passenger_sets();
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      all_possible_players = Player.get_all_possible_players();

      num_cols = length(all_possible_taxi_sets);
      num_rows = length(all_possible_passenger_sets);

      max_value = max(cell2mat(cellfun(@(x) cell2mat(struct2cell(x)), solutions, 'UniformOutput', false)));
      min_value = min(cell2mat(cellfun(@(x) cell2mat(struct2cell(x)), solutions, 'UniformOutput', false)));
      x = VariablesHelper.init_expected_utilities();

      for policy_index = 1:length(solutions)
        solution = solutions{policy_index};
        if is_optimal(policy_index)
          optimal_str = 'true';
        else
          optimal_str = 'false';
        end
        x_evaluated = double(subs(x, fieldnames(solution), struct2cell(solution)));
  
        fig = figure('Units', 'pixels', 'Position', [0, 0, 3000, 2000]);
        for i = 1:size(x_evaluated, 1)
          player_set = all_possible_player_sets{i};
          subplot(num_cols, num_rows, i);
          expected_utilities = x_evaluated(i, :);
          % 棒グラフを生成
          bar(expected_utilities);
          % タイトルとラベルを設定
          title_str = sprintf('Player Set: %s', player_set.label());
          title(title_str);
          xticks(1:length(all_possible_players));
          xticklabels(Player.labels(all_possible_players));
          xtickangle(90);
          ylim([min_value*1.2, max_value*1.2]);
          grid on;
          adjusted_value = min(max(max(expected_utilities), 0), max_value) + max_value*0.1;
          for j = 1:length(all_possible_players)
            text(j, adjusted_value, sprintf('%.0f', expected_utilities(j)), ...
              'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 7,  'Rotation', 0); 
          end
        end
        sgtitle(['\pi_{', num2str(policy_index), '} (Optimal: ', optimal_str, ') の下での期待効用'], ...
          'Interpreter', 'tex');  
        exportgraphics(fig, sprintf('result/policy_%d_expected_utilities.png', policy_index));
      end
    end
  end
end
  