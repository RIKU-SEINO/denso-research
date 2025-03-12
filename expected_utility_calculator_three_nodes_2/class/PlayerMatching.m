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

    % マッチングによって"置き換わる前"と"置き換わった後"のプレイヤを返す。あくまで置き換わったプレイヤであり、削除されたプレイヤは含まれない。もちろん、置き換わっていないプレイヤも含まれる
    function [players_before_replaced, players_after_replaced] = get_players_before_and_after_replaced(obj)
      players_before_replaced = {};
      players_after_replaced = {};
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        if player_pair.is_matched() % matchしている場合は、taxiが置き換わる
          for j = 1:length(player_pair.players)
            player = player_pair.players{j};
            if player.is_taxi()
              players_before_replaced{end+1, 1} = player;
              break;
            end
          end
          remained_player = player_pair.get_remained_player_after_matching_of_pair();
          players_after_replaced{end+1, 1} = remained_player;
        else % matchしていない場合は、taxi, passengerに関わらず、beforeとafterが同じ
          remained_player = player_pair.get_remained_player_after_matching_of_pair();
          players_before_replaced{end+1, 1} = remained_player;
          players_after_replaced{end+1, 1} = remained_player;
        end
      end
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
      all_players = Player.get_all_players();
      values = sym(zeros(length(all_players), 1));
      % 1. マッチングで組まれたプレイヤの効用
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        values = values + player_pair.get_utilities();
      end
      % 2. マッチングが組まれた後のプレイヤ集合における期待効用
      values_after_matched_player_set = player_set_after_matching.get_expected_utilities(x);
      % [players_before_replaced, players_after_replaced] = obj.get_players_before_and_after_replaced();
      % for i = 1:length(players_before_replaced)
      %   player_before_replaced = players_before_replaced{i};
      %   player_after_replaced = players_after_replaced{i};
      %   idx = player_before_replaced.index();
      %   values(idx) = values(idx) + values_after_matched_player_set(player_after_replaced.index());
      % end
      values = values + values_after_matched_player_set;
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