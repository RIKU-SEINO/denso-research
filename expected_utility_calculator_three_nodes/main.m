clear;

addpath('./class');


%% 変数の定義
x = generateExpectedUtilitiesSymbolicMatrix();


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

for i = 1:length(currentSituations)
    currentSituation = currentSituations(i);
    optimalPlayerMatching = currentSituation.getOptimalPlayerMatching(x);
end
