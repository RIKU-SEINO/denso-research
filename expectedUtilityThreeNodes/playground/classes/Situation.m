classdef Situation
  properties
    situationNumber % 状況番号
    presencePair % その状況において存在するプレイヤーの組み合わせ
  end

  methods
    function obj = Situation(attr, type)
      if type == "situationNumber"
        obj.situationNumber = attr;
        obj.presencePair = SituationHelper.convertToPresencePair(attr);
      elseif type == "presencePair"
        obj.presencePair = attr;
        obj.situationNumber = SituationHelper.convertToSituationNumber(attr);
      else
        error("type must be 'situationNumber' or 'presencePair'");
      end
    end
  end

  % ネットワーク上にプレイヤがいるかどうかを返す
  % playerIndex: プレイヤーのインデックス
  % v1: 1, ps1: 2, v2: 3, ps2: 4, v3: 5, ps3: 6
  methods
    function result = isPresent(obj, playerIndex)
      result = obj.presencePair(playerIndex) == 1;
    end
  end

  methods
    % 状況遷移前と後で出現/消滅したプレイヤーインデックスを返す
    function [emergedPlayerIndices, disappearedPlayerIndices] = getEmergedAndDisappearedPlayerIndices(obj, nextSituation)
      emergedPlayerIndices = [];
      disappearedPlayerIndices = [];
      for playerIndex = 1:6
        if obj.isPresent(playerIndex) && ~nextSituation.isPresent(playerIndex)
          disappearedPlayerIndices = [disappearedPlayerIndices, playerIndex];
        elseif ~obj.isPresent(playerIndex) && nextSituation.isPresent(playerIndex)
          emergedPlayerIndices = [emergedPlayerIndices, playerIndex];
        end
      end
    end
  end

  % 今現在のsituationにおいて、同じノードにいるタクシーと乗客が無条件マッチし消滅する状況を返す
  methods
    function obj = removeTaxiAndPassengerInSameNode(obj)
      for i = 1:3
        if obj.isPresent(2*i-1) && obj.isPresent(2*i)
          obj.presencePair(2*i-1) = 0;
          obj.presencePair(2*i) = 0;
        end
      end
      obj.situationNumber = SituationHelper.convertToSituationNumber(obj.presencePair);
    end
  end

  methods
    % situation同士の比較
    function isEqual = eq(obj1, obj2)
      isEqual = isequal(obj1.situationNumber, obj2.situationNumber) && ...
                isequal(obj1.presencePair, obj2.presencePair);
    end

    % 現在の状況から乗客の出現によって遷移できるSituationオブジェクトを列挙する
    function nextSituations = enumerateNextSituationsEmergingPassenger(obj)
      % 遷移可能ペアを取得(6x8行列)
      a = TransitionHelper.emergedPairsPassenger;
      % 現在の状態(6x1行列)
      b = obj.presencePair;

      nextSituations = [];
      for j = 1:size(a, 2)
        nextPresencePair = a(:, j) | b;
        nextSituation = Situation(nextPresencePair, "presencePair");
        if ~ismember(nextSituation, nextSituations)
          nextSituations = [nextSituations, nextSituation];
        end
      end
    end

    % 現在の状況からタクシーの出現によって遷移できるSituationオブジェクトを列挙する
    function nextSituations = enumerateNextSituationsEmergingTaxi(obj)
      % 遷移可能ペアを取得(6x8行列)
      a = TransitionHelper.emergedPairsTaxi;
      % 現在の状態(6x1行列)
      b = obj.presencePair;

      nextSituations = [];
      for j = 1:size(a, 2)
        nextPresencePair = a(:, j) | b;
        nextSituation = Situation(nextPresencePair, "presencePair");
        if ~ismember(nextSituation, nextSituations)
          nextSituations = [nextSituations, nextSituation];
        end
      end
    end
  end

  methods
    % objから到達可能な全てのsituationとそのtransitionを返す
    function [allSituations, transition] = enumerateAllSituations(obj)
      queue = {obj};
      visited = containers.Map();
      visited(num2str(obj.situationNumber)) = true;
      
      allSituations = {obj};

      transition = Transition();
      
      % BFS探索
      while ~isempty(queue)
        currentSituation = queue{1};
        queue(1) = [];
        
        % 乗客が出現する遷移とタクシーが出現する遷移を列挙
        nextSituationsEmergingPassenger = currentSituation.enumerateNextSituationsEmergingPassenger();
        nextSituationsEmergingTaxi = currentSituation.enumerateNextSituationsEmergingTaxi();
        
        for i = 1:length(nextSituationsEmergingPassenger)
            nextSituationBeforeMatch = nextSituationsEmergingPassenger(i);
            nextSituation = nextSituationBeforeMatch.removeTaxiAndPassengerInSameNode();
            
            key = num2str(nextSituation.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                queue{end + 1} = nextSituation;
                allSituations{end + 1} = nextSituation;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = currentSituation.getEmergedAndDisappearedPlayerIndices(nextSituationBeforeMatch);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              fprintf('currentSituation: %d\n', currentSituation.situationNumber);
              fprintf('nextSituationBeforeMatch: %d\n', nextSituationBeforeMatch.situationNumber);
              fprintf('emergedPlayerIndices: %s\n', mat2str(emergedPlayerIndices));
              fprintf('disappearedPlayerIndices: %s\n', mat2str(disappearedPlayerIndices));
              disp('---');
              transition.updateTransitionValuedMatrix(currentSituation.situationNumber, nextSituationBeforeMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transition.updateTransitionBinaryMatrix(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituation);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              fprintf('nextSituationBeforeMatch: %d\n', nextSituationBeforeMatch.situationNumber);
              fprintf('nextSituation: %d\n', nextSituation.situationNumber);
              fprintf('emergedPlayerIndices: %s\n', mat2str(emergedPlayerIndices));
              fprintf('disappearedPlayerIndices: %s\n', mat2str(disappearedPlayerIndices));
              disp('---');
              transition.updateTransitionValuedMatrix(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transition.updateTransitionBinaryMatrix(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end
        end

        for i = 1:length(nextSituationsEmergingTaxi)
            nextSituationBeforeMatch = nextSituationsEmergingTaxi(i);
            nextSituation = nextSituationBeforeMatch.removeTaxiAndPassengerInSameNode();
            
            key = num2str(nextSituation.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                queue{end + 1} = nextSituation;
                allSituations{end + 1} = nextSituation;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = currentSituation.getEmergedAndDisappearedPlayerIndices(nextSituationBeforeMatch);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              fprintf('currentSituation: %d\n', currentSituation.situationNumber);
              fprintf('nextSituationBeforeMatch: %d\n', nextSituationBeforeMatch.situationNumber);
              fprintf('emergedPlayerIndices: %s\n', mat2str(emergedPlayerIndices));
              fprintf('disappearedPlayerIndices: %s\n', mat2str(disappearedPlayerIndices));
              disp('---');
              transition.updateTransitionValuedMatrix(currentSituation.situationNumber, nextSituationBeforeMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transition.updateTransitionBinaryMatrix(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituation);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              fprintf('nextSituationBeforeMatch: %d\n', nextSituationBeforeMatch.situationNumber);
              fprintf('nextSituation: %d\n', nextSituation.situationNumber);
              fprintf('emergedPlayerIndices: %s\n', mat2str(emergedPlayerIndices));
              fprintf('disappearedPlayerIndices: %s\n', mat2str(disappearedPlayerIndices));
              disp('---');
              transition.updateTransitionValuedMatrix(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transition.updateTransitionBinaryMatrix(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end
        end
      end
    end
  end
end