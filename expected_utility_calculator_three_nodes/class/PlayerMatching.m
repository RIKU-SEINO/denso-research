classdef PlayerMatching
  properties
    playerPairArray; % Array<PlayerPair>: プレイヤのペアの配列
  end

  methods
    function obj = PlayerMatching(playerPairArray)
      obj.playerPairArray = playerPairArray;
    end
  end

  % 今現在のマッチングが組まれた後におけるsituationを返す
  methods
    function situation = getSituationAfterMatching(obj)
      situationNumber = 0;
      for i = 1:length(obj.playerPairArray)
        playerPair = obj.playerPairArray(i);
        taxi = playerPair.taxi;
        passenger = playerPair.passenger;

        if ~isempty(taxi) && isempty(passenger) && taxi.appearanceStepCount == 0
          playerIndexTaxi = taxi.playerIndex;
          situationNumber = situationNumber + 2^(playerIndexTaxi - 1);
        end
      end

      situation = Situation(situationNumber);
    end
  end

  % 各Playerの期待効用を計算する。出現していないプレイヤの期待効用は0とする。
  methods
    function expectedUtilities = calculateExpectedUtilities(obj, x)

      % タクシーが乗客を1ノード先に運ぶ際に得る利益
      u = ParamsHelper.u;
      % 乗客がマッチした時に得る効用
      r = ParamsHelper.r;
      % 乗客が単位時間あたりに低下する効用
      alpha = ParamsHelper.alpha;
      % 出現した乗客がどのノードを目的地とするかの確率
      p_jk = ParamsHelper.p_jk;

      expectedUtilities = sym(zeros(6, 1));
      for i = 1:length(obj.playerPairArray)
        playerPair = obj.playerPairArray(i);
        taxi = playerPair.taxi;
        passenger = playerPair.passenger;

        % タクシーの期待効用
        if ~isempty(taxi)
          playerIndexTaxi = taxi.playerIndex;
          taxiNode = taxi.getNodeNum();
          if ~isempty(passenger) && passenger.destinationNode ~= 0
            passengerNode = passenger.getNodeNum();
            destinationNode = passenger.destinationNode;
            expectedUtilities(playerIndexTaxi) = u(taxiNode, passengerNode, destinationNode);
          elseif ~isempty(passenger) && passenger.destinationNode == 0
            passengerNode = passenger.getNodeNum();
            destinationNodeCandidates = setdiff(1:3, passenger.getNodeNum());
            destinationNodeLeft = destinationNodeCandidates(1);
            destinationNodeRight = destinationNodeCandidates(2);
            expectedUtilities(playerIndexTaxi) = p_jk(passengerNode, destinationNodeLeft) * u(taxiNode, passengerNode, destinationNodeLeft) + p_jk(passengerNode, destinationNodeRight) * u(taxiNode, passengerNode, destinationNodeRight);
          elseif isempty(passenger) && taxi.appearanceStepCount == 0
            situation = obj.getSituationAfterMatching();
            expectedUtilities(playerIndexTaxi) = x(situation.situationNumber+1, playerIndexTaxi);
          end
        end

        % 乗客の期待効用 乗客は取り残されることはない
        if ~isempty(taxi) && ~isempty(passenger)
          taxiNode = taxi.getNodeNum();
          waitStepCount = passenger.appearanceStepCount;
          passengerNode = passenger.getNodeNum();
          playerIndexPassenger = passenger.playerIndex;
          expectedUtilities(playerIndexPassenger) = r(taxiNode, passengerNode) - waitStepCount * alpha(passengerNode);
        end
      end
    end
  end
end