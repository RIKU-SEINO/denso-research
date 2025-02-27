classdef Player
  % v_i(n)やps_jのようなプレイヤを表すクラス

  properties
    type % "taxi" or "passenger"
    node_number % 1, 2 or 3
    appearance_step % 0 or more (max 0 or 3 or 4)
  end

  % constructor
  methods
    function obj = Player(type, node_number, appearance_step)
        obj.type = type;
        obj.node_number = node_number;
        obj.appearance_step = appearance_step;

        obj.validate();
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

      id = strcat(type_alias, num2str(obj.node_number));

      if obj.type == "taxi"
        id = strcat(id, '(', num2str(obj.appearance_step), ')');
      end
    end
  end

  % Static methods
  methods (Static)
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

        if obj.node_number ~= 1 && obj.node_number ~= 2 && obj.node_number ~= 3
            error("node_number must be 1, 2 or 3");
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

        if obj.type == "taxi" && obj.node_number ~= 2 && obj.appearance_step > 4
            error("appearance_step must be 0, 1, 2, 3 or 4 when type is taxi and node_number is 1 or 3");
        end

        if obj.type == "taxi" && obj.node_number == 2 && obj.appearance_step > 3
            error("appearance_step must be 0, 1, 2 or 3 when type is taxi and node_number is 2");
        end
    end
  end
end