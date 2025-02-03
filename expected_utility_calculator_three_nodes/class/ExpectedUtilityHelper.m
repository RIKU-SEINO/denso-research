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


                        if false && isempty(elem{1})
                            fprintf(fileID, '%s\n', '[]');
                        else
                            % 各要素の 'expr' を取り出して、改行を手動で追加
                            exprStrings = string(elem);

                            % 改行を手動で追加
                            formattedElements(i) = "[" + join(exprStrings, ", ") + "]";
                        end
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
    end
end