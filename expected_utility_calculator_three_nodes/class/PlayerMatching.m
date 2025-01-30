classdef PlayerMatching
  properties
    playerPairArray; % Array<PlayerPair>: プレイヤのペアの配列
  end

  methods
    function obj = PlayerMatching(playerPairArray)
      obj.playerPairArray = playerPairArray;
    end
  end

  % 各Playerの期待効用を計算し、そのmatchingにおける期待効用和を返す
  methods
    function expectedUtility = calculateExpectedUtility(obj, u, r)
      expectedUtility = 0;
      for i = 1:length(obj.playerPairArray)
        playerPair = obj.playerPairArray(i);
        taxi = playerPair.taxi;
        passenger = playerPair.passenger;

        % プレイヤ1の期待効用を計算
        if ~isempty(passenger)
          expectedUtility = expectedUtility + u(taxi.getNodeNum(), passenger.getNodeNum(), passenger.getNodeNum());
        else
          expectedUtility = expectedUtility + r(taxi.getNodeNum(), taxi.getNodeNum());
        end

        % プレイヤ2の期待効用を計算
        if ~isempty(passenger)
          expectedUtility = expectedUtility + u(passenger.getNodeNum(), taxi.getNodeNum(), taxi.getNodeNum());
        else
          expectedUtility = expectedUtility + r(taxi.getNodeNum(), taxi.getNodeNum());
        end
      end
    end
  end
end