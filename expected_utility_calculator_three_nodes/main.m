clear;

warning('off','all')
warning
addpath('./class');

%% パラメータ設定
[w, c, r_0, a, m, p, p_, u, r, q, d] = ParamsHelper.getSymbolicParams();

%% 変数の定義
x = ExpectedUtilityHelper.generateExpectedUtilitiesSymbolicMatrix();

try
    dataAllConditions = load('data/allConditions.mat', 'allConditions');
    allConditions = dataAllConditions.allConditions;
catch ME
    disp(ME.message);
    ExpectedUtilityHelper.saveExpectedUtilityMaterials(x);

    ExpectedUtilityHelper.writeRightVecs("data/right_vec/right_vec_summary.txt");
    ExpectedUtilityHelper.writeConditions("data/conditions_vec/conditions_vec_summary.txt");
    ExpectedUtilityHelper.writeAllConditions("data/allConditions.mat");

    dataAllConditions = load('data/allConditions.mat', 'allConditions');
    allConditions = dataAllConditions.allConditions;
end

%% 期待効用の計算

% まずx_v1_1, x_v2_4, x_v3_16を求める
% for playerIndex = [1,3,5]
%     s = (playerIndex - 1)^2;
%     dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(s) + ".mat", "rightVec");
%     rightVec = dataRightVec.rightVec;
%     disp(q.' * cell2sym(rightVec));
% end




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


