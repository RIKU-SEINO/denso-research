classdef PlayerPair
  % マッチングを決めた時に、組となったプレイヤのペアを表すクラス。

  properties
    players % Playerのセル配列
  end

  % constructor
  methods
    function obj = PlayerPair(players)
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
  end

  % other
  methods
    function id = id(obj)
        ids = Player.ids(obj.players);
        id = char(strjoin(string(ids), '-'));
        id = strcat('{', id, '}');
    end

    function result = is_included_taxi(obj)
      result = false;
      for i = 1:length(obj.players)
        if obj.players{i}.is_taxi()
          result = true;
          break
        end
      end
    end

    function player = get_taxi(obj)
      player = [];
      for i = 1:length(obj.players)
        if obj.players{i}.is_taxi()
          player = obj.players{i};
          break
        end
      end
    end

    function result = is_included_passenger(obj)
      result = false;
      for i = 1:length(obj.players)
        if obj.players{i}.is_passenger()
          result = true;
          break
        end
      end
    end

    function player = get_passenger(obj)
      player = [];
      for i = 1:length(obj.players)
        if obj.players{i}.is_passenger()
          player = obj.players{i};
          break
        end
      end
    end

    function result = is_matched(obj)
      result = obj.is_included_taxi() && obj.is_included_passenger();
    end

    % return player after executing matching of obj (PlayerPair)
    % remained player is just one player
    function player = get_remained_player_after_matching_of_pair(obj)
      if obj.is_matched() % taxi and passenger are matched
        taxi = obj.get_taxi();
        passenger = obj.get_passenger();
        
        i = taxi.node;
        j = passenger.node;
        k = passenger.destination_node;

        if taxi.appearance_step ~= 0
          disp('warning: appearance_step is not 0, which contradicts the assumption');
        end
        taxi.node = k; % taxi moves to the destination node of passenger
        taxi.appearance_step = taxi.appearance_step + abs(i - j) + abs(j - k); % taxi moves to the destination node of passenger through the node of passenger
        taxi.validate();

        player = taxi;
      elseif obj.is_included_taxi() % taxi are remained
        player = obj.get_taxi();
      elseif obj.is_included_passenger() % passenger are remained
        player = obj.get_passenger();
      end
    end

    function utilities = get_utilities(obj)
      [~, ~, ~, ~, ~, ~, ~, u, r, ~, ~] = ParamsHelper.getSymbolicParams();

      all_players = Player.get_all_players();
      utilities = sym(zeros(length(all_players), 1));

      if ~obj.is_matched()
        return
      end

      taxi = obj.get_taxi();
      passenger = obj.get_passenger();

      i = taxi.node;
      j = passenger.node;
      k = passenger.destination_node;

      utilities(taxi.index()) = u(i, j, k);
      utilities(passenger.index()) = r(i, j);
    end
  end

  methods (Static)
    function ids = ids(player_pairs)
      ids = cell(length(player_pairs), 1);
      for i = 1:length(player_pairs)
        ids{i} = player_pairs{i}.id();
      end
    end

    function player_pairs = sort_player_pairs(player_pairs)
      ids = PlayerPair.ids(player_pairs);
      [~, idx] = sort(ids);
      player_pairs = player_pairs(idx);
    end
  end

  % validation
  methods
    function validate(obj)
      % Check that players is a cell array
      if ~iscell(obj.players)
        error('players must be a cell array');
      end

      % Check obj.players is not empty
      if isempty(obj.players)
        error('players cell array must not be empty');
      end

      % Check that the players cell array contains only Player instances
      taxi_count = 0;
      passenger_count = 0;
      for i = 1:length(obj.players)
        if ~isa(obj.players{i}, 'Player')
          error('players cell array must contain only Player instances');
        end

        if strcmp(obj.players{i}.type, 'taxi')
          taxi_count = taxi_count + 1;
        else
          passenger_count = passenger_count + 1;
        end
      end

      if taxi_count > 1
        error('The number of taxi players must be 0 or 1');
      end

      if passenger_count > 1
        error('The number of passenger players must be 0 or 1');
      end

      % Check that the number of players is correct
      if taxi_count == 0 && passenger_count ~= 1
        error('if 0 taxi players, the number of passenger players must be 1');
      end
    end
  end
end