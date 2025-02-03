classdef Condition
  properties
    expr; % symbolic: 条件式
  end

  methods
    function obj = Condition(expr)
      if nargin == 0
        obj.expr = [];
      else
        obj.expr = simplify(expr);
      end
    end

    function expr = getExpression(obj)
      expr = obj.expr;
    end

    function key = getKey(obj)
      key = char(obj.expr);
    end
  end

  methods
    function obj = combineAsAND(obj, condition)
      if isempty(obj.expr)
        obj.expr = condition.getExpression();
      else
        obj.expr = simplify(and(obj.expr, condition.getExpression()));
      end
    end

    function obj = combineAsOR(obj, condition)
      if isempty(obj.expr)
        obj.expr = condition.getExpression();
      else
        obj.expr = simplify(or(obj.expr, condition.getExpression()));
      end
    end
  end

  methods 
    function result = isIncluded(obj, conditions)
      result = false;
      for i = 1:length(conditions)
        if isequal(obj.expr, conditions{i}.getExpression())
          result = true;
          break;
        end
      end
    end

    function result = isIncluded2(obj, conditions)
      result = false;
      for i = 1:length(conditions)
        if isequal(obj.expr, conditions{i}.getExpression()) || isequal(simplify(or(obj.expr, conditions{i}.getExpression())), symtrue)
          result = true;
          break;
        end
      end
    end
  end


  methods (Static)
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
end