classdef SituationHelper
  % 状況番号を、その状況において存在するプレイヤーの組み合わせに変換する
  methods (Static)
    function presencePair = convertToPresencePair(newSituationNumber)
      presencePair = zeros(6, 1);
      situationNumberBinary = dec2bin(newSituationNumber, 6);
      
      for i = 1:6
        presencePair(i) = str2double(situationNumberBinary(7-i));
      end
    end

    % その状況において存在するプレイヤーの組み合わせを状況番号に変換する
    function situationNumber = convertToSituationNumber(newPresencePair)
      situationNumber = bin2dec(num2str(flip(newPresencePair.')));
    end
  end

  % 起点とする状況から到達可能な状況のうち、指定したプレイヤが存在する状況のみを返す
  % つまり指定したプレイヤの期待効用の漸化式定式化に必要な状況のみを返す
  methods (Static)
    function situationsWithPlayer = extractSituationsWithPlayerWithinReachableSituations(reachableSituations, playerIndex)
      situationsWithPlayer = [];
      for i = 1:length(reachableSituations)
        if reachableSituations(i).presencePair(playerIndex) == 1
          situationsWithPlayer = [situationsWithPlayer, reachableSituations(i)];
        end
      end
    end
  end

  % 指定したノード番号以外のノード番号を返す
  methods (Static)
    function [nodeNum1, nodeNum2] = getAnotherNodeNums(nodeNum)
      if nodeNum == 1
        nodeNum1 = 2;
        nodeNum2 = 3;
      elseif nodeNum == 2
        nodeNum1 = 1;
        nodeNum2 = 3;
      elseif nodeNum == 3
        nodeNum1 = 1;
        nodeNum2 = 2;
      else
        error('nodeNum must be 1, 2, or 3');
      end
    end
  end

  % 指定したplayerIndexで指定したプレイヤがいるノードと同じノードに出現しうるプレイヤのplayerIndexを返す
  % あくまで出現しうるプレイヤのplayerIndexを返すだけであり、実際に出現しているかどうかは考慮していない
  methods (Static)
    function result = getAnotherPlayerIndexInSameNode(playerIndex)
      if mod(playerIndex, 2) == 1
        result = playerIndex + 1;
      else
        result = playerIndex - 1;
      end
    end
  end

  % 指定した状況において、playerIndexで指定したタクシーがいるノード以外で出現している乗客のplayerIndexを返す
  % つまり、playerIndexで指定したタクシーがマッチする可能性のある乗客のplayerIndexを返す
  % playerIndexで指定したタクシーと同じノードにいる乗客との無条件マッチは含めていない
  % playerIndexで指定されたプレイヤーがタクシーでない場合は空の配列を返す
  methods (Static)
    function result = getPassengersInDifferentNode(situation, playerIndex)
      result = [];
      if mod(playerIndex, 2) == 1
        a = situation.isPresent(playerIndex) && ~situation.isPresent(playerIndex + 1);
        b1 = 2*min(setdiff(1:3, (1+playerIndex)/2)) - 1;
        b2 = 2*min(setdiff(1:3, (1+playerIndex)/2));
        b = ~situation.isPresent(b1) && situation.isPresent(b2);
        c1 = 2*max(setdiff(1:3, (1+playerIndex)/2)) - 1;
        c2 = 2*max(setdiff(1:3, (1+playerIndex)/2));
        c = ~situation.isPresent(c1) && situation.isPresent(c2);
        if a && b
          result = [result, b2];
        end
        if a && c
          result = [result, c2];
        end
      end
    end
  end

  % 起点とする状況ごとの到達可能な状況数を表示する
  methods (Static)
    function displayReachableSituationsCount()
      disp("-----------------");
      disp("起点とする状況ごとの到達可能な状況数");
      for situationNumber = 0:63
        situation = Situation(situationNumber, "situationNumber");
        allSituations = situation.enumerateAllSituations(); 
        fprintf('situationNumber: %d, presencePair: %s -> reachableSituationsCount: %d\n', situationNumber, mat2str(situation.presencePair), length(allSituations));
      end
    end
  end

  % 起点とする状況を指定し、その世界線における各プレイヤの期待効用の漸化式を表示し、保存する
  methods (Static)
    function displayAndSaveExpectedUtilityRecurrenceEquations(situation)

      content = '';
      reachableSituations = situation.enumerateAllSituations();

      % 各プレイヤごとに期待効用計算に必要な状況のみを抽出
      % v1 -> 1, ps1 ->2, v2 -> 3, ps2 -> 4, v3 -> 5, ps3 -> 6
      for playerIndex = 1:6
        situationsWithPlayer = SituationHelper.extractSituationsWithPlayerWithinReachableSituations(reachableSituations, playerIndex);
        disp("-----------------");
        playerName = PlayerHelper.convertToPlayerName(playerIndex);
        playerNameSuffixNum = PlayerHelper.convertToPlayerNameSuffixNum(playerIndex);

        % 各situationsWithPlayerのsituationNumberを表示
        for j = 1:length(situationsWithPlayer)
          situationWithPlayer = situationsWithPlayer(j);
          disp("----");
          fprintf('プレイヤ名: %s, 漸化式左辺: x_%s_%d\n', playerName, playerName, situationWithPlayer.situationNumber);
          content = content + "----" + newline;
          content = content + strcat('プレイヤ名: ', playerName, ', 漸化式左辺: x_', playerName, '_', num2str(situationWithPlayer.situationNumber)) + newline;

          nextSituationsBeforeMatch = situationWithPlayer.enumerateNextSituationsEmergingPassenger(true);

          for k = 1:length(nextSituationsBeforeMatch) % 27回ループ
            nextSituationBeforeMatch = nextSituationsBeforeMatch(k);
            if nextSituationBeforeMatch.isMatched(playerIndex) % 無条件マッチ
              if PlayerHelper.isTaxi(playerIndex)
                passengerIndexInSameNode = SituationHelper.getAnotherPlayerIndexInSameNode(playerIndex);
                destinationNodeNum = TransitionHelper.emergedPairsPassengerWithDestionationValued(passengerIndexInSameNode, k);
                if destinationNodeNum == 0
                  [destinationNodeNum1, destinationNodeNum2] = SituationHelper.getAnotherNodeNums(playerNameSuffixNum);
                  destinationNodeNum = strcat('k(k:', num2str(destinationNodeNum1), ',', num2str(destinationNodeNum2), ')');      
                  fprintf('漸化式右辺: u_%d_%d_%s\n', playerNameSuffixNum, playerNameSuffixNum, destinationNodeNum);          
                else
                  fprintf('漸化式右辺: u_%d_%d_%d\n', playerNameSuffixNum, playerNameSuffixNum, destinationNodeNum);
                end
                content = content + strcat('漸化式右辺: u_', num2str(playerNameSuffixNum), '_', num2str(playerNameSuffixNum), '_', num2str(destinationNodeNum)) + newline;
              else
                fprintf('漸化式右辺: r_%d_%d\n', playerNameSuffixNum, playerNameSuffixNum);
                content = content + strcat('漸化式右辺: r_', num2str(playerNameSuffixNum), '_', num2str(playerNameSuffixNum)) + newline;
              end
            else
              if ~PlayerHelper.isTaxi(playerIndex) 
                % text = strcat(text, ' +a');% 乗客ならば効用がaだけ下がる
                % 無条件マッチしていない乗客が出現する場合、その乗客と同ノードにmステップ後にタクシーがお迎えに来る場合の効用を計算する
                text = strcat('漸化式右辺: r_', num2str(playerNameSuffixNum), '_', num2str(playerNameSuffixNum), ' + ma');
              else
                text = strcat('漸化式右辺: x_', playerName, '_' , num2str(nextSituationBeforeMatch.situationNumber));
                passengersInDifferentNode = SituationHelper.getPassengersInDifferentNode(nextSituationBeforeMatch, playerIndex);

                destinationNodeNums = [];
                for l = 1:length(passengersInDifferentNode)
                  destinationNodeNums = [destinationNodeNums, TransitionHelper.emergedPairsPassengerWithDestionationValued(passengersInDifferentNode(l), k)];
                end
                for l = 1:length(passengersInDifferentNode)
                  destinationNodeNum = destinationNodeNums(l);
                  if destinationNodeNums(l) == 0
                    [destinationNodeNum1, destinationNodeNum2] = SituationHelper.getAnotherNodeNums(PlayerHelper.convertToPlayerNameSuffixNum(passengersInDifferentNode(l)));
                    destinationNodeNum = strcat('k(k:', num2str(destinationNodeNum1), ',', num2str(destinationNodeNum2), ')');
                    text = strcat(text, ' or u_', num2str(playerNameSuffixNum), '_', num2str(PlayerHelper.convertToPlayerNameSuffixNum(passengersInDifferentNode(l))), '_', destinationNodeNum);
                    continue;
                  end
                  text = strcat(text, ' or u_', num2str(playerNameSuffixNum), '_', num2str(PlayerHelper.convertToPlayerNameSuffixNum(passengersInDifferentNode(l))), '_', num2str(destinationNodeNum));
                end
              end
              fprintf('%s\n', text);
              content = content + text + newline;
            end
          end
        end
      end

      fileName = strcat('RecurrenceEquations_', num2str(situation.situationNumber));
      disp(fileName);
      Utils.writeTxtFile(fileName, content);
    end
  end
end
