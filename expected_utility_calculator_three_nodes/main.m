clear;

warning('off','all')
warning
addpath('./class');


%% 変数の定義
x = ExpectedUtilityHelper.generateExpectedUtilitiesSymbolicMatrix();

% 64通りの状況について、次のステップ
situationNumber = 6;
% ps1(=playerIndex=2)のみ出現
currentSituation = Situation(situationNumber);
appearedPlayerIndices = [2]; % appearedPlayerIndicesの各要素とappearedPlayerDestinationNodesの各要素は対応している
appearedPlayerDestinationNodes = [3]; % appearedPlayerIndicesの各要素とappearedPlayerDestinationNodesの各要素は対応している
disappearedPlayerIndices = [];
destinationNodes = zeros(6, 1);
for i = 1:length(appearedPlayerIndices)
    appearedPlayerIndex = appearedPlayerIndices(i);
    destinationNodes(appearedPlayerIndex) = appearedPlayerDestinationNodes(i);
end
nextSituation = currentSituation.createNextSituation(appearedPlayerIndices, disappearedPlayerIndices, destinationNodes);
playerMatchings = nextSituation.getPlayerMatchings();
for i = 1:length(playerMatchings)
    disp("状況"+nextSituation.situationNumber+"のマッチング"+i+"の期待効用");
    playerMatching = playerMatchings(i);
    expectedUtilities = playerMatching.calculateExpectedUtilities(x);
    disp(expectedUtilities);
end

currentSituations = [];
for situationNumber = 0:63
    currentSituationBase = Situation(situationNumber);
    presenceSet = currentSituationBase.getPresenceSet();
    for i = 1:27
        destinationNodes = ParamsHelper.destinationNodesCandidates(:, i);
        newDestinationNodes = destinationNodes .* presenceSet;
        currentSituationWithDestinationNodes = Situation(situationNumber, newDestinationNodes);
        if ~currentSituationWithDestinationNodes.ismember(currentSituations)
            currentSituations = [currentSituations, currentSituationWithDestinationNodes];
        end
    end
end

% allConditions.matを読み込む
dataAllConditions = load('data/allConditions.mat', 'allConditions');
try
    error;
    allConditions = data.allConditions;
    allConditionsPrepared = true;
catch
    allConditions = {};
    allConditionsPrepared = false;
end

for playerIndex = 1:size(x,2)
    if allConditionsPrepared
        break;
    end
    for situationNumber = 0:size(x,1)-1
        disp("状況"+situationNumber+"のプレイヤー"+playerIndex+"の期待効用: ");
        disp(x(situationNumber+1, playerIndex));

        currentSituation = Situation(situationNumber);
        nextSituations = currentSituation.createNextSituationsByOneStep();

        rightVec = cell(length(nextSituations), 1);
        conditionsVec = cell(length(nextSituations), 1);

        for i = 1:length(nextSituations)
            nextSituation = nextSituations(i);
            playerMatchings = nextSituation.getPlayerMatchings();
            totalExpectedUtilities = sym(zeros(length(playerMatchings), 1));
            for j = 1:length(playerMatchings)
                playerMatching = playerMatchings(j);
                totalExpectedUtilities(j) = playerMatching.calculateTotalExpectedUtility(x);
            end

            totalExpectedUtilities_onlyMax = UtilsHelper.getMaxCandidates(totalExpectedUtilities); % 最大となる候補のみに絞り、最大とならない候補については0*0 doubleでmasking

            optimalPlayerMatchings = [];
            expectedUtilityNextStepArray = [];
            totalExpectedUtilityNextStepArray = [];

            allConditionsByNextSituation = {};
            for j = 1:length(totalExpectedUtilities_onlyMax)
                totalExpectedUtility = totalExpectedUtilities_onlyMax{j};
                if ~isempty(totalExpectedUtility) % 0*0 doubleでmaskingされていないものは、最大となる候補なので、その候補についてのみ社会全体の期待効用和を計算
                    optimalPlayerMatchings = [optimalPlayerMatchings, playerMatchings(j)];
                    expectedUtilitiesNextStep = playerMatchings(j).calculateExpectedUtilities(x);
                    expectedUtilityNextStepArray = [expectedUtilityNextStepArray, expectedUtilitiesNextStep(playerIndex)];
                    totalExpectedUtilityNextStepArray = [totalExpectedUtilityNextStepArray, totalExpectedUtility];
                end
            end

            if isempty(optimalPlayerMatchings)
               error('ERROR: optimalPlayerMatchings is empty');
            end

            conditions = cell(length(totalExpectedUtilityNextStepArray), 1);
            if length(totalExpectedUtilityNextStepArray) > 1
                for j = 1:length(totalExpectedUtilityNextStepArray)% [1,2,3,4]
                    totalExpectedUtilityNextStep = totalExpectedUtilityNextStepArray(j);% これが最大のものの場合を考える ex. 2
                    otherExpectedUtilityNextStepArray = setdiff(totalExpectedUtilityNextStepArray, totalExpectedUtilityNextStep);% [1,3,4]

                    condition = Condition();
                    for k = 1:length(otherExpectedUtilityNextStepArray)
                        otherExpectedUtilityNextStep = otherExpectedUtilityNextStepArray(k);% 1
                        expr = totalExpectedUtilityNextStep >= otherExpectedUtilityNextStep;
                        condition = condition.combineAsAND(Condition(expr));% 2>1 && 2>3 && 2>4
                    end
                    conditions{j} = condition;

                    if ~(condition.isIncluded(allConditions))
                        allConditions{end+1} = condition;
                    end
                end
            end
            rightVec{i} = expectedUtilityNextStepArray;
            conditionsVec{i} = conditions;
        end

        allConditions
        save("data/right_vec/rightVec_"+string(playerIndex)+"_"+string(situationNumber)+".mat", "rightVec");
        save("data/conditions_vec/conditionsVec_"+string(playerIndex)+"_"+string(situationNumber)+".mat", "conditionsVec");
    end
