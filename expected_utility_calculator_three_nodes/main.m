clear;

warning('off','all')
warning
addpath('./class');

%% パラメータ設定
[w, c, r_0, a, m, p, p_, u, r, q, d] = ParamsHelper.getSymbolicParams();

%% 変数の定義
x = ExpectedUtilityHelper.generateExpectedUtilitiesSymbolicMatrix();

try
    if ~exist('rightVecs', 'var') || ~exist('conditionsVecs', 'var') || ~exist('allPlayerMatchings', 'var') || ~exist('allSocialExpectedUtilities', 'var')
        
        disp("data/materials.matを読み込みます");
        dataMaterials = load("data/materials.mat", 'rightVecs', 'conditionsVecs');
        rightVecs = dataMaterials.rightVecs;
        conditionsVecs = dataMaterials.conditionsVecs;

        disp("data/playerMatchings.matを読み込みます");
        dataPlayerMatchings = load("data/playerMatchings.mat", 'allPlayerMatchings', 'allSocialExpectedUtilities');
        allPlayerMatchings = dataPlayerMatchings.allPlayerMatchings;
        allSocialExpectedUtilities = dataPlayerMatchings.allSocialExpectedUtilities;
    end
catch ME
    disp(ME.message);
    [rightVecs, conditionsVecs, allPlayerMatchings, allSocialExpectedUtilities] = ExpectedUtilityHelper.saveExpectedUtilityMaterials(x);

    ExpectedUtilityHelper.writeRightVecs("data/right_vec_summary.txt");
    ExpectedUtilityHelper.writeConditions("data/conditions_vec_summary.txt");
    ExpectedUtilityHelper.writeAllConditions("data/allconditions_summary.txt");
end

%% 期待効用の計算
%% 1. まず、方程式を構成する要素を定義する
disp("方程式を構成する要素を定義します");
[I, L, b, M, c, cE] = ExpectedUtilityHelper.generateEquationElements(x);
L_default = L;
b_default = b;
M_default = M;
c_default = c;

alreadySolvedVarNames = {};
alreadySolvedVarValues = {};

%% 2. 次に、x_v1_1, x_v2_4, x_v3_16について期待効用を計算。条件分岐がないので簡単に求められる。
disp("x_v1_1, x_v2_4, x_v3_16について期待効用を計算します");
for playerIndex = 1:6

    L_p = L_default{playerIndex}{1}; % x_p = L_p * x_p + b_pのL_p = zeros(64, 64)
    b_p = b_default{playerIndex}{1}; % x_p = L_p * x_p + b_pのb_p = zeros(64, 1)

    for situationNumber = 0:63

        M_ps = M_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのM_ps = zeros(27, 64)
        c_ps = c_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのc_ps = zeros(27, 1)

        if ismember(playerIndex, [1,3,5]) && (situationNumber == 2^(playerIndex-1))

            rightVec = rightVecs{playerIndex, situationNumber+1};

            for i = 1:size(M_ps, 1)
                rightVec_i = rightVec{i};
                rightVec_i_arr = children(rightVec_i);
                for j = 1:length(rightVec_i_arr)
                    rightVec_i_arr_j = rightVec_i_arr(j);
                    rightVec_i_arr_j = rightVec_i_arr_j{1};
                    xpsIndexInFlattenx = find(x(:,playerIndex) == rightVec_i_arr_j);
                    if ~any(isletter(char(rightVec_i_arr_j)))  % 数値の場合
                        c_ps(i) = c_ps(i) + rightVec_i_arr_j;
                    else % 変数が含まれている場合
                        M_ps(i, xpsIndexInFlattenx) = 1;
                    end
                end
            end

            M{playerIndex, situationNumber+1}{1} = M_ps;
            c{playerIndex, situationNumber+1}{1} = c_ps;
        end

        L_p(situationNumber+1, :) = q.' * M_ps;
        b_p(situationNumber+1) = q.' * c_ps;
    end

    L{playerIndex}{1} = L_p;
    b{playerIndex}{1} = b_p;
end

