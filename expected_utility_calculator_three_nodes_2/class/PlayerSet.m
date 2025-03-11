classdef PlayerSet
  % Playerクラスで表されるプレイヤの集合を表すクラス。状況を一意に決定する。

  properties
    players % Playerのセル配列
  end

  methods
    function obj = PlayerSet(players)
      obj.players = players;
      obj.validate();
      obj = obj.sort();
    end
  end

  % override
  methods
    function obj = sort(obj)
      obj.players = Player.sort_players(obj.players);
    end

    function result = eq(obj1, obj2)
      result = false;
      if length(obj1.players) ~= length(obj2.players)
        return
      end

      for i = 1:length(obj1.players)
        if ~eq(obj1.players{i}, obj2.players{i})
          return
        end
      end

      result = true;
    end
  end

  % other
  methods
    function id = id(obj)
        ids = Player.ids(obj.players);
        id = char(strjoin(string(ids), ','));
        id = strcat('{', id, '}');
    end

    function index = index(obj)
      all_player_sets = PlayerSet.get_all_player_sets();
      index = -1;
      for i = 1:length(all_player_sets)
        if strcmp(obj.id(), all_player_sets{i}.id())
          index = i;
          break
        end
      end

      if index == -1
        error('PlayerSet is not found in all_player_sets');
      end
    end

    function result = is_present(obj, player)
      result = false;
      for i = 1:length(obj.players)
        if eq(obj.players{i}, player)
          result = true;
          break
        end
      end
    end

    function result = is_all_possible_passenger_present(obj)
      result = true;
      all_possible_passengers = Player.get_all_passengers();
      for i = 1:length(all_possible_passengers)
        if ~obj.is_present(all_possible_passengers{i})
          result = false;
          break;
        end
      end
    end

    function result = is_node_occupied_by_taxi(obj, node)
      result = false;
      for i = 1:length(obj.players)
        player = obj.players{i};
        if player.is_taxi() && player.node == node
          result = true;
          break
        end
      end
    end

    function result = is_node_occupied_by_passenger(obj, node)
      result = false;
      for i = 1:length(obj.players)
        player = obj.players{i};
        if player.is_passenger() && player.node == node
          result = true;
          break
        end
      end
    end

    function result = is_all_node_occupied_by_passenger(obj)
      result = true;
      for node = 1:3
        if ~obj.is_node_occupied_by_passenger(node)
          result = false;
          break
        end
      end
    end

    function obj = add_player(obj, player)
      if obj.is_node_occupied_by_taxi(player.node) && player.is_taxi() || obj.is_node_occupied_by_passenger(player.node) && player.is_passenger()
        return;
      end

      obj.players{end+1, 1} = player;
      obj.validate();
    end

    function obj = combine(obj, other)
      for i = 1:length(other.players)
        obj = obj.add_player(other.players{i});
      end

      obj = obj.sort();
    end

    function obj = one_step_elapsed(obj)
      for i = 1:length(obj.players)
        player = obj.players{i};
        player_one_step_elapsed = player.one_step_elapsed();

        obj.players{i} = player_one_step_elapsed;
      end

      obj = obj.sort();
      obj.validate();
    end

    function objs = get_all_player_sets_after_one_step(obj)
      objs = {};

      obj = obj.one_step_elapsed();
      appeared_passenger_player_sets = PlayerSet.get_all_passenger_sets();
      for i = 1:length(appeared_passenger_player_sets)
        objs{end+1, 1} = obj.combine(appeared_passenger_player_sets{i});
      end
    end

    function taxis = get_taxis(obj)
      taxis = {};
      for i = 1:length(obj.players)
        if obj.players{i}.is_taxi()
          taxis{end+1, 1} = obj.players{i};
        end
      end
    end

    function taxis = get_empty_taxis(obj)
      taxis = {};
      for i = 1:length(obj.players)
        if obj.players{i}.is_empty_taxi()
          taxis{end+1, 1} = obj.players{i};
        end
      end
    end

    function result = is_all_taxis_empty(obj)
      result = true;
      for i = 1:length(obj.players)
        if ~obj.players{i}.is_empty_taxi() && obj.players{i}.is_taxi()
          result = false;
          break
        end
      end
    end

    function result = is_all_taxis_empty_after_just_m_steps(obj, m)
      result = true;
      for i = 1:length(obj.players)
        player = obj.players{i};
        if player.appearance_step ~= m && player.is_taxi()
          result = false;
          break;
        end
      end
    end

    function passengers = get_passengers(obj)
      passengers = {};
      for i = 1:length(obj.players)
        if obj.players{i}.is_passenger()
          passengers{end+1, 1} = obj.players{i};
        end
      end
    end

    % マッチングアルゴリズム。計算量的に色々仮定をつけている
    function all_player_matchings = get_all_player_matchings(obj)
      all_player_matchings = {};
      player_pairs = {};

      taxi_candidates = obj.get_empty_taxis();
      passenger_candidates = obj.get_passengers();

      % 出現確率が0ではないが、乗客が出現していないノードが存在する、もしくは、出現確率が0でない全てのノードに乗客が出現していても、タクシーが満車の状態では、誰もマッチングしないというマッチングも考える
      if ~obj.is_all_possible_passenger_present() || isempty(taxi_candidates)
        for i = 1:length(obj.players)
          player_pairs{end+1, 1} = PlayerPair({obj.players{i}});
        end
        all_player_matchings{end+1, 1} = PlayerMatching(player_pairs);
      end

      if isempty(taxi_candidates) || isempty(passenger_candidates)
        return
      end

      taxi = taxi_candidates{1}; % タクシーの運用台数は1としている
      for i = 1:length(passenger_candidates)
        passenger = passenger_candidates{i};
        player_pairs = {PlayerPair({taxi; passenger})};

        remained_passengers = Utils.obj_setdiff(passenger_candidates, {passenger});
        for j = 1:length(remained_passengers)
          player_pairs{end+1, 1} = PlayerPair({remained_passengers{j}});
        end

        all_player_matchings{end+1, 1} = PlayerMatching(player_pairs);
      end
    end

    function expected_utilities = get_expected_utilities(obj, x)
      all_players = Player.get_all_players();
      expected_utilities = sym(zeros(length(all_players), 1));
  
      for i = 1:length(obj.players)
          player = obj.players{i};
          expected_utilities(player.index()) = ExpectedUtilityHelper.get_expected_utility(player, obj, x);
      end
    end
  end

  methods (Static)

    function all_passenger_sets = get_all_passenger_sets()
      % passenger variation
      % In general case, use this
      % all_passenger_sets = {
      %   PlayerSet({}); % 何も出現しない
      %   PlayerSet({Player('passenger', 1, 2, 0)}); % ps1のみ出現(ps1: 1->2)
      %   PlayerSet({Player('passenger', 1, 3, 0)}); % ps1のみ出現(ps1: 1->3)
      %   PlayerSet({Player('passenger', 2, 1, 0)}); % ps2のみ出現(ps2: 2->1)
      %   PlayerSet({Player('passenger', 2, 3, 0)}); % ps2のみ出現(ps2: 2->3)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 2, 1, 0)}); % ps1とps2が出現(ps1: 1->2, ps2: 2->1)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 2, 1, 0)}); % ps1とps2が出現(ps1: 1->3, ps2: 2->1)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 2, 3, 0)}); % ps1とps2が出現(ps1: 1->2, ps2: 2->3)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 2, 3, 0)}); % ps1とps2が出現(ps1: 1->3, ps2: 2->3)
      %   PlayerSet({Player('passenger', 3, 1, 0)}); % ps3のみ出現(ps3: 3->1)
      %   PlayerSet({Player('passenger', 3, 2, 0)}); % ps3のみ出現(ps3: 3->2)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 3, 1, 0)}); % ps1とps3が出現(ps1: 1->2, ps3: 3->1)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 3, 1, 0)}); % ps1とps3が出現(ps1: 1->3, ps3: 3->1)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 3, 2, 0)}); % ps1とps3が出現(ps1: 1->2, ps3: 3->2)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 3, 2, 0)}); % ps1とps3が出現(ps1: 1->3, ps3: 3->2)
      %   PlayerSet({Player('passenger', 2, 1, 0); Player('passenger', 3, 1, 0)}); % ps2とps3が出現(ps2: 2->1, ps3: 3->1)
      %   PlayerSet({Player('passenger', 2, 3, 0); Player('passenger', 3, 1, 0)}); % ps2とps3が出現(ps2: 2->3, ps3: 3->1)
      %   PlayerSet({Player('passenger', 2, 1, 0); Player('passenger', 3, 2, 0)}); % ps2とps3が出現(ps2: 2->1, ps3: 3->2)
      %   PlayerSet({Player('passenger', 2, 3, 0); Player('passenger', 3, 2, 0)}); % ps2とps3が出現(ps2: 2->3, ps3: 3->2)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 2, 1, 0); Player('passenger', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->1, ps3: 3->1)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 2, 1, 0); Player('passenger', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->1, ps3: 3->1)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 2, 3, 0); Player('passenger', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->3, ps3: 3->1)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 2, 3, 0); Player('passenger', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->3, ps3: 3->1)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 2, 1, 0); Player('passenger', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->1, ps3: 3->2)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 2, 1, 0); Player('passenger', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->1, ps3: 3->2)
      %   PlayerSet({Player('passenger', 1, 2, 0); Player('passenger', 2, 3, 0); Player('passenger', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->3, ps3: 3->2)
      %   PlayerSet({Player('passenger', 1, 3, 0); Player('passenger', 2, 3, 0); Player('passenger', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->3, ps3: 3->2)
      % };

      % If p and p_ are special matrices, hard code
      all_passenger_sets = {
        PlayerSet({}); % 何も出現しない
        PlayerSet({Player('passenger', 2, 1, 0)}); % ps2のみ出現(ps2: 2->1)
        PlayerSet({Player('passenger', 3, 1, 0)}); % ps3のみ出現(ps3: 3->1)
        PlayerSet({Player('passenger', 2, 1, 0); Player('passenger', 3, 1, 0)}); % ps1とps2が出現(ps1: 1->2, ps2: 2->1)
      };
    end

    function all_taxi_sets = get_all_taxi_sets()
      temp_sets = num2cell(Player.get_all_taxis());
      all_taxi_sets = {};
      for i = 1:length(temp_sets)
        all_taxi_sets{end+1, 1} = PlayerSet(temp_sets{i});
      end
    end

    function all_player_sets = get_all_player_sets()
      persistent cached_player_sets; % 静的変数の宣言

      if isempty(cached_player_sets)
        % passenger variation
        passenger_player_sets = PlayerSet.get_all_passenger_sets();

        % taxi variation
        taxi_player_sets = PlayerSet.get_all_taxi_sets();

        % all player sets. passenger_player_setsとtaxi_player_setsの直積を取る
        cached_player_sets = {};
        for i = 1:length(passenger_player_sets)
          for j = 1:length(taxi_player_sets)
            player_set = passenger_player_sets{i}.combine(taxi_player_sets{j});
            cached_player_sets{end+1, 1} = player_set;
          end
        end
      end

      all_player_sets = cached_player_sets;
    end
  end  

  %validation
  methods
    function validate(obj)
      skip_validation = Utils.is_allowed_skip_validation();
      % Check that players is a cell array
      if ~iscell(obj.players)
        error('players must be a cell array');
      end

      % Check obj.players is not empty
      if isempty(obj.players) && ~skip_validation
        error('players cell array must not be empty');
      end

      % Check that the size of columns is 1
      if size(obj.players, 2) ~= 1 && ~skip_validation
        error('players cell array must have only one column');
      end

      % Check that the players cell array contains only Player instances
      taxi_count = 0;
      for i = 1:length(obj.players)
        if ~isa(obj.players{i}, 'Player')
          error('players cell array must contain only Player instances');
        end

        if strcmp(obj.players{i}.type, 'taxi')
          taxi_count = taxi_count + 1;
        end
      end

      % Check that just two taxi players are included
      if taxi_count ~= 1 && ~skip_validation
        error('players cell array must contain exactly one taxi player. The actual number of taxi players: %d', taxi_count);
      end
    end
  end
end