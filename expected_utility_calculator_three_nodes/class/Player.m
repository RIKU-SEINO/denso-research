classdef Player
  properties
    playerIndex; % int: プレイヤーインデックス。1~6
    appearanceStepCount; % int: 出現するまでにかかるステップ数。0であればすでに出現している
    destinationNode; % int: 目的地ノード番号。タクシーの場合は0, 乗客の場合は0ならば未定, 1~3ならばそれが目的地
  end

  methods
    function obj = Player(playerIndex, appearanceStepCount, destinationNode)
      obj.playerIndex = playerIndex;
      obj.appearanceStepCount = appearanceStepCount;

      if nargin > 2
        obj.destinationNode = destinationNode;
      else
        obj.destinationNode = 0;
      end

      if (playerIndex ~= 1) && (playerIndex ~= 2) && (playerIndex ~= 3) && (playerIndex ~= 4) && (playerIndex ~= 5) && (playerIndex ~= 6)
        error('playerIndex must be in 1, 2, 3, 4, 5, or 6');
      end

      if appearanceStepCount < 0
        error('appearanceStepCount must be greater than or equal to 0');
      end

      % 出現するプレイヤが乗客の場合は、0より大きいappearanceStepCountは許可しない
      if ~(playerIndex == 1) && ~(playerIndex == 3) && ~(playerIndex == 5)
        if appearanceStepCount > 0
          error('appearanceStepCount must be 0 if the player is a passenger');
        end
      end

      if (destinationNode ~= 0) && (destinationNode ~= 1) && (destinationNode ~= 2) && (destinationNode ~= 3)
        error('destinationNode must be in 0, 1, 2, or 3');
      end
    end
  end

  methods
    function isequal = eq(obj1, obj2)
      isequal = (obj1.playerIndex == obj2.playerIndex) && (obj1.appearanceStepCount == obj2.appearanceStepCount);
    end
  end

  % playerが出現するノード番号を返す
  methods
    function result = getNodeNum(obj)
      if (obj.playerIndex == 1) || (obj.playerIndex == 2)
        result = 1;
      elseif (obj.playerIndex == 3) || (obj.playerIndex == 4)
        result = 2;
      elseif (obj.playerIndex == 5) || (obj.playerIndex == 6)
        result = 3;
      end
    end
  end
end