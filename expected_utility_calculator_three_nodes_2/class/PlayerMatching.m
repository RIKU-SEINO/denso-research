classdef PlayerMatching
  % プレイヤ集合において組まれたマッチングを返す

  properties
    player_pairs % PlayerPairのセル配列
  end

  % constructor
  methods
    function obj = PlayerMatching(player_pairs)
      obj.player_pairs = player_pairs;
      obj = obj.sort();
    end
  end

  % override
  methods
    function obj = sort(obj)
      obj.player_pairs = PlayerPair.sort_player_pairs(obj.player_pairs);
    end
  end

  % other methods
  methods
    function id = id(obj)
      ids = PlayerPair.ids(obj.player_pairs);
      id = char(strjoin(string(ids), ','));
      id = strcat('{', id, '}');
    end

    % return player set after matching
    function player_set = get_player_set_after_matching(obj)
      player_set = {};
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        remained_player = player_pair.get_remained_player_after_matching_of_pair();
        player_set{end+1, 1} = remained_player;
      end

      player_set = PlayerSet(player_set);
    end

    % calculate expected utility for each player after matching
    function expected_utilities = calculate_expected_utilities(obj)
      player_set_after_matching = obj.get_player_set_after_matching();
      
      % 2つに分けて計算をする
      % 1. マッチング後残ったプレイヤの期待効用
      expected_utilities = player_set_after_matching.get_expected_utilities();
      % 2. マッチングで組まれたプレイヤの効用
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        expected_utilities = expected_utilities + player_pair.get_utilities();
      end
      % 補足: 1.と2.の両方に該当するプレイヤもいる。例えば、タクシーは乗客と組まれた2.に該当するが、その後目的地までの移動後を考えて、1.にも該当する。
    end
  end
end