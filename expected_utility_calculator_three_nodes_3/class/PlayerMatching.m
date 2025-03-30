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
               all(arrayfun(@(x, y) eq(x, y), obj.player_pairs, other.player_pairs));
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
      % マッチングを組んだ時の即時効用の合計を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   utility (Utility): マッチングのユーティリティの合計

      utilities = obj.get_utilities();
      utility = sum(utilities);
    end
  end
end