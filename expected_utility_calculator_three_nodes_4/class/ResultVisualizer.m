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
          optimal_str = '(=optimal)';
        else
          optimal_str = '';
        end
        
        % グラフを生成
        player_set_graph = PlayerSetGraph(solution, policy);
        
        % グラフを表示
        fig = player_set_graph.plot_graph();
        title(['\pi_{', num2str(i), '}', optimal_str, 'の下でのマルコフ決定過程の遷移グラフ'], ...
          'Interpreter', 'tex');
        print(fig, sprintf('result/policy_%d_state_value_graph', i), '-depsc');
      end
    end

    function display_state_values_as_bar(solutions, g)
      % プレイヤ集合の状態価値関数を棒グラフとして表示する
      %
      % Parameters:
      %   solutions (cell): 各方策に対する状態価値関数の解
      %
      % Returns:
      %   None
  
      % フォント設定
      font_name = 'Times New Roman'; 
      font_size_xaxis = 18;            
      font_size_yaxis = 16;
      font_size_title = 20;          
      
      b_color = [0, 0.4470, 0.7410]; 
      
      % レイアウト設定
      margin_side   = 0.08;  % 左右の余白 (ラベル用に少し広げました: 0.05 -> 0.08)
      margin_top    = 0.03;  % 上の余白
      margin_bottom = 0.05;  % 下の余白
      
      gap_horizontal = 0.05; % グラフ間の横の隙間
      gap_vertical   = 0.09; % グラフ間の縦の隙間
      
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      num_solutions = length(solutions);
      num_cols = 2;
      num_rows = 6;
      
      % 割引率 g に応じて y_limits を切り替え
      if g == 0.95
        y_limits = [-1e4, 3.5e4];
      elseif g == 0
        y_limits = [-2e3, 7e3];
      else
        % デフォルト値（g が 0 でも 0.95 でもない場合）
        y_limits = [-1e4, 3.5e4];
      end
      
      fig = figure('Units', 'pixels', 'Position', [-191, 957, 585, 812], 'Color', 'w');
      
      % 1つのグラフの幅と高さを計算
      plot_width  = (1 - margin_side*2 - (num_cols-1)*gap_horizontal) / num_cols;
      plot_height = (1 - margin_top - margin_bottom - (num_rows-1)*gap_vertical) / num_rows;
      
      for i = 1:num_solutions
          % 現在の行と列を計算
          row_idx = ceil(i / num_cols);       
          col_idx = mod(i-1, num_cols) + 1;   
          
          % グラフの配置位置 (Left, Bottom, Width, Height) を計算
          pos_x = margin_side + (col_idx-1) * (plot_width + gap_horizontal);
          pos_y = 1 - margin_top - row_idx * plot_height - (row_idx-1) * gap_vertical;
          
          % 計算した位置にサブプロットを作成
          subplot('Position', [pos_x, pos_y, plot_width, plot_height]);
          
          solution = solutions{i};
          state_values = cell2mat(struct2cell(solution));
          
          % 棒グラフ描画
          bar(state_values, 'FaceColor', b_color, 'EdgeColor', 'none', 'BarWidth', 0.6);
          
          % 軸設定
          set(gca, 'FontName', font_name, 'FontSize', font_size_xaxis, ...
              'LineWidth', 1.5, 'Box', 'off');
          
          % タイトル
          title(['\pi_{', num2str(i), '}'], 'Interpreter', 'tex', ...
              'FontSize', font_size_title, 'FontName', font_name);
          
          % X軸ラベル
          xticks(1:length(all_possible_player_sets));
          xticklabels(PlayerSet.latex_labels_indexed(all_possible_player_sets));
          
          % 軸プロパティの詳細設定
          xaxisproperties = get(gca, 'XAxis');
          yaxisproperties = get(gca, 'YAxis');
          xaxisproperties.TickLabelInterpreter = 'latex';
          xaxisproperties.FontSize = font_size_xaxis;
          yaxisproperties.TickLabelInterpreter = 'latex';
          yaxisproperties.FontSize = font_size_yaxis;
          
          % Y軸設定
          ylim(y_limits);
          
          % Y軸の表記を科学的記数法に統一
          if max(abs(y_limits)) >= 1e3
            ax = gca;
            ax.YAxis.Exponent = 3;  % 10^3の指数表記を使用
          end
          grid on;
          ax = gca;
          ax.GridAlpha = 0.3;
      end

      % 図全体を覆う不可視のAxesを作成
      h_common = axes(fig, 'Position', [0 0 1 1], 'Visible', 'off');
      
      % テキストを配置 (X座標は余白の左寄り、Y座標は中央)
      text(h_common, margin_side * 0.2, 0.5, 'state-value', ...
          'FontName', font_name, ...
          'FontSize', font_size_title, ...
          'Interpreter', 'latex', ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'middle', ...
          'Rotation', 90);
      
      % 割引率 g から保存先ディレクトリを決定
      if nargin < 2
        % 引数で g が渡されなかった場合は、デフォルト値を ParamsHelper から取得
        [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, g, ~, ~, ~] = ParamsHelper.get_valued_params();
      end
      g_dir_suffix = sprintf('%03d', round(g * 100));      % 0   -> '000', 0.95 -> '095'
      result_g_dir = sprintf('result_g_%s', g_dir_suffix); % 例: 'result_g_000'
      if ~exist(result_g_dir, 'dir')
        mkdir(result_g_dir);
      end

      % 保存設定 (pdf形式とfig形式で保存)
      exportgraphics(fig, fullfile(result_g_dir, 'state_value_bar.pdf'), 'ContentType', 'vector');
      savefig(fig, fullfile(result_g_dir, 'state_value_bar.fig'));
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
        Utils.plot_max_symbolic_funcs_3d(funcs, ["p_2", "p_3"], [0, 1], [0, 1], 100);
        title(sprintf('player set: %s', player_set.label()));
      end
    end
  end        

  methods (Static)
    function display_expected_utilities_as_bar(solutions)
      % 各policyを採用した場合の、プレイヤ集合ごとの各プレイヤの期待効用を棒グラフとして表示する
      %
      % Parameters:
      %   solution (struct): 期待効用方程式の解
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
        % if is_optimal(policy_index)
        %   optimal_str = '(=optimal)';
        % else
        %   optimal_str = '';
        % end

        x_evaluated = double(subs(x, fieldnames(solution), struct2cell(solution)));
  
        fig = figure('Units', 'pixels', 'Position', [0, 0, 3000, 2000]);
        for i = 1:size(x_evaluated, 1)
          player_set = all_possible_player_sets{i};
          subplot(num_cols, num_rows, i);
          expected_utilities = x_evaluated(i, :);
          % 棒グラフを生成
          bar(expected_utilities);
          % タイトルとラベルを設定
          title_str = sprintf('player set: %s', player_set.latex_label());
          title(title_str, 'Interpreter', 'tex');
          xticks(1:length(all_possible_players));
          xticklabels(Player.latex_labels(all_possible_players));
          xtickangle(90);
          ylim([min_value*1.2, max_value*1.2]);
          grid on;
          adjusted_value = min(max(max(expected_utilities), 0), max_value) + max_value*0.1;
          for j = 1:length(all_possible_players)
            text(j, adjusted_value, sprintf('%.0f', expected_utilities(j)), ...
              'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 7,  'Rotation', 0); 
          end
        end
        print(fig, sprintf('result/policy_%d_expected_utilities', policy_index), '-depsc');
      end
    end

    function display_simulation_results(simulation_results, policies, passengers)
      % シミュレーション結果（社会的効用、タクシー効用、乗客効用）をグラフとして表示・保存する
      %
      % Parameters:
      %   simulation_results (cell): 各方策に対するシミュレーション結果
      %     - utilities_social_cumulative
      %     - utilities_taxi_cumulative
      %     - utilities_passengers (Map)
      %   policies (cell): 各方策の情報
      %   passengers (cell): 全乗客のリスト
      %
      % Returns:
      %   None

      % フォント設定
      font_name = 'Times New Roman'; 
      font_size_xaxis = 18;           
      font_size_yaxis = 18;
      font_size_label = 24;
      font_size_legend = 27;

      M = length(policies);
      colors = jet(M);
      pink_rgb = [1, 105/255, 180/255]; 
      if size(colors, 1) >= 8
        colors(8,:) = pink_rgb;
      end

      legend_labels = arrayfun(@(i) sprintf('$\\pi_{%d}$', i), 1:M, 'UniformOutput', false);

      % --- Figures Setup ---
      % Figure 1: Social Utility
      f_social = figure(1); clf; hold on;
      xlabel('time step'); ylabel('utility');

      % Figure 2: Taxi Utility
      f_taxi = figure(2); clf; hold on;
      xlabel('time step'); ylabel('utility');

      % Figure 3...: Passenger Utility
      f_passengers = gobjects(1, length(passengers));
      for i = 1:length(passengers)
        f_passengers(i) = figure(2+i); clf; hold on;
        xlabel('time step'); ylabel('utility');
      end

      % --- Plotting ---
      for policy_index = 1:M
        result = simulation_results{policy_index};
        cs = result.utilities_social_cumulative;
        ct = result.utilities_taxi_cumulative;
        hp = result.utilities_passengers;
        tspan = 0:length(cs)-1;

        % Plot Social Utility
        figure(f_social);
        plot(tspan, cs, 'LineWidth', 2, 'Color', colors(policy_index, :));

        % Plot Taxi Utility
        figure(f_taxi);
        plot(tspan, ct, 'LineWidth', 2, 'Color', colors(policy_index, :));

        % Plot Passenger Utilities
        for i = 1:length(passengers)
          passenger = passengers{i};
          utilities_passenger = hp(passenger.label);
          figure(f_passengers(i));
          plot(tspan, cumsum(utilities_passenger), 'LineWidth', 2, 'Color', colors(policy_index, :));
        end
      end

      % --- Styling and Saving ---
      figHandles = [f_social, f_taxi, f_passengers];
      
      % Get Scale Range
      ymax = -inf;
      ymin = inf;
      for i = 1:length(figHandles)
        figure(figHandles(i));
        ax = gca;
        lines = findall(ax, 'Type', 'line');
        for j = 1:length(lines)
            ydata = get(lines(j), 'YData');
            ymax = max([ymax, max(ydata)]);
            ymin = min([ymin, min(ydata)]);
        end
      end

      % Apply Styles and Save
      if ~exist('simulation_result', 'dir')
        mkdir('simulation_result');
      end

      for i = 1:length(figHandles)
        fig = figHandles(i);
        figure(fig);
        
        % Normalize Y-axis
        ylim([ymin, ymax]);
        
        % Legend
        legend(legend_labels, 'Location', 'northwest', 'Interpreter', 'latex', 'FontSize', font_size_legend);

        % Apply Styles
        set(gca, 'FontName', font_name, 'FontSize', font_size_xaxis, ...
            'LineWidth', 1.5, 'Box', 'off');
        
        xaxisproperties = get(gca, 'XAxis');
        yaxisproperties = get(gca, 'YAxis');
        xaxisproperties.TickLabelInterpreter = 'latex';
        xaxisproperties.FontSize = font_size_xaxis;
        yaxisproperties.TickLabelInterpreter = 'latex';
        yaxisproperties.FontSize = font_size_yaxis;

        xlabel('time step', 'Interpreter', 'latex', 'FontName', font_name, 'FontSize', font_size_label);
        ylabel('utility', 'Interpreter', 'latex', 'FontName', font_name, 'FontSize', font_size_label);

        grid on;
        ax = gca;
        ax.GridAlpha = 0.3;

        % Save
        if fig == f_social
          filename_base = 'simulation_result/social_utility_cumulative';
        elseif fig == f_taxi
          filename_base = 'simulation_result/taxi_utility_cumulative';
        else
          % Identify passenger index
          p_idx = find(fig == f_passengers);
          filename_base = sprintf('simulation_result/passenger_%s_utility_cumulative', passengers{p_idx}.label);
        end
        
        exportgraphics(fig, [filename_base '.eps']);
        savefig(fig, [filename_base '.fig']);
      end
    end
  end
end
  