for playerIndex = 1:6
    for situationNumber = 0:63
        if ismember(playerIndex, [1,3,5]) && (situationNumber == 2^(playerIndex-1))
            sol = (I - L{playerIndex}{1}) \ b{playerIndex}{1};
            alreadySolvedVarNames{end+1} = char(x(situationNumber + 1, playerIndex));
            alreadySolvedVarValues{end+1} = sol(situationNumber + 1);
        end
    end
end

M_default = M;
c_default = c;
cE_default = cE;
L_default = L;
b_default = b;

%% 3. 次のペアについて期待効用を同時に求める
% 3-1. x_v1_5, x_v2_5
% 3-2. x_v1_17, x_v3_17
% 3-3. x_v2_20, x_v3_20

disp("条件分岐を含む期待効用を計算します");
pairs = {
    [1,3], 5;
    [1,5], 17;
    [3,5], 20;
};

for pairIdx = 1:length(pairs)
    currentPlayerIndices = pairs{pairIdx, 1};
    currentSituationNumber = pairs{pairIdx, 2};

    for playerIndex = 1:6
        
        for situationNumber = 0:63

            if ismember(playerIndex, currentPlayerIndices) && (situationNumber == currentSituationNumber)

                rightVec = rightVecs{playerIndex, situationNumber+1};
                conditionsVec = conditionsVecs{playerIndex, situationNumber+1};

                newRightVec = {};
                newConditionExprsVec = {};

                for i = 1:length(rightVec)
                    rightVec_i = simplify(subs(rightVec{i}, alreadySolvedVarNames, alreadySolvedVarValues));
                    newRightVec_i = [];
                    conditionsVec_i = conditionsVec{i};
                    newConditionExprsVec_i = [];
                    for j = 1:length(conditionsVec_i)
                        condition = conditionsVec_i{j};
                        if isempty(condition)
                            newRightVec_i = rightVec_i;
                            newConditionExprsVec_i = symtrue;
                            break;
                        end

                        newCondExpr = simplify(subs(condition.expr, alreadySolvedVarNames, alreadySolvedVarValues));

                        if isequal(newCondExpr, symtrue)
                            newRightVec_i = simplify(subs(rightVec_i(j), alreadySolvedVarNames, alreadySolvedVarValues));
                            newConditionExprsVec_i = symtrue;
                            break;
                        elseif isequal(newCondExpr, symfalse)
                            continue;
                        else
                            newRightVec_i = [newRightVec_i, rightVec_i(j)];
                            newConditionExprsVec_i = [newConditionExprsVec_i, newCondExpr];
                        end
                    end

                    newRightVec{end+1, 1} = newRightVec_i;
                    newConditionExprsVec{end+1, 1} = newConditionExprsVec_i;
                end

                [newRightVecCandidates, newConditionExprsVecCandidates] = UtilsHelper.getRightVecAndConditionsVecCandidates(newRightVec, newConditionExprsVec);

                for ii = 1:length(newRightVecCandidates)
                    newRightVecCandidate = newRightVecCandidates{ii};
                    newConditionExprsVecCandidate = newConditionExprsVecCandidates{ii};

                    M_ps = M_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのM_ps = zeros(27, 64)
                    c_ps = c_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのc_ps = zeros(27, 1)
                    cE_ps = cE_default{playerIndex, situationNumber+1}{1}; % 条件式

                    for i = 1:length(rightVec)
                        rightVec_i = newRightVecCandidate{i};
                        conditionExprVec_i = newConditionExprsVecCandidate{i};
                        rightVec_i_arr = children(rightVec_i);
                        for j = 1:length(rightVec_i_arr)
                            rightVec_i_arr_j = rightVec_i_arr(j);
                            rightVec_i_arr_j = rightVec_i_arr_j{1};
                            xpsIndexInFlattenx = find(x(:,playerIndex) == rightVec_i_arr_j);
                            if ~any(isletter(char(rightVec_i_arr_j)))  % 数値の場合
                                c_ps(i) = c_ps(i) + rightVec_i_arr_j;
                            else % 変数が含まれている場合
                                M_ps(i, xpsIndexInFlattenx) = 1;
                            end
                        end
                        cE_ps = simplify(and(cE_ps, conditionExprVec_i));
                    end

                    M{playerIndex, situationNumber+1}{ii} = M_ps;
                    c{playerIndex, situationNumber+1}{ii} = c_ps;
                    cE{playerIndex, situationNumber+1}{ii} = cE_ps;

                    L{playerIndex}{ii} = L_default{playerIndex}{1};
                    L{playerIndex}{ii}(situationNumber+1, :) = q.' * M_ps;

                    b{playerIndex}{ii} = b_default{playerIndex}{1};
                    b{playerIndex}{ii}(situationNumber+1) = q.' * c_ps;
                end
            end
        end
    end

    cE_set = {};
    for playerIndex = 1:6
        for situationNumber = 0:63
            if ismember(playerIndex, currentPlayerIndices) && (situationNumber == currentSituationNumber)
                for ii = 1:length(M{playerIndex, situationNumber+1})
                    cE_ps = cE{playerIndex, situationNumber+1}{ii};
                    % cE_setにcE_psが含まれていないなら、cE_setに追加
                    if ~ismember(cE_ps, cE_set)
                        cE_set{end+1} = cE_ps;
                    end
                end
            end
        end
    end

    % もしcE_setの長さが2以上であれば、symtrueを削除
    if length(cE_set) >= 2
        for cEIndex = 1:length(cE_set)
            cE_ps = cE_set{cEIndex};
            if isequal(cE_ps, symtrue)
                cE_set = cE_set([1:cEIndex-1, cEIndex+1:end]);
            end
        end
    end

    for cEIndex = 1:length(cE_set)
        cE_ps = cE_set{cEIndex};
        disp('-------------------');
        disp("条件式: ");
        disp(cE_ps);
        varNames = {};
        varValues = {};

        for playerIndex = 1:6
            for situationNumber = 0:63
                if ismember(playerIndex, currentPlayerIndices) && (situationNumber == currentSituationNumber)
                    ii = find(cE{playerIndex, situationNumber+1} == cE_ps);
                    if ~isempty(ii)

                        L_p = L{playerIndex}{ii}; % x_p = L_p * x_p + b_pのL_p = zeros(64, 64)
                        b_p = b{playerIndex}{ii}; % x_p = L_p * x_p + b_pのb_p = zeros(64, 1)

                        sol = (I - L_p) \ b_p;

                        varNames{end+1} = char(x(situationNumber + 1, playerIndex));
                        varValues{end+1} = sol(situationNumber + 1);
                    end
                end
            end
        end

        result = simplify(subs(cE_ps, varNames, varValues));
        if isequal(result, symtrue)
            disp("条件式は成立します");
            alreadySolvedVarNames = [alreadySolvedVarNames, varNames];
            alreadySolvedVarValues = [alreadySolvedVarValues, varValues];

            M_default = M;
            c_default = c;
            cE_default = cE;
            L_default = L;
            b_default = b;
        else
            disp("条件式は成立しません");
        end
    end
