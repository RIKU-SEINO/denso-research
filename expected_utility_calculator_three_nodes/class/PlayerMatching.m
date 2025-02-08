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

        if ~isempty(taxi) && isempty(passenger) && taxi.appearanceStepCount == 0 % playerPairにおけるtaxiとpassengerの組み合わせとして想定されるのが、taxiとpassengerの両方が存在するペアとtaxiだけが存在するペアの2通りである。乗客は取り残されることはないからである。ここで、マッチングが組まれた後において、プレイヤが残るケースは、後者のtaxiだけが存在するペアのみである。（taxiとpassengerがplayerpairの場合、それらは消失するので、situationNumerに+=1しなくて良い。）
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

      [~, ~, ~, a, ~, ~, p_, u, r, ~, ~] = ParamsHelper.getSymbolicParams();

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
            expectedUtilities(playerIndexTaxi) = p_(passengerNode, destinationNodeLeft) * u(taxiNode, passengerNode, destinationNodeLeft) + p_(passengerNode, destinationNodeRight) * u(taxiNode, passengerNode, destinationNodeRight);

          elseif isempty(passenger) && taxi.appearanceStepCount == 0

            situation = obj.getSituationAfterMatching();
            expectedUtilities(playerIndexTaxi) = x(situation.situationNumber+1, playerIndexTaxi);

          end
        end

        % 乗客の期待効用 乗客は取り残されることはない
        if ~isempty(taxi) && ~isempty(passenger)
          taxiNode = taxi.getNodeNum();
          waitStepCount = taxi.appearanceStepCount;
          passengerNode = passenger.getNodeNum();
          playerIndexPassenger = passenger.playerIndex;
          expectedUtilities(playerIndexPassenger) = r(taxiNode, passengerNode) - waitStepCount * a(passengerNode);
        end
      end
    end

    % PlayerMatchingにおける社会全体の期待効用を計算する
    function expectedUtility = calculateTotalExpectedUtility(obj, x)
      expectedUtilities = obj.calculateExpectedUtilities(x);
      expectedUtility = sum(expectedUtilities);
    end
  end

  methods
    % 現在のplayerMatchingにおけるペアを文字列として返す
    function str = toString(obj)
      str = '';
      for i = 1:length(obj.playerPairArray)
        str_tmp = '';
        playerPair = obj.playerPairArray(i);
        taxi = playerPair.taxi;
        passenger = playerPair.passenger;

        if ~isempty(taxi)
          str_tmp = strcat(str_tmp, taxi.getName());
          if ~isempty(passenger)
            str_tmp = strcat(str_tmp, '-', passenger.getName());
          end
        end

        str = strcat(str, '{', str_tmp, '},');
      end
    end
  end
end