end
save('data/allConditions.mat', 'allConditions');

% 期待効用ベクトルと条件式ベクトルをそれぞれテキストファイルに出力する
ExpectedUtilityHelper.writeRightVecs("data/right_vec/right_vec_summary.txt");
Condition.writeConditions("data/conditions_vec/conditions_vec_summary.txt");


% uniqueMaxCandidates = {};
% for i = 1:length(currentSituations)
%     currentSituation = currentSituations(i);
%     playerMatchings = currentSituation.getPlayerMatchings();
%     totalExpectedUtilities = sym(zeros(length(playerMatchings), 1));
%     for j = 1:length(playerMatchings)
%         playerMatching = playerMatchings(j);
%         totalExpectedUtilities(j) = playerMatching.calculateTotalExpectedUtility(x);
%     end

%     totalExpectedUtilities_potentialMaxFiltered = UtilsHelper.getMaxCandidates(totalExpectedUtilities); % 最大となる候補のみに絞り、最大とならない候補については0*0 doubleでmasking
    
%     % totalExpectedUtilities_potentialMaxFilteredがもしuniqueMaxCandidatesに含まれていないなら、uniqueMaxCandidatesに追加
%     if ~UtilsHelper.isIncluded(totalExpectedUtilities_potentialMaxFiltered, uniqueMaxCandidates)
%         disp("---New MaxCandidates---");
%         totalExpectedUtilities_potentialMaxFiltered
%         uniqueMaxCandidates{end+1} = totalExpectedUtilities_potentialMaxFiltered;   
%     end

%     % もしtotalExpectedUtilities_potentialMaxFilteredの中で、0*0 doubleでないものが1つだけであるなら、
% end

% memo
% まず、全ての不等式を全て洗い出す必要がある。
% 全ての不等式とは、実質的に等価な不等式を重複とし、含めない
% まずは、全てのtotalExpectedUtilities_potentialMaxFilteredから重複を削除する
% 次に、各totalExpectedUtilities_potentialMaxFilteredについて、不等式を全てpermutationで洗い出し、永続的にどこかで管理する(.matなどで。後から解析できるように)
% そのそれぞれのうーんやっぱり何か違う、めちゃくちゃ無駄な計算ばかりしそう、実際これ、かなり場合の数が多そう。どうしよう。不等式の数は3!^15 + 2!^12になるのやばすぎるだろ。
% Equationクラスを作ることが先かな？
% ある状況から1ステップ先の状況をcreateする
% そのそれぞれの状況において、