end

%% 4. 最後に、まだ計算されていない期待効用を計算する。条件分岐が依存している期待効用は1.〜3.で計算されているので、それらを利用する。
disp("残りの期待効用を計算します");

for playerIndex = 1:6

    L{playerIndex}{1} = L_default{playerIndex}{1};
    b{playerIndex}{1} = b_default{playerIndex}{1};

    for situationNumber = 0:63

        if (ismember(playerIndex, [1,3,5]) && (situationNumber == 2^(playerIndex-1))) || ...
            (ismember(playerIndex, [1,3]) && (situationNumber == 5)) || ...
            (ismember(playerIndex, [1,5]) && (situationNumber == 17)) || ...
            (ismember(playerIndex, [3,5]) && (situationNumber == 20))
            continue; % 既に計算済みのためスキップ
        end

        disp('-------------------');
        disp("playerIndex: " + playerIndex + ", situationNumber: " + situationNumber);

        rightVec = rightVecs{playerIndex, situationNumber+1};
        conditionsVec = conditionsVecs{playerIndex, situationNumber+1};

        newRightVec = {};
        newConditionExprsVec = {};

        for i = 1:length(rightVec)
            rightVec_i = simplify(subs(rightVec{i}, alreadySolvedVarNames, alreadySolvedVarValues));
            newRightVec_i = [];
            conditionsVec_i = conditionsVec{i};
            newConditionExprsVec_i = [];
            for j = 1:length(conditionsVec_i)
                condition = conditionsVec_i{j};
                if isempty(condition)
                    newRightVec_i = rightVec_i;
                    newConditionExprsVec_i = symtrue;
                    break;
                end

                newCondExpr = simplify(subs(condition.expr, alreadySolvedVarNames, alreadySolvedVarValues));

                if isequal(newCondExpr, symtrue)
                    newRightVec_i = simplify(subs(rightVec_i(j), alreadySolvedVarNames, alreadySolvedVarValues));
                    newConditionExprsVec_i = symtrue;
                    break;
                elseif isequal(newCondExpr, symfalse)
                    continue;
                else
                    error('条件式が成立するか否かが決定されていません。')
                end
            end

            newRightVec{end+1, 1} = newRightVec_i;
            newConditionExprsVec{end+1, 1} = newConditionExprsVec_i;
        end

        M_ps = M_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのM_ps = zeros(27, 64)
        c_ps = c_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのc_ps = zeros(27, 1)

        for i = 1:length(newRightVec)
            rightVec_i = newRightVec{i};
            conditionExprVec_i = newConditionExprsVec{i};
            rightVec_i_arr = children(rightVec_i);
            for j = 1:length(rightVec_i_arr)
                rightVec_i_arr_j = rightVec_i_arr(j);
                rightVec_i_arr_j = rightVec_i_arr_j{1};
                xpsIndexInFlattenx = find(x(:,playerIndex) == rightVec_i_arr_j);
                if ~any(isletter(char(rightVec_i_arr_j)))  % 数値の場合
                    c_ps(i) = c_ps(i) + rightVec_i_arr_j;
                else % 変数が含まれている場合
                    M_ps(i, xpsIndexInFlattenx) = 1;
                end
            end

            cE_ps = symtrue;
        end

        M{playerIndex, situationNumber+1}{1} = M_ps;
        c{playerIndex, situationNumber+1}{1} = c_ps;
        cE{playerIndex, situationNumber+1}{1} = cE_ps;

        L{playerIndex}{1}(situationNumber+1, :) = q.' * M_ps;

        b{playerIndex}{1}(situationNumber+1) = q.' * c_ps;
    end
