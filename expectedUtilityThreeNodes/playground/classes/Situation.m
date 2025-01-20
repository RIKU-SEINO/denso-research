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
    % 今現在のsituationにおいて、異なるノードでマッチすることを考慮した際に、遷移先のsituationを複数列挙する
    function nextSituations = removeTaxiAndPassengerInDifferentNode(obj)
      nextSituations = [];
      for i = 1:6
        if mod(i, 2) == 1 % タクシーの場合
          passengers = SituationHelper.getPassengersInDifferentNode(obj, i);
          for j = 1:length(passengers)
            nextPresencePair = obj.presencePair;
            nextPresencePair(i) = 0;
            nextPresencePair(passengers(j)) = 0;
            nextSituation = Situation(nextPresencePair, "presencePair");
            nextSituations = [nextSituations, nextSituation];
          end
        end
      end
    end
  end

  methods
    % 今現在のsituationにおいて、乗客を全て取り除いた状況を返す
    function nextSituation = removeAllPassengers(obj)
      nextPresencePair = obj.presencePair;
      for i = 1:6
        if mod(i, 2) == 0 % 乗客の場合
          nextPresencePair(i) = 0;
        end
      end
      nextSituation = Situation(nextPresencePair, "presencePair");
    end
  end

  methods
    % 今現在出現している乗客全てに対して、同ノードにタクシーを出現させた状況を返す
    function nextSituation = addTaxiToPassengerInSameNode(obj)
      nextPresencePair = obj.presencePair;
      for i = 1:6
        if mod(i, 2) == 0 && obj.isPresent(i) == 1 % 乗客の場合かつ乗客が存在する場合
          nextPresencePair(i-1) = 1;
        end
      end
      nextSituation = Situation(nextPresencePair, "presencePair");
    end
  end

  methods
    function result = isMatched(obj, playerIndex)
      if mod(playerIndex, 2) == 1%playerIndexで指定されたプレイヤがタクシーの場合
        result = obj.isPresent(playerIndex) && obj.isPresent(playerIndex + 1);
      else%playerIndexで指定されたプレイヤが乗客の場合
        result = obj.isPresent(playerIndex) && obj.isPresent(playerIndex - 1);
      end
    end
  end

  methods
    % situation同士の比較
    function isEqual = eq(obj1, obj2)
      isEqual = isequal(obj1.situationNumber, obj2.situationNumber) && ...
                isequal(obj1.presencePair, obj2.presencePair);
    end

    % 現在の状況から乗客の出現によって遷移できるSituationオブジェクトを列挙する
    function nextSituations = enumerateNextSituationsEmergingPassenger(obj, destinationVariation)
      if destinationVariation
        % 遷移可能ペアを取得(6x27行列)
        a = TransitionHelper.emergedPairsPassengerWithDestionation;
      else
        % 遷移可能ペアを取得(6x8行列)
        a = TransitionHelper.emergedPairsPassenger;
      end
      % 現在の状態(6x1行列)
      b = obj.presencePair;

      nextSituations = [];
      for j = 1:size(a, 2)
        nextPresencePair = double(a(:, j) | b);
        nextSituation = Situation(nextPresencePair, "presencePair");
        if ~ismember(nextSituation, nextSituations) || destinationVariation
          nextSituations = [nextSituations, nextSituation];
        end
      end
    end

    % 現在の状況からタクシーの出現によって遷移できるSituationオブジェクトを列挙する
    function nextSituations = enumerateNextSituationsEmergingTaxi(obj)
      % 遷移可能ペアを取得(6x27行列)
      a = TransitionHelper.emergedPairsTaxi;
      % 現在の状態(6x1行列)
      b = obj.presencePair;
  
      nextSituations = [];
      for j = 1:size(a, 2)
          % 初期化
          nextPresencePair = zeros(size(b,1),1);
          for i = 1:length(b) - 1
              % すでにタクシー(b(i)==1)がいるか、もしくはすでに乗客(b(i+1)==1)がいて、同じノードにタクシーが出現する(a(i,j)==1)場合
              if (b(i) == 1) || ((a(i, j) == 1) && (b(i+1) == 1) && (b(i) == 0))
                  nextPresencePair(i) = 1;
              end
          end
          nextPresencePair(end) = b(end);
  
          % 最後の行は i+1 が存在しないので無視
  
          % Situation オブジェクトを作成
          nextSituation = Situation(nextPresencePair, "presencePair");
  
          % 一意性の確認
          if ~ismember(nextSituation, nextSituations)
              nextSituations = [nextSituations, nextSituation];
          end
      end
    end
  end

  methods
    % objから到達可能な全てのsituationとそのtransitionを返す
    function [allSituations, transitions] = enumerateAllSituations(obj)
      queue = {obj};
      visited = containers.Map();
      visited(num2str(obj.situationNumber)) = true;
      
      allSituations = [obj];

      transitions = Transitions();
      
      % BFS探索
      while ~isempty(queue)
        currentSituation = queue{1};
        queue(1) = [];
        
        % 乗客が出現する遷移とタクシーが出現する遷移を列挙
        nextSituationsEmergingPassenger = currentSituation.enumerateNextSituationsEmergingPassenger(false);
        nextSituationsEmergingTaxi = currentSituation.enumerateNextSituationsEmergingTaxi();
        
        for i = 1:length(nextSituationsEmergingPassenger)
            nextSituationBeforeMatch = nextSituationsEmergingPassenger(i);
            nextSituation = nextSituationBeforeMatch.removeTaxiAndPassengerInSameNode();
            nextSituationsAfterSecondMatch = nextSituation.removeTaxiAndPassengerInDifferentNode();%異ノードマッチ
            
            key = num2str(nextSituation.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                queue{end + 1} = nextSituation;
                allSituations(end + 1) = nextSituation;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = currentSituation.getEmergedAndDisappearedPlayerIndices(nextSituationBeforeMatch);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % セルフループも考慮
              transitions = transitions.updateTransitionValuedCellArray(currentSituation.situationNumber, nextSituationBeforeMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end

            %ver2. v1, ps2が出現している状況から、v1, ps2が消滅している状況への遷移は起こり得ない。なぜかというと、v1, ps2という状況になっている段階で、v1とps2はマッチしないことを選択した過去があるため、その後においてもv1とps2がマッチすることはないからである。（By hayakawa）だがしかし、beforeMatch状態からafterSecondMatch状態へのエッジを結ぶ必要はあるので、beforeMatchからnextSituationへの遷移は考えず、beforeMatchからafterSecondMatchへの遷移を考える。

            % [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituation);
            % if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % セルフループも考慮
            %   transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
            %   transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            % end

            for j = 1:length(nextSituationsAfterSecondMatch)
                nextSituationAfterSecondMatch = nextSituationsAfterSecondMatch(j);
                key = num2str(nextSituationAfterSecondMatch.situationNumber);
                if ~isKey(visited, key)
                    visited(key) = true;
                    queue{end + 1} = nextSituationAfterSecondMatch;
                    allSituations(end + 1) = nextSituationAfterSecondMatch;
                end

                [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituationAfterSecondMatch);
                if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % セルフループも考慮
                  % ver2改変部分
                  % transitions = transitions.updateTransitionValuedCellArray(nextSituation.situationNumber, nextSituationAfterSecondMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
                  % transitions = transitions.updateTransitionBinaryCellArray(nextSituation.situationNumber, nextSituationAfterSecondMatch.situationNumber, 1);
                  if (nextSituation.situationNumber ~= nextSituationBeforeMatch.situationNumber)
                    transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeMatch.situationNumber, nextSituationAfterSecondMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
                    transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituationAfterSecondMatch.situationNumber, 1);
                  end
                end
            end
        end

        for i = 1:length(nextSituationsEmergingTaxi)
            nextSituationBeforeMatch = nextSituationsEmergingTaxi(i);
            nextSituation = nextSituationBeforeMatch.removeTaxiAndPassengerInSameNode();
            
            key = num2str(nextSituation.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                queue{end + 1} = nextSituation;
                allSituations(end + 1) = nextSituation;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = currentSituation.getEmergedAndDisappearedPlayerIndices(nextSituationBeforeMatch);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % セルフループも考慮
              transitions = transitions.updateTransitionValuedCellArray(currentSituation.situationNumber, nextSituationBeforeMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituation);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % セルフループも考慮
              transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituation.situationNumber, 1);
            end

            nextSituationsAfterSecondMatch = nextSituation.removeTaxiAndPassengerInDifferentNode();%異ノードマッチ
            for j = 1:length(nextSituationsAfterSecondMatch)
                nextSituationAfterSecondMatch = nextSituationsAfterSecondMatch(j);
                key = num2str(nextSituationAfterSecondMatch.situationNumber);
                if ~isKey(visited, key)
                    visited(key) = true;
                    queue{end + 1} = nextSituationAfterSecondMatch;
                    allSituations(end + 1) = nextSituationAfterSecondMatch;
                end

                [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituationAfterSecondMatch);
                if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % セルフループも考慮
                  if (nextSituation.situationNumber ~= nextSituationBeforeMatch.situationNumber)
                    transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeMatch.situationNumber, nextSituationAfterSecondMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
                    transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituationAfterSecondMatch.situationNumber, 1);
                  end
                end
            end
        end
      end
    end
  end

  methods
    % objから到達可能な全てのsituationとそのtransitionを返す
    function [allSituations, transitions] = enumerateAllSituations2(obj)
      queue = {obj};
      visited = containers.Map();
      queueAdded = containers.Map();
      visited(num2str(obj.situationNumber)) = true;
      
      allSituations = [obj];

      transitions = Transitions();
      
      % BFS探索
      while ~isempty(queue)
        currentSituation = queue{1};
        queue(1) = [];

        % % もしcurrentSituationにおいて、乗客が存在する場合
        % if currentSituation.isPresent(2) || currentSituation.isPresent(4) || currentSituation.isPresent(6)
        %   continue;
        % end
        
        % 乗客が出現する遷移とタクシーが出現する遷移を列挙(currentSituation -> nextSituationBeforeMatch)
        nextSituationsEmergingPassengerBeforeMatch = currentSituation.enumerateNextSituationsEmergingPassenger(false);
        % nextSituationsEmergingTaxiBeforeMatch = currentSituation.enumerateNextSituationsEmergingTaxi();
        % nextSituationsBeforeMatch = [nextSituationsEmergingPassengerBeforeMatch, nextSituationsEmergingTaxiBeforeMatch]; %同ノードへのタクシーの出現はこのステップでは考慮しない
        nextSituationsBeforeMatch = nextSituationsEmergingPassengerBeforeMatch;
        for i = 1:length(nextSituationsBeforeMatch)
            nextSituationBeforeMatch = nextSituationsBeforeMatch(i);
            key = num2str(nextSituationBeforeMatch.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                allSituations(end + 1) = nextSituationBeforeMatch;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = currentSituation.getEmergedAndDisappearedPlayerIndices(nextSituationBeforeMatch);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices) || isempty(disappearedPlayerIndices) || isempty(emergedPlayerIndices) % 乗客が全く出現しないこともあるのでセルフループも考慮
              transitions = transitions.updateTransitionValuedCellArray(currentSituation.situationNumber, nextSituationBeforeMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(currentSituation.situationNumber, nextSituationBeforeMatch.situationNumber, 1);
            end
        end

        % nextSituationBeforeMatchにおいて、同じノードでマッチしているプレイヤを削除する(nextSituationBeforeMatch -> nextSituationBeforeSecondMatch)
        nextSituationsBeforeSecondMatch = [];
        for i = 1:length(nextSituationsBeforeMatch)
            nextSituationBeforeMatch = nextSituationsBeforeMatch(i);
            nextSituationBeforeSecondMatch = nextSituationBeforeMatch.removeTaxiAndPassengerInSameNode();
            nextSituationsBeforeSecondMatch = [nextSituationsBeforeSecondMatch, nextSituationBeforeSecondMatch];
            key = num2str(nextSituationBeforeSecondMatch.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                allSituations(end + 1) = nextSituationBeforeSecondMatch;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeMatch.getEmergedAndDisappearedPlayerIndices(nextSituationBeforeSecondMatch);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeMatch.situationNumber, nextSituationBeforeSecondMatch.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeMatch.situationNumber, nextSituationBeforeSecondMatch.situationNumber, 1);
            end
        end

        % nextSituationBeforeSecondMatchにおいて、異なるノードでマッチしているプレイヤを削除する(nextSituationBeforeSecondMatch -> nextSituationAfterSecondMatch)
        nextSituationsAfterSecondMatch = [];
        for i = 1:length(nextSituationsBeforeSecondMatch)
          nextSituationBeforeSecondMatch = nextSituationsBeforeSecondMatch(i);
          % nextSituationBeforeSecondMatchにおいて、異なるノードでマッチしているプレイヤを削除する(nextSituationBeforeSecondMatch -> nextSituation)
          nextSituationsAfterDifferentBeforeSame = nextSituationBeforeSecondMatch.removeTaxiAndPassengerInDifferentNode(); % ex. ps1, v2, ps3で、ps3とv2が異ノードマッチを選択-> ps1が取り残される
          % nextSituationAfterSame = nextSituationBeforeSecondMatch.removeAllPassengers();% ex. ps1, v2で、ps1が同ノードマッチを選択-> v2
          nextSituationAfterSame1 = nextSituationBeforeSecondMatch.addTaxiToPassengerInSameNode();% ex. ps1, v2で、ps1が同ノードマッチを選択-> v1, ps1, v2
          nextSituationAfterSame2 = nextSituationAfterSame1.removeTaxiAndPassengerInSameNode();% ex. v1, ps1, v2 -> v2
          nextSituationsAfterSecondMatch = [nextSituationsAfterSecondMatch, nextSituationAfterSame2];

          key = num2str(nextSituationAfterSame1.situationNumber);
          if ~isKey(visited, key)
              visited(key) = true;
              allSituations(end + 1) = nextSituationAfterSame1;
          end
          key = num2str(nextSituationAfterSame2.situationNumber);
          if ~isKey(visited, key)
              visited(key) = true;
              allSituations(end + 1) = nextSituationAfterSame2;
          end
          % 1サイクルの終了なので、queueに追加するが、もしnextSituationAfterSame2がqueueに追加された過去がなければ、queueに追加する。追加履歴はqueueAddedに記録
          if ~isKey(queueAdded, key)
            queueAdded(key) = true;
            queue{end + 1} = nextSituationAfterSame2;
            allSituations(end + 1) = nextSituationAfterSame2;
          end

          [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeSecondMatch.getEmergedAndDisappearedPlayerIndices(nextSituationAfterSame1);
          if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
            transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeSecondMatch.situationNumber, nextSituationAfterSame1.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
            transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeSecondMatch.situationNumber, nextSituationAfterSame1.situationNumber, 1);
          end

          [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationAfterSame1.getEmergedAndDisappearedPlayerIndices(nextSituationAfterSame2);
          if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
            transitions = transitions.updateTransitionValuedCellArray(nextSituationAfterSame1.situationNumber, nextSituationAfterSame2.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
            transitions = transitions.updateTransitionBinaryCellArray(nextSituationAfterSame1.situationNumber, nextSituationAfterSame2.situationNumber, 1);
          end

          % nextSituationBeforeSecondMatchが ps1, v2, v3の時、v2とps3が異ノードマッチを起こす場合、ps1は取り残されるので、取り残されたps1は同ノードマッチを起こす
          for j = 1:length(nextSituationsAfterDifferentBeforeSame)
            nextSituationAfterDifferentBeforeSame = nextSituationsAfterDifferentBeforeSame(j);
            % nextSituationAfterDifferentAfterSame = nextSituationAfterDifferentBeforeSame.removeAllPassengers();
            nextSituationAfterDifferentAfterSame1 = nextSituationAfterDifferentBeforeSame.addTaxiToPassengerInSameNode();
            nextSituationAfterDifferentAfterSame2 = nextSituationAfterDifferentAfterSame1.removeTaxiAndPassengerInSameNode();

            nextSituationsAfterSecondMatch = [nextSituationsAfterSecondMatch, nextSituationAfterDifferentAfterSame2];

            key = num2str(nextSituationAfterDifferentAfterSame1.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                allSituations(end + 1) = nextSituationAfterDifferentAfterSame1;
            end
            key = num2str(nextSituationAfterDifferentAfterSame2.situationNumber);
            if ~isKey(visited, key)
                visited(key) = true;
                allSituations(end + 1) = nextSituationAfterDifferentAfterSame2;
            end
            % 1サイクルの終了なので、queueに追加するが、もしnextSituationAfterDifferentAfterSame2がqueueに追加された過去がなければ、queueに追加する。追加履歴はqueueAddedに記録
            if ~isKey(queueAdded, key)
              queueAdded(key) = true;
              queue{end + 1} = nextSituationAfterDifferentAfterSame2;
              allSituations(end + 1) = nextSituationAfterDifferentAfterSame2;
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationBeforeSecondMatch.getEmergedAndDisappearedPlayerIndices(nextSituationAfterDifferentAfterSame1);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              transitions = transitions.updateTransitionValuedCellArray(nextSituationBeforeSecondMatch.situationNumber, nextSituationAfterDifferentAfterSame1.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(nextSituationBeforeSecondMatch.situationNumber, nextSituationAfterDifferentAfterSame1.situationNumber, 1);
            end

            [emergedPlayerIndices, disappearedPlayerIndices] = nextSituationAfterDifferentAfterSame1.getEmergedAndDisappearedPlayerIndices(nextSituationAfterDifferentAfterSame2);
            if ~isempty(disappearedPlayerIndices) || ~isempty(emergedPlayerIndices)
              transitions = transitions.updateTransitionValuedCellArray(nextSituationAfterDifferentAfterSame1.situationNumber, nextSituationAfterDifferentAfterSame2.situationNumber, emergedPlayerIndices, disappearedPlayerIndices);
              transitions = transitions.updateTransitionBinaryCellArray(nextSituationAfterDifferentAfterSame1.situationNumber, nextSituationAfterDifferentAfterSame2.situationNumber, 1);
            end
          end
        end      
      end
    end
  end
end