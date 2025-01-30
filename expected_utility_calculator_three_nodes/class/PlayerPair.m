classdef PlayerPair
  properties
    taxi; % Player: タクシー。タクシーは取り残されることができるので、PlayerPairに必ず存在するため、必須
    passenger; % Player: 乗客。乗客がいない場合は空にする
  end

  methods
    function obj = PlayerPair(taxi, passenger)
        if ~isa(taxi, 'Player')
            error('taxi must be an instance of the Player class.');
        end
        obj.taxi = taxi;
        
        if nargin > 1 && isa(passenger, 'Player')
            obj.passenger = passenger;
        else
            obj.passenger = [];  % passengerがいない場合は空にする
        end
    end
  end

  % 指定したプレイヤの相手のプレイヤを返す
  methods
    function player = getOpponent(obj, player)
      if obj.taxi == player
        player = obj.passenger;
      elseif obj.passenger == player
        player = obj.taxi;
      else
        error('The specified player is not included in this pair.');
      end
    end
  end

  % プレイヤペアに属する全てのプレイヤを返す
  methods
    function players = getPlayers(obj)
      if isempty(obj.passenger)
        players = [obj.taxi];
      else
        players = [obj.taxi, obj.passenger];
      end
    end
  end
end