end

for playerIndex = 1:6
    for situationNumber = 0:63
        if (ismember(playerIndex, [1,3,5]) && (situationNumber == 2^(playerIndex-1))) || ...
            (ismember(playerIndex, [1,3]) && (situationNumber == 5)) || ...
            (ismember(playerIndex, [1,5]) && (situationNumber == 17)) || ...
            (ismember(playerIndex, [3,5]) && (situationNumber == 20))
            continue; % 既に計算済みのためスキップ
        end

        disp('-------------------');
        disp("playerIndex: " + playerIndex + ", situationNumber: " + situationNumber);

        L_p = L{playerIndex}{1}; % x_p = L_p * x_p + b_pのL_p = zeros(64, 64)
        b_p = b{playerIndex}{1}; % x_p = L_p * x_p + b_pのb_p = zeros(64, 1)

        sol = (I - L_p) \ b_p;

        disp(char(x(situationNumber + 1, playerIndex)) + " = " + sol(situationNumber + 1));

        alreadySolvedVarNames = [alreadySolvedVarNames, char(x(situationNumber + 1, playerIndex))];
        alreadySolvedVarValues = [alreadySolvedVarValues, sol(situationNumber + 1)];
    end
end

%% 5. 期待効用計算結果を保存
vars = containers.Map();
for playerIndex = 1:6
    for situationNumber = 0:63
        x_ps_char = char(x(situationNumber + 1, playerIndex));
        idx = find(strcmp(alreadySolvedVarNames, x_ps_char));
        value = alreadySolvedVarValues{idx};
        vars(x_ps_char) = value;
    end
end
save('data/solution.mat', 'vars')

