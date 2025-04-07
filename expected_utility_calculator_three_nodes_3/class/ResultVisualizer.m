classdef ResultVisualizer
  % ResultVisualizer クラス
  %
  % シミュレーション結果を可視化するクラス。
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
        fprintf('Policy %d: %s の遷移グラフを作成中...\n', i, policies{i}.label);
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
        player_set_graph.plot_graph();
        title_str = sprintf('Policy: %d, Optimal: %s', i, optimal_str);
        title(title_str);
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
      figure;
      for i = 1:length(solutions)
        subplot(num_rows, num_cols, i);
        solution = solutions{i};
        if is_optimal(i)
          optimal_str = 'true';
        else
          optimal_str = 'false';
        end
        
        state_values = cell2mat(struct2cell(solution));
        % 棒グラフを生成
        bar(state_values);
        
        % タイトルとラベルを設定
        title_str = sprintf('State Values based on Policy: %d, Optimal: %s', i, optimal_str);
        title(title_str);
        xticks(1:length(all_possible_player_sets));
        xticklabels(PlayerSet.labels(all_possible_player_sets));
        xtickangle(90);
        ylim([min_value*1.2, max_value*1.2]);
        grid on;

        adjusted_value = min(max(max(state_values), 0), max_value) + max_value*0.1;
        for j = 1:length(fieldnames(solution))
          text(j, adjusted_value, sprintf('%.0f', state_values(j)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 7,  'Rotation', 45);
        end
      end
    end
  end
end
  