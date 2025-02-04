classdef Situation
  properties
    situationNumber; % int: 状況番号
    destinationNodes = zeros(6, 1); % array<int>: 目的地ノード番号。0の場合は目的地が未定
  end

  methods
    function obj = Situation(situationNumber, destinationNodes)
      if situationNumber < 0 || situationNumber > 63
        error('situationNumber must be in 0 to 63');
      end

      obj.situationNumber = situationNumber;

      if nargin == 2
        if size(destinationNodes, 1) == 6 && size(destinationNodes, 2) == 1
          obj.destinationNodes = destinationNodes;
        else
          error('destinationNodes must be a 6x1 array');
        end
      else
        obj.destinationNodes = zeros(6, 1);
      end
    end
  end

  methods
    function isequal = eq(obj, obj2)
      isequal = (obj.situationNumber == obj2.situationNumber) && all(obj.destinationNodes == obj2.destinationNodes);
    end

    function result = ismember(obj, situationArray)
      result = false;
      for i = 1:length(situationArray)
        if obj == situationArray(i)
          result = true;
          break;
        end
      end
    end
  end

  methods
    % 現在のsituationにおいて、現行プレイヤ集合の0-1表記配列を返す
    function result = getPresenceSet(obj)
      result = zeros(6, 1);
      situationNumberBinary = dec2bin(obj.situationNumber, 6);

      for playerIndex = 1:6
        result(playerIndex) = str2double(situationNumberBinary(7-playerIndex));
      end
    end

    % 現在のsituationにおいて、潜在プレイヤ集合の0-1表記配列を返す。
    function result = getPotentialSet(obj)
      presenceSet = obj.getPresenceSet();
      result = zeros(6, 1);

      for playerIndex = 1:6
        if (playerIndex == 1 || playerIndex == 3 || playerIndex == 5) 
          continue;
        end

        if presenceSet(playerIndex) == 1 && presenceSet(playerIndex-1) == 0 % 乗客が出現しており、そのノードにおいて、現行プレイヤ集合に属するタクシーが存在しない場合
          result(playerIndex-1) = 1;
        end
      end
    end
  end

  % 現在のsituationにおいて、マッチング対象プレイヤ集合をタクシーと乗客に分けてPlayerオブジェクトの配列として返す
  methods
    function [taxis, passengers] = getMatchablePlayers(obj)
      [~, ~, ~, ~, m, ~, ~, ~, ~, ~, ~] = ParamsHelper.getSymbolicParams();
      presenceSet = obj.getPresenceSet();
      potentialSet = obj.getPotentialSet();
      taxis = [];
      passengers = [];

      for playerIndex = 1:6
        if (~presenceSet(playerIndex) && ~potentialSet(playerIndex)) 
          continue;
        end
        if (playerIndex == 1 || playerIndex == 3 || playerIndex == 5)
          if presenceSet(playerIndex) == 1
            taxis = [taxis, Player(playerIndex, 0, 0)];
          elseif potentialSet(playerIndex) == 1
            taxis = [taxis, Player(playerIndex, m((playerIndex+1)/2), 0)];
          end
        else
          passengers = [passengers, Player(playerIndex, 0, obj.destinationNodes(playerIndex))];
        end
      end
    end
  end
  
  % 現在のsituationにおいて、指定したplayerIndexに対応するプレイヤが存在するかどうかを返す
  methods
    function result = isPlayerPresent(obj, targetPlayerIndex)
      presenceSet = obj.getPresenceSet();
      for playerIndex = 1:6
        if playerIndex == targetPlayerIndex
          result = presenceSet(playerIndex) == 1;
          break;
        end
      end
    end
  end

  % 現在のsituationから、指定したプレイヤが出現/消滅した後のsituationを返す
  methods
    function newSituation = createNextSituation(obj, appearedPlayerIndices, disappearedPlayerIndices, destinationNodes)

      if nargin < 4
        destinationNodes = zeros(6, 1);
      end

      newSituationNumber = obj.situationNumber;
      newDestinationNodes = destinationNodes;

      for playerIndex = 1:length(appearedPlayerIndices)
        appearedPlayerIndex = appearedPlayerIndices(playerIndex);
        if ~obj.isPlayerPresent(appearedPlayerIndex)
          newSituationNumber = newSituationNumber + 2^(appearedPlayerIndex-1);
        else
          newDestinationNodes(appearedPlayerIndex) = 0;
        end
      end

      for playerIndex = 1:length(disappearedPlayerIndices)
        disappearedPlayerIndex = disappearedPlayerIndices(playerIndex);
        if obj.isPlayerPresent(disappearedPlayerIndex)
          newSituationNumber = newSituationNumber - 2^(disappearedPlayerIndex-1);
        else
          error('Player %d is not present in the current situation', disappearedPlayerIndex);
        end
      end

      newSituation = Situation(newSituationNumber, newDestinationNodes);
    end

    % 現在のsituationから、乗客が出現した直後の起こりうる全てのsituationを返す
    function newSituations = createNextSituationsByOneStep(obj)
      newSituations = [];
      [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, destinationNodesCandidates] = ParamsHelper.getSymbolicParams();
      for i = 1:length(destinationNodesCandidates)
        destinationNodesCandidate = destinationNodesCandidates(:, i);
        appearedPlayerIndices = find(destinationNodesCandidate);

        newSituations = [newSituations, obj.createNextSituation(appearedPlayerIndices, [], destinationNodesCandidate)];
      end
    end
  end

  methods
    % 現在のsituationにおいて、考えられる全てのPlayerMatchingオブジェクトを配列として返す
    function playerMatchings = getPlayerMatchings(obj)
      [taxis, passengers] = obj.getMatchablePlayers();
      playerMatchings = UtilsHelper.generateMatchings(taxis, passengers);
    end

    % 現在のsituationにおいて、考えられる全てのPlayerMatchingオブジェクト配列のうち、最適なものを返す。もし期待効用にxが含まれていて、最適なものが一意に定まらない場合は、空を返す
    function playerMatching = getOptimalPlayerMatching(obj, x)
      playerMatchings = obj.getPlayerMatchings();
      optimalPlayerMatching = [];
      maxExpectedUtility = Inf;

      symFlag = false;
      expectedUtilityArray = [];
      for i = 1:length(playerMatchings)
        playerMatching = playerMatchings(i);
        expectedUtility = sum(playerMatching.calculateExpectedUtilities(x));
        expectedUtilityArray = [expectedUtilityArray, expectedUtility];
        try
          if length(playerMatchings) == 1
            optimalPlayerMatching = playerMatching;
          end
          if eval(expectedUtility > maxExpectedUtility)
            maxExpectedUtility = expectedUtility;
            optimalPlayerMatching = playerMatching;
          end
        catch
          symFlag = true;
          continue;
        end
      end

      if symFlag
        disp(expectedUtilityArray);
        playerMatching = [];
        disp('-----------------');
      else
        playerMatching = optimalPlayerMatching;
      end
    end
  end
end