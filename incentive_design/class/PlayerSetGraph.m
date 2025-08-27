classdef PlayerSetGraph
  % PayerSetGraph クラス
  %
  % 期待効用の計算結果に基づき、プレイヤ集合の遷移とマッチングを表すグラフを生成するクラス。
  % 
  properties
    solution % 数値解
    policy % Policyクラスのインスタンス
    player_set_labels_origin % 遷移前のプレイヤーセットラベル
    player_set_labels_after_transition % 遷移後のプレイヤーセットラベル
    player_set_labels_before_matching % マッチング前のプレイヤーセットラベル
    player_set_labels_after_matching % マッチング後のプレイヤーセットラベル
    player_set_labels_before_adopted_matching % obj.policyで採用されたマッチング前のプレイヤーセットラベル
    player_set_labels_after_adopted_matching % obj.policyで採用されたマッチング後のプレイヤーセットラベル
    graph % 作成されたグラフオブジェクト
  end
  
  % constructor
  methods
    function obj = PlayerSetGraph(solution, policy)
      obj.solution = solution;
      obj.policy = policy;
      obj = obj.generate_labels_and_graph();
    end
  end

  % other
  methods  
    function obj = generate_labels_and_graph(obj)
      % プレイヤーセットのラベルを生成し、グラフを作成する
      % 
      % Returns:
      %   obj (PlayerSetGraph): グラフが生成されたPlayerSetGraphオブジェクト
      
      % ラベルの生成
      obj.player_set_labels_origin = {};
      obj.player_set_labels_after_transition = {};
      obj.player_set_labels_before_matching = {};
      obj.player_set_labels_after_matching = {};
      obj.player_set_labels_before_adopted_matching = {};
      obj.player_set_labels_after_adopted_matching = {};

      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      
      for i = 1:length(all_possible_player_sets)
        % 最初の状態から、1ステップ経過+乗客の出現
        player_set = all_possible_player_sets{i};
        all_possible_player_sets_after_transition = player_set.get_all_possible_player_sets_after_transition();
        for j = 1:length(all_possible_player_sets_after_transition)
          player_set_after_transition = all_possible_player_sets_after_transition{j};

          label_origin = sprintf('%s: %.2f', player_set.label, player_set.get_state_value_from_solution(obj.solution));
          label_after_transition = sprintf('%s: %.2f', player_set_after_transition.label, player_set_after_transition.get_state_value_from_solution(obj.solution));

          obj.player_set_labels_origin{end+1} = label_origin;
          obj.player_set_labels_after_transition{end+1} = label_after_transition;
        end
        
        % 遷移後のプレイヤ集合に対して、マッチングを決定し、プレイヤ集合が変化
        all_possible_player_matchings = player_set.get_all_possible_player_matchings();
        for j = 1:length(all_possible_player_matchings)
          player_matching = all_possible_player_matchings{j};
          player_set_after_matching = player_matching.get_player_set_after_matching();

          label_before_matching = sprintf('%s: %.2f', player_set.label, player_set.get_state_value_from_solution(obj.solution));
          label_after_matching = sprintf('%s: %.2f', player_set_after_matching.label, player_set_after_matching.get_state_value_from_solution(obj.solution));

          obj.player_set_labels_before_matching{end+1} = label_before_matching;
          obj.player_set_labels_after_matching{end+1} = label_after_matching;

          if isequal(player_matching, obj.policy.get_player_matching_by_player_set(player_set))
            obj.player_set_labels_before_adopted_matching{end+1} = label_before_matching;
            obj.player_set_labels_after_adopted_matching{end+1} = label_after_matching;
          end
        end
      end
      
      % ノード（ラベル）の一覧を作成
      all_labels = unique(obj.player_set_labels_origin);
      
      % 空の有向グラフを作成してノードを追加
      obj.graph = digraph();
      obj.graph = addnode(obj.graph, all_labels);
      
      % 遷移エッジの追加（青色）
      num_edges_transition = length(obj.player_set_labels_origin);
      for k = 1:num_edges_transition
        idx_origin = find(strcmp(all_labels, obj.player_set_labels_origin{k}));
        idx_after  = find(strcmp(all_labels, obj.player_set_labels_after_transition{k}));
        obj.graph = addedge(obj.graph, idx_origin, idx_after);
      end
    end
    
    function fig = plot_graph(obj)
      % グラフをlayeredレイアウトで描画する
      % 
      % Returns:
      %   h (handle): グラフの描画ハンドル
      
      fig = figure('Units', 'pixels', 'Position', [0, 0, 3000, 2000]);
      h = plot(obj.graph, 'EdgeColor', 'b', 'LineWidth', 0.5);
      layout(h, 'layered');
      hold on;
      
      % マッチングエッジ（赤破線）の追加
      obj.add_matching_edges(h, ...
        obj.player_set_labels_before_matching, ...
        obj.player_set_labels_after_matching, 'normal');
      hold on;

      obj.add_matching_edges(h, ...
        obj.player_set_labels_before_adopted_matching, ...
        obj.player_set_labels_after_adopted_matching, 'bold');
      hold off;
    end
    
    function add_matching_edges(obj, h, labels_before_matching, labels_after_matching, style)
      % マッチングエッジ（赤破線）を追加する
      % 
      % Parameters:
      %   h (handle): グラフの描画ハンドル
      
      ax = gca;
      num_edges_matching = length(labels_before_matching);
      for k = 1:num_edges_matching
        idx_before = find(strcmp(obj.graph.Nodes.Name, labels_before_matching{k}));
        idx_after  = find(strcmp(obj.graph.Nodes.Name, labels_after_matching{k}));
        pos_before = [h.XData(idx_before), h.YData(idx_before)];
        pos_after  = [h.XData(idx_after), h.YData(idx_after)];
        
        if norm(pos_before - pos_after) == 0
          % セルフループの場合
          obj.draw_self_loop(ax, pos_before, style);
        else
          % 通常のエッジの場合
          obj.draw_normal_edge(ax, pos_before, pos_after, style);
        end
      end
    end
    
    function draw_self_loop(~, ax, pos_before, style)
      % セルフループのエッジを描画する
      % 
      % Parameters:
      %   ax (axes): 軸オブジェクト
      %   pos_before (2D vector): セルフループの始点
      %   pos_after (2D vector): セルフループの終点
      
      r = 0.1;    % セルフループの半径（調整可能）
      delta = 0.2; % ギャップ角（ラジアン）
      x = pos_before(1);
      y = pos_before(2);
      center = [x, y + r];
      theta_node = -pi/2;
      theta_start = theta_node + delta;
      theta_end   = theta_node - delta + 2*pi;
      theta = linspace(theta_start, theta_end, 100);
      arc_x = center(1) + r * cos(theta);
      arc_y = center(2) + r * sin(theta);
      if strcmp(style, 'bold')
        plot(arc_x, arc_y, 'r', 'LineWidth', 2);
      elseif strcmp(style, 'normal')
        plot(arc_x, arc_y, 'r', 'LineWidth', 0.5);
      end
      mid_idx = round(length(theta)/2);
      arrow_start_point = [arc_x(mid_idx-1), arc_y(mid_idx-1)];
      arrow_end_point   = [arc_x(mid_idx), arc_y(mid_idx)];
      [xs, ys] = PlayerSetGraph.ax2fig(ax, arrow_start_point(1), arrow_start_point(2));
      [xe, ye] = PlayerSetGraph.ax2fig(ax, arrow_end_point(1), arrow_end_point(2));
      annotation('arrow', [xs, xe], [ys, ye], 'Color','r','LineStyle','--','LineWidth',1.5);
    end
    
    function draw_normal_edge(~, ax, pos_before, pos_after, style)
      % 通常のエッジを描画する
      % 
      % Parameters:
      %   ax (axes): 軸オブジェクト
      %   pos_before (2D vector): 始点
      %   pos_after (2D vector): 終点
      
      [xs, ys] = PlayerSetGraph.ax2fig(ax, pos_before(1), pos_before(2));
      [xe, ye] = PlayerSetGraph.ax2fig(ax, pos_after(1), pos_after(2));
      
      if strcmp(style, 'bold')
        annotation('arrow', [xs, xe], [ys, ye], 'Color','r','LineWidth',2);
      elseif strcmp(style, 'normal')
        annotation('arrow', [xs, xe], [ys, ye], 'Color','r','LineWidth',0.5);
      end
    end
  end

  methods (Static)
    function [nx, ny] = ax2fig(ax, x, y)
      % 軸座標をフィギュア座標に変換する
      % 
      % Parameters:
      %   ax (axes): 軸オブジェクト
      %   x (double): 軸座標のx成分
      %   y (double): 軸座標のy成分
      % 
      % Returns:
      %   nx (double): フィギュア座標のx成分
      %   ny (double): フィギュア座標のy成分
      
      ax_units = ax.Units;
      ax.Units = 'normalized';
      axpos = ax.Position;
      ax.Units = ax_units;  % 元に戻す
      % 軸の範囲を取得
      xl = ax.XLim;
      yl = ax.YLim;
      nx = axpos(1) + (x - xl(1))/(xl(2)-xl(1)) * axpos(3);
      ny = axpos(2) + (y - yl(1))/(yl(2)-yl(1)) * axpos(4);
    end
  end
end
