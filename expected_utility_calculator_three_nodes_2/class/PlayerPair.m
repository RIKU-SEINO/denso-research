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