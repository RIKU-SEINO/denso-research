classdef Player
  % v_i(n)やps_jのようなプレイヤを表すクラス

  properties
    type % "taxi" or "passenger"
    node % 1, 2 or 3
    destination_node % 1, 2 or 3 if passenger, which is different from node. 0 if taxi
    appearance_step % 0 or more (max 0 or 3 or 4)
  end

  % constructor
  methods
    function obj = Player(type, node, destination_node, appearance_step)
        obj.type = type;
        obj.node = node;
        obj.destination_node = destination_node;
        obj.appearance_step = appearance_step;

        obj.validate();
    end
  end

  % override
  methods
    function result = eq(obj, other)
      result = strcmp(obj.type, other.type) && obj.node == other.node && obj.destination_node == other.destination_node && obj.appearance_step == other.appearance_step;
    end
  end

  % other methods
  methods
    function id = id(obj)
      if obj.type == "taxi"
          type_alias = 'v';
      else
          type_alias = 'ps';
      end

      id = strcat(type_alias, num2str(obj.node));

      if obj.type == "taxi"
        id = strcat(id, '(', num2str(obj.appearance_step), ')');
      else
        id = strcat(id, '[', num2str(obj.destination_node), ']');
      end
    end

    function index = index(obj)
      % all_playersの中でのindexを返す
      all_players = Player.get_all_players();
      index = -1;
      for i = 1:length(all_players)
        if eq(obj, all_players{i})
          index = i;
          break
        end
      end

      if index == -1
        error("Player not found in all_players");
      end
    end

    function result = is_taxi(obj)
      result = obj.type == "taxi";
    end

    function result = is_empty_taxi(obj)
      result = obj.type == "taxi" && obj.appearance_step == 0;
    end

    function result = is_passenger(obj)
      result = obj.type == "passenger";
    end

    function obj = one_step_elapsed(obj)
      if obj.is_taxi()
        obj.appearance_step = max([obj.appearance_step - 1, 0]);
      end
    end
  end

  % Static methods
  methods (Static)
    function all_taxis = get_all_taxis()
      all_taxis = {};
      for node = 1:3
        for appearance_step = 0:3
          all_taxis{end+1, 1} = Player('taxi', node, 0, appearance_step);
        end

        if node ~= 2
          all_taxis{end+1, 1} = Player('taxi', node, 0, 4);
        end
      end
    end

    function all_passengers = get_all_passengers()
      all_passengers = {};
      for i = 1:3
        for j = 1:3
          if i == j
            continue
          end

          all_passengers{end+1, 1} = Player('passenger', i, j, 0);
        end
      end
    end

    function all_players = get_all_players()
      persistent cached_players;

      if isempty(cached_players)
        taxis = Player.get_all_taxis();
        passengers = Player.get_all_passengers();
        cached_players = [taxis; passengers];
      end

      all_players = cached_players;
    end

    function ids = ids(players)
      ids = cell(length(players), 1);
      for i = 1:length(players)
        ids{i} = players{i}.id();
      end
    end

    function sorted_players = sort_players(players)
      taxi_players = {};
      passenger_players = {};
      for i = 1:length(players)
        if players{i}.type == "taxi"
          taxi_players{end + 1} = players{i};
          taxi_ids = Player.ids(taxi_players);
          [~, taxi_idx] = sort(taxi_ids);
        else
          passenger_players{end + 1} = players{i};
          passenger_ids = Player.ids(passenger_players);
          [~, passenger_idx] = sort(passenger_ids);
        end
      end

      % taxiとpassengerをそれぞれソート
      sorted_taxi_players = cell(length(taxi_players), 1);
      for i = 1:length(taxi_players)
        sorted_taxi_players{i} = taxi_players{taxi_idx(i)};
      end

      sorted_passenger_players = cell(length(passenger_players), 1);
      for i = 1:length(passenger_players)
        sorted_passenger_players{i} = passenger_players{passenger_idx(i)};
      end

      % taxiとpassengerを結合
      sorted_players = [sorted_taxi_players; sorted_passenger_players];
    end
  end

  % validation
  methods
    function validate(obj)
        if obj.type ~= "taxi" && obj.type ~= "passenger"
            error("type must be taxi or passenger");
        end

        if obj.node ~= 1 && obj.node ~= 2 && obj.node ~= 3
            error("node must be 1, 2 or 3");
        end

        if obj.appearance_step < 0
            error("appearance_step must be 0 or more");
        end

        if obj.appearance_step ~= floor(obj.appearance_step)
            error("appearance_step must be an integer");
        end

        if obj.type == "passenger" && obj.appearance_step ~= 0
            error("appearance_step must be 0 when type is passenger");
        end

        if obj.type == "taxi" && obj.node ~= 2 && obj.appearance_step > 4
            error("appearance_step must be 0, 1, 2, 3 or 4 when type is taxi and node is 1 or 3");
        end

        if obj.type == "taxi" && obj.node == 2 && obj.appearance_step > 3
            error("appearance_step must be 0, 1, 2 or 3 when type is taxi and node is 2");
        end

        if obj.node == obj.destination_node
            error("node and destination_node must be different");
        end

        if obj.type == "taxi" && obj.destination_node ~= 0
            error("destination_node must be 0 when type is taxi");
        end
    end
  end
end