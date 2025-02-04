classdef Equation
  properties
    playerIndex; % int: プレイヤーのインデックス
    situationNumber; % int: 状況の番号
    condition; % Condition: 条件
  end

  methods
    function obj = Equation(playerIndex, situationNumber, condition)
      obj.playerIndex = playerIndex;
      obj.situationNumber = situationNumber;
      obj.condition = condition;
    end

    function playerIndex = getPlayerIndex(obj)
      playerIndex = obj.playerIndex;
    end

    function situationNumber = getSituationNumber(obj)
      situationNumber = obj.situationNumber;
    end

    function condition = getCondition(obj)
      condition = obj.condition;
    end
  end
end