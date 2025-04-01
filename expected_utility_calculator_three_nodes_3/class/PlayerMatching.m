classdef PlayerMatching
  % PlayerMatching クラス
  %
  % プレイヤ集合において組まれたマッチングを表すクラス。
  %

  % properties
  properties
    % プレイヤのペア
    % cell<PlayerPair>: プレイヤのペアを格納するセル配列
    player_pairs
  end

  % constructor
  methods
    function obj = PlayerMatching(player_pairs)
      % PlayerMatching クラスのコンストラクタ
      %
      % Parameters:
      %   player_pairs (cell<PlayerPair>): プレイヤのペアを格納するセル配列
      %
      % Returns:
      %   obj (PlayerMatching): 生成された PlayerMatching インスタンス

      obj.player_pairs = player_pairs;

      obj = obj.sort();
    end
  end

  % override
  methods
    function result = eq(obj, other)
      % 2つの PlayerMatching オブジェクトが等しいか判定する
      %
      % Parameters:
      %   obj (PlayerMatching): 1つ目の PlayerMatching オブジェクト
      %   other (PlayerMatching): 2つ目の PlayerMatching オブジェクト
      %
      % Returns:
      %   result (logical): 等しい場合は true, そうでない場合は false

      result = length(obj.player_pairs) == length(other.player_pairs) && ...
               all(arrayfun(@(x, y) isequal(x, y), obj.player_pairs, other.player_pairs));
    end

    function obj = sort(obj)
      % プレイヤのペアをソートする
      % 
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   obj (PlayerMatching): ソートされた PlayerMatching インスタンス

      obj.player_pairs = PlayerPair.sort_player_pairs(obj.player_pairs);
    end
  end

  % other methods
  methods
    function id = id(obj)
      % マッチングのIDを取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   id (char): マッチングのIDを表す文字列
      ids = PlayerPair.ids(obj.player_pairs);
      id = char(strjoin(string(ids), '_'));
    end

    function label = label(obj)
      % マッチングのラベルを取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   label (char): マッチングのラベルを表す文字列
      labels = PlayerPair.labels(obj.player_pairs);
      label = char(strjoin(string(labels), ','));
      label = strcat('{', label, '}');
    end

    function player_set = get_player_set_before_matching(obj)
      % マッチング前のプレイヤ集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_set (PlayerSet): マッチング前のプレイヤ集合

      player_set = PlayerSet({});
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        player_set = player_set.add_all(player_pair.players);
      end
    end

    function player_set = get_player_set_after_matching(obj)
      % マッチング後のプレイヤ集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_set (PlayerSet): マッチング後のプレイヤ集合

      player_set = obj.get_player_set_before_matching();
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        
        removed_player = player_pair.get_removed_player_after_matching();
        player_set = player_set.remove(removed_player);

        [replaced_player, replaced_player_new] = player_pair.get_replaced_player_after_matching();

        player_set = player_set.replace(replaced_player, replaced_player_new);
      end
    end

    function utilities = get_utilities(obj)
      % マッチングを組んだ時の即時効用を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   utilities (cell<Utility>): マッチングのユーティリティを格納するセル配列

      all_possible_players = Player.get_all_possible_players();
      utilities = sym(zeros(length(all_possible_players), 1));

      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        utilities = utilities + player_pair.get_utilities();
      end
    end

    function utility = get_utility_sum(obj)
      % マッチングを組んだ時の即時効用の合計を取得する(=R)
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   utility (Utility): マッチングのユーティリティの合計

      utilities = obj.get_utilities();
      utility = sum(utilities);
    end

    function utility = get_expected_utility_sum(obj)
      % マッチングを組んだ時の期待効用の合計を取得する（=R + γ * V）
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   utility (Utility): マッチングの期待効用の合計
      [~, ~, ~, ~, ~, ~, g, ~, ~, ~] = ParamsHelper.get_symbolic_params();


      player_set = obj.get_player_set_after_matching();
      utility = obj.get_utility_sum() + g * VariablesHelper.get_state_value(player_set); % R + γ * V
    end

    function player_matchings = get_all_possible_player_matchings(obj)
      % objで指定したプレイヤマッチングが組まれるようなプレイヤ集合において考えられる全てのプレイヤマッチングの集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列

      player_set = obj.get_player_set_before_matching();
      player_matchings = player_set.get_all_possible_player_matchings();
    end

    function player_matchings = get_not_optimaL_player_matchings(obj)
      % 最適でないプレイヤマッチングの集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): 最適でないプレイヤマッチングの集合を格納するセル配列

      all_possible_player_matchings = obj.get_all_possible_player_matchings();
      player_matchings = Utils.obj_setdiff(all_possible_player_matchings, {obj});
    end

    function expr = optimality_condition(obj)
      % 指定したプレイヤマッチングが最適である場合の条件式を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   expr (sym): プレイヤマッチングのシンボリック条件式

      not_optimal_player_matchings = obj.get_not_optimaL_player_matchings();
      expr = symtrue;
      for i = 1:length(not_optimal_player_matchings)
        not_optimal_expected_utility = not_optimal_player_matchings{i}.get_expected_utility_sum();
        optimal_expected_utility = obj.get_expected_utility_sum();

        expr = expr & (not_optimal_expected_utility <= optimal_expected_utility);
      end
    end
  end

  methods (Static)
    function ids = ids(player_matchings)
      % プレイヤマッチングのIDを取得する
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列
      %
      % Returns:
      %   ids (cell): プレイヤマッチングのIDを格納するセル配列

      ids = cell(length(player_matchings), 1);
      for i = 1:length(player_matchings)
        ids{i} = player_matchings{i}.id();
      end
    end

    function labels = labels(player_matchings)
      % プレイヤマッチングのラベルを取得する
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列
      %
      % Returns:
      %   labels (cell): プレイヤマッチングのラベルを格納するセル配列

      labels = cell(length(player_matchings), 1);
      for i = 1:length(player_matchings)
        labels{i} = player_matchings{i}.label();
      end
    end

    function player_matchings = sort_player_matchings(player_matchings)
      % プレイヤマッチングをソートする。all_player_setsの順番に従ってソートする
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): ソートされたプレイヤマッチングの集合を格納するセル配列

      player_sets = cell(length(player_matchings), 1);
      for i = 1:length(player_matchings)
        player_set = player_matchings{i}.get_player_set_before_matching();
        player_sets{i} = player_set;
      end
      
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      [~, sorted_indices] = sort(cellfun(@(x) find(Utils.ismember(x, all_possible_player_sets)), player_sets));
      player_matchings = player_matchings(sorted_indices);
    end
  end
end