%% 6. 期待効用結果を表示
figure;  % figureを1つだけ作成
for situationNumber = 0:63
    % 各状況における各プレイヤの期待効用を、棒グラフで表示

    situation = Situation(situationNumber);

    playerNames = {};
    values = [];
    for playerIndex = 1:6
        x_ps_char = char(x(situationNumber + 1, playerIndex));
        % フォーマット変換: x_vi_3 -> x_{vi,3}, x_ps3_4 -> x_{ps3,4}
        x_ps_char = regexprep(x_ps_char, '_(\d+)_(\d+)$', '_{$1,$2}');
        playerNames{end+1} = regexprep(x_ps_char, '_([a-zA-Z0-9]+)_(\d+)$', '_{$1}');

        % 値の取得
        idx = find(strcmp(alreadySolvedVarNames, char(x(situationNumber + 1, playerIndex))));
        if situation.isPlayerPresent(playerIndex)
            value = alreadySolvedVarValues{idx};
        else
            value = 0;
        end
        values = [values, value];
    end

    % 8×8 のグリッドでサブプロットを作成
    subplot(8, 8, situationNumber + 1);
    bar(values);

    for k = 1:length(values)
        if values(k) == 0
            displayValue = "";
        else
            displayValue = num2str(values(k));
        end
        text(k, values(k) + 0.05 * max(values), displayValue, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 5);
    end

    presentPlayerNames = situation.getPresentPlayerNames();
    if isempty(presentPlayerNames)
        presentPlayerNames = "None";
    end
    title(situationNumber + ": " + presentPlayerNames);
    xticklabels(playerNames);
    xtickangle(0);
    ylim([min(cell2mat(alreadySolvedVarValues)) 1000+max(cell2mat(alreadySolvedVarValues))]);
end

%% 7. 決定された最適マッチングを表示
for playerIndex = 1:6
    for situationNumber = 0:63
        situation = Situation(situationNumber);

        if ~situation.isPlayerPresent(playerIndex)
            continue;
        end
        nextSituations = situation.createNextSituationsByOneStep();
        for i = 1:length(nextSituations)
            nextSituation = nextSituations(i);
            socialUtilities = allSocialExpectedUtilities{playerIndex, situationNumber+1, i};
            playerMatchings = allPlayerMatchings{playerIndex, situationNumber+1, i};

            [maxValue, maxIndex] = max(subs(socialUtilities, alreadySolvedVarNames, alreadySolvedVarValues));

            optimalPlayerMatching = playerMatchings(maxIndex);

            disp('-------------------');
            disp("playerIndex: " + playerIndex + ", situationNumber: " + situationNumber + ", nextSituationNumber: " + nextSituation.situationNumber);
            disp("Optimal Player Matching: ");
            disp(optimalPlayerMatching.toString());
            disp("Social Expected Utility: ");
            disp(maxValue);
        end
    end
end



% Lambda_p = zeros(length(x_vec));
% b_p = zeros(length(x_vec), 1);
% playerIndices = [1,3,5]; % v1, v2, v3
% for idx = 1:length(playerIndices)
%     playerIndex = playerIndices(idx);
%     situationNumber = 2^(playerIndex-1);
%     dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "rightVec");

%     rightVec = dataRightVec.rightVec; 

%     M_ps = zeros(27, 3); % 0-1行列
%     c_ps = zeros(27, 1); % 定数項ベクトル
%     for i = 1:size(M_ps, 1)
%         rightVec_i = rightVec{i};
%         rightVec_i_arr = children(rightVec_i);
%         for j = 1:length(rightVec_i_arr)
%             rightVec_i_arr_j = rightVec_i_arr(j);
%             rightVec_i_arr_j = rightVec_i_arr_j{1};
%             xpsIndexInFlattenx = find(x_vec == rightVec_i_arr_j);
%             if ~any(isletter(char(rightVec_i_arr_j)))  % 数値の場合
%                 c_ps(i) = c_ps(i) + rightVec_i_arr_j;
%             else % 変数が含まれている場合
%                 M_ps(i, xpsIndexInFlattenx) = 1;
%             end
%         end
%     end

%     Lambda_p(idx, :) = q.' * M_ps;
%     b_p(idx) = q.' * c_ps;
% end

% sol = (eye(3) - Lambda_p) \ b_p;

% for idx = 1:length(sol)
%     [row, col] = find(x == x_vec(idx));
%     x(row, col) = sol(idx);
% end

% % 次に、x_v1_5, x_v2_5を求める。これらは条件分岐があるので、条件分岐を考慮して期待効用を計算する。
% x_vec = [x(6,1); x(6,3)];



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


