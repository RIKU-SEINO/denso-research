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
  end

  % other
  methods
    function id = id(obj)
        ids = Player.ids(obj.players);
        id = char(strjoin(string(ids), ','));
        id = strcat('{', id, '}');
    end
  end

  %validation
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
      for i = 1:length(obj.players)
        if ~isa(obj.players{i}, 'Player')
          error('players cell array must contain only Player instances');
        end

        if strcmp(obj.players{i}.type, 'taxi')
          taxi_count = taxi_count + 1;
        end
      end

      % Check that just two taxi players are included
      if taxi_count ~= 2
        error('players cell array must contain exactly two taxi players');
      end
    end
  end
end