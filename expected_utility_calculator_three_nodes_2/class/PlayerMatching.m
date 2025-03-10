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
    function values = calculate_expected_utilities(obj, x)
      % persistent cached_data; % キャッシュを保持する変数 (persistent)
      % if isempty(cached_data)
      %   cached_data = containers.Map('KeyType', 'char', 'ValueType', 'any');
      % end

      % key = obj.id();
      % if isKey(cached_data, key)
      %   values = cached_data(key);
      %   return
      % end

      player_set_after_matching = obj.get_player_set_after_matching();
      
      % 2つに分けて計算をする
      % 1. マッチング後残ったプレイヤの期待効用
      values = player_set_after_matching.get_expected_utilities(x);
      % 2. マッチングで組まれたプレイヤの効用
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        values = values + player_pair.get_utilities();
      end
      % 補足: 1.と2.の両方に該当するプレイヤもいる。例えば、タクシーは乗客と組まれた2.に該当するが、その後目的地までの移動後を考えて、1.にも該当する。
    end

    function value_sum = calculate_expected_utility_sum(obj, x)
      values = obj.calculate_expected_utilities(x);
      value_sum = sum(values);
    end

    function value = calculate_expected_utility_of_player(obj, player, x)
      values = obj.calculate_expected_utilities(x);
      value = values(player.index());
    end
  end

  methods (Static)
    function ids = ids(player_matchings)
      ids = {};
      for i = 1:length(player_matchings)
        ids{end+1, 1} = player_matchings{i}.id();
      end
    end

    function objs = sort_player_matchings(objs)
      ids = PlayerMatching.ids(objs);
      [~, idx] = sort(ids);
      objs = objs(idx);
    end
  end
end