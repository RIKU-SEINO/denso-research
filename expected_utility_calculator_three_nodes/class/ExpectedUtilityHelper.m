classdef ExpectedUtilityHelper
    methods (Static)
        function mat = generateExpectedUtilitiesSymbolicMatrix() 
            players = {'v1', 'ps1', 'v2', 'ps2', 'v3', 'ps3'};
            mat = sym(zeros(64, 6));
            for s = 1:64
                for playerIndex = 1:6
                    % 動的にシンボリック変数名を作成
                    varName = sprintf('x_%s_%d', players{playerIndex}, s-1);
                    
                    % 配列にシンボリック変数を格納
                    mat(s, playerIndex) = sym(varName);
                    assume(mat(s, playerIndex), 'real');
                    if playerIndex == 1 || playerIndex == 3 || playerIndex == 5
                        assume(mat(s, playerIndex), 'positive');
                    end
                end
            end
        end
    end

    methods (Static)
        function saveExpectedUtilityMaterials(x)
            allConditions = {};
            for playerIndex = 1:size(x,2)
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
        end
    end

    methods (Static)
        % 各期待効用の右辺ベクトルを/data/right_vec/rightVec_*.matから読み込み、その全部のデータをテキストファイルに出力する
        function writeRightVecs(outputPath)
            % 出力ファイルを開く（書き込みモード）
            fileID = fopen(outputPath, 'w');

            for playerIndex = 1:6
                for s = 0:63
                    data = load("data/right_vec/rightVec_" + string(playerIndex) + "_" + string(s) + ".mat", "rightVec");
                    fprintf(fileID, '------\n');
                    fprintf(fileID, "rightVec_%s_%d\n", string(playerIndex), s); % ファイル名をファイルに書き込む
                    disp("rightVec_" + string(playerIndex) + "_" + string(s)+"を書き込み中");
                    rightVec = data.rightVec;
                    formattedElements = strings(1, length(rightVec)); % 結果格納用

                    for i = 1:length(rightVec)
                        elem = rightVec{i};

                        % 各要素の 'expr' を取り出して、改行を手動で追加
                        exprStrings = string(elem);

                        % 改行を手動で追加
                        formattedElements(i) = "[" + join(exprStrings, ", ") + "]";
                    end

                    fprintf(fileID, "{\n");
                    for k = 1:length(formattedElements)
                        % 各要素を改行でファイルに書き込む
                        fprintf(fileID, '%s\n', formattedElements(k));
                    end
                    fprintf(fileID, "}\n");
                end
            end

            % ファイルを閉じる
            fclose(fileID);

            disp(['結果がファイルに保存されました: ', outputPath]);
        end

        % 各期待効用の変数を計算する上で必要になる条件式を/data/conditions_vec/conditionsVec_*.matから読み込み、その全部のデータをテキストファイルに出力する
        function writeConditions(outputPath)

            % 出力ファイルを開く（書き込みモード）
            fileID = fopen(outputPath, 'w');
    
            for playerIndex = 1:6
                for s = 0:63
                    data = load("data/conditions_vec/conditionsVec_" + string(playerIndex) + "_" + string(s) + ".mat", "conditionsVec");
                    fprintf(fileID, '------\n');
                    fprintf(fileID, "conditionsVec_%s_%d\n", string(playerIndex), s); % ファイル名をファイルに書き込む
                    disp("conditionsVec_" + string(playerIndex) + "_" + string(s)+"を書き込み中");
    
                    if iscell(data.conditionsVec) % セル配列か確認
                        formattedElements = strings(1, length(data.conditionsVec)); % 結果格納用
                        
                        for i = 1:length(data.conditionsVec)
                            elem = data.conditionsVec{i};
                            
                            if isempty(elem{1})
                                fprintf(fileID, '%s\n', '[]');
                            else
                                % 各要素の 'expr' を取り出して、改行を手動で追加
                                exprStrings = [];
                                for j = 1:length(elem)
                                    exprStrings = [exprStrings, string(elem{j}.expr)]; % 'expr'を結合
                                end
                                
                                % 改行を手動で追加
                                formattedElements(i) = "[" + join(exprStrings, ", ") + "]";
                            end
                        end
    
                        % 整形した要素がある場合のみ、{} で囲んでファイルに書き込む
                        nonEmptyElements = formattedElements(formattedElements ~= "");
                        if ~isempty(nonEmptyElements)
                            fprintf(fileID, "{\n");
                            for k = 1:length(nonEmptyElements)
                                % 各要素を改行でファイルに書き込む
                                fprintf(fileID, '%s\n', nonEmptyElements(k));
                            end
                            fprintf(fileID, "}\n");
                        end
                    else
                        % 'cell'型ではない場合、そのまま文字列として書き込む
                        fprintf(fileID, '%s\n', string(data.conditionsVec)); % セルでない場合そのままファイルに書き込む
                    end
                end
            end
    
            % ファイルを閉じる
            fclose(fileID);
    
            disp(['結果がファイルに保存されました: ', outputPath]);
        end

        function writeAllConditions(outputPath)
            data = load("data/allConditions.mat", "allConditions");
            allConditions = data.allConditions;
      
            % 出力ファイルを開く（書き込みモード）
            fileID = fopen(outputPath, 'w');
      
            for i = 1:length(allConditions)
              fprintf(fileID, '%s\n', char(allConditions{i}.getExpression()));
            end
      
            % ファイルを閉じる
            fclose(fileID);
      
            disp(['結果がファイルに保存されました: ', outputPath]);
        end        
    end

    methods (Static)
        % 期待効用の方程式を構成する要素を定義する
        function [I, L, b, M, c, cE] = generateEquationElements(x)
            I = eye(length(x));
            L = {};
            b = {};
            M = {};
            c = {};
            cE = {};

            for playerIndex = 1:6
                L{playerIndex} = {}; % playerIndexを決めても条件分岐により複数のLが存在する場合があるので、cell配列にする
                L{playerIndex}{1} = zeros(length(x)); % 0-1行列
            
                b{playerIndex} = {}; % playerIndexを決めても条件分岐により複数のbが存在する場合があるので、cell配列にする
                b{playerIndex}{1} = zeros(length(x), 1); % 定数項ベクトル
            
                for situationNumber = 0:63
                    M{playerIndex, situationNumber+1} = {}; % playerIndex, situationNumberを決めても条件分岐により複数のMが存在する場合があるので、cell配列にする
                    M{playerIndex, situationNumber+1}{1} = zeros(27, length(x)); % 0-1行列
            
                    c{playerIndex, situationNumber+1} = {}; % playerIndex, situationNumberを決めても条件分岐により複数のcが存在する場合があるので、cell配列にする
                    c{playerIndex, situationNumber+1}{1} = zeros(27, 1); % 定数項ベクトル
            
                    cE{playerIndex, situationNumber+1} = {}; % playerIndex, situationNumberを決める際に、条件分岐により複数のcEが存在する場合があるので、cell配列にする
                    cE{playerIndex, situationNumber+1}{1} = symtrue; % 条件式
                end
            end
        end
    end
end