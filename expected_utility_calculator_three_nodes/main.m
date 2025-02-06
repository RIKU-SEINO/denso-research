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
%% 1. まず、方程式を構成する要素を定義する
[I, L, b, M, c, cE] = ExpectedUtilityHelper.generateEquationElements(x);
L_default = L;
b_default = b;
M_default = M;
c_default = c;

alreadySolvedVarNames = {};
alreadySolvedVarValues = {};

%% 2. 次に、x_v1_1, x_v2_4, x_v3_16について期待効用を計算。条件分岐がないので簡単に求められる。
for playerIndex = 1:6

    L_p = L_default{playerIndex}{1}; % x_p = L_p * x_p + b_pのL_p = zeros(64, 64)
    b_p = b_default{playerIndex}{1}; % x_p = L_p * x_p + b_pのb_p = zeros(64, 1)

    for situationNumber = 0:63

        M_ps = M_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのM_ps = zeros(27, 64)
        c_ps = c_default{playerIndex, situationNumber+1}{1}; % x_ps = M_ps * x + c_psのc_ps = zeros(27, 1)

        if ismember(playerIndex, [1,3,5]) && (situationNumber == 2^(playerIndex-1))

            dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "rightVec");
            rightVec = dataRightVec.rightVec;

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
                dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "rightVec");
                dataConditionsVec = load("data/conditions_vec/conditionsVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "conditionsVec");
                rightVec = dataRightVec.rightVec;
                conditionsVec = dataConditionsVec.conditionsVec;

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

        dataRightVec = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "rightVec");
        dataConditionsVec = load("data/conditions_vec/conditionsVec_" + string(playerIndex) + "_" + string(situationNumber) + ".mat", "conditionsVec");

        rightVec = dataRightVec.rightVec;
        conditionsVec = dataConditionsVec.conditionsVec;

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

%% 5. 結果を保存
vars = containers.Map();
for playerIndex = 1:6
    for situationNumber = 0:63
        x_ps_char = char(x(situationNumber + 1, playerIndex));
        idx = find(strcmp(alreadySolvedVarNames, x_ps_char));
        value = alreadySolvedVarValues{idx};
        vars(x_ps_char) = value;
    end
end
save('data/sol/solution.mat', 'vars')

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


