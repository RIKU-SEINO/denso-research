clear;

warning('off','all')
warning
addpath('./class');

%% パラメータ設定
[w, c, r_0, a, m, p, p_, u, r, q, d] = ParamsHelper.getSymbolicParams();

%% 変数の定義
x = ExpectedUtilityHelper.generateExpectedUtilitiesSymbolicMatrix();

try
    load("data/right_vec/rightVec_1_0.mat", "rightVec");
    load("data/conditions_vec/conditionsVec_1_0.mat", "conditionsVec");
catch ME
    disp(ME.message);
    ExpectedUtilityHelper.saveExpectedUtilityMaterials(x);

    ExpectedUtilityHelper.writeRightVecs("data/right_vec/right_vec_summary.txt");
    ExpectedUtilityHelper.writeConditions("data/conditions_vec/conditions_vec_summary.txt");
    ExpectedUtilityHelper.writeAllConditions("data/allconditions_summary.txt");
end

%% 期待効用の計算
% まず、x_v1_1, x_v2_4, x_v3_16について期待効用を計算。条件分岐がないので簡単に求められる。
x_vec = [x(2,1); x(5,3); x(17,5)];
Lambda_p = zeros(length(x_vec));
b_p = zeros(length(x_vec), 1);
playerIndices = [1,3,5]; % v1, v2, v3
for idx = 1:length(playerIndices)
    playerIndex = playerIndices(idx);
    situationNumber = 2^(playerIndex-1);
    dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "rightVec");

    rightVec = dataRightVec.rightVec;
    disp(q.' * cell2sym(rightVec))

    M_ps = zeros(27, 3); % 0-1行列
    c_ps = zeros(27, 1); % 定数項ベクトル
    for i = 1:size(M_ps, 1)
        rightVec_i = rightVec{i};
        rightVec_i_arr = children(rightVec_i);
        for j = 1:length(rightVec_i_arr)
            rightVec_i_arr_j = rightVec_i_arr(j);
            rightVec_i_arr_j = rightVec_i_arr_j{1};
            xpsIndexInFlattenx = find(x_vec == rightVec_i_arr_j);
            if ~any(isletter(char(rightVec_i_arr_j)))  % 数値の場合
                c_ps(i) = c_ps(i) + rightVec_i_arr_j;
            else % 変数が含まれている場合
                M_ps(i, xpsIndexInFlattenx) = 1;
            end
        end
    end

    Lambda_p(idx, :) = q.' * M_ps;
    b_p(idx) = q.' * c_ps;
end

inv(eye(3) - Lambda_p) * b_p


% 次に、
% for playerIndex = [1,3,5]
%     situationNumber = 2^(playerIndex-1);
%     dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "rightVec");

%     rightVec = dataRightVec.rightVec;

%     M = zeros(27, 64); % 0-1行列
%     b = zeros(27, 1); % 定数項ベクトル
%     for i = 1:27
%         rightVec_i = rightVec{i};
%         rightVec_i_arr = children(rightVec_i);
%         for j = 1:length(rightVec_i_arr)
%             rightVec_i_arr_j = rightVec_i_arr(j);
%             rightVec_i_arr_j = rightVec_i_arr_j{1};
%             xpsIndexInFlattenx = find(x(:,playerIndex) == rightVec_i_arr_j);
%             if ~any(isletter(char(rightVec_i_arr_j)))  % 数値の場合
%                 b(i) = b(i) + rightVec_i_arr_j;
%             else % 変数が含まれている場合
%                 M(i, xpsIndexInFlattenx) = 1;
%             end
%         end
%     end
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


