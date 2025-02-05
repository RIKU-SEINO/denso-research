classdef UtilsHelper
  methods (Static)
    % taxisとpassengersから可能なマッチングを全て生成
    function playerMatchings = generateMatchings(taxis, passengers)
      % taxisとpassengersから可能なマッチングを全て生成（重複排除）
      numPassengers = length(passengers);
      numTaxis = length(taxis);

      % 乗客の数がタクシーの数を超えていないか確認
      if numPassengers > numTaxis
          error('The number of passengers must be less than or equal to the number of taxis.');
      end

      % taxisの順列を生成
      taxiPerms = perms(taxis);

      % すべての可能なマッチングを格納するセル配列
      matchings = {};

      % 各順列に対してマッチングを生成
      for i = 1:size(taxiPerms, 1)
          % 現在の順列を取得
          currentPerm = taxiPerms(i, :);

          % 乗客とタクシーのマッチングを作成
          matching = cell(1, numTaxis);
          for j = 1:numPassengers
              matching{j} = {currentPerm(j), passengers(j)};
          end

          % 残りのタクシーを追加
          for j = numPassengers+1:numTaxis
              matching{j} = {currentPerm(j)};
          end

          matchings{end+1} = matching;
      end

      matchings = UtilsHelper.removeDuplicateMatchings(matchings);
      playerMatchings = [];
      for i = 1:length(matchings)
          matching_ = matchings{i};
          playerPairArray = [];
          for j = 1:length(matching_)
              playerPair = PlayerPair(matching_{j}{:});
              playerPairArray = [playerPairArray, playerPair];
          end

          playerMatching = PlayerMatching(playerPairArray);
          playerMatchings = [playerMatchings, playerMatching];
      end
    end

    % 重複を削除する関数
    function unique_matchings = removeDuplicateMatchings(matchings)
      matchings_str_keys = cell(1, length(matchings));
      for i = 1:length(matchings)
          matching = matchings{i};
          matching_str_key = '';
          for j = 1:length(matching)
              pair = matching{j};
              playerIndices = [];
              for k = 1:length(pair)
                  player = pair{k};
                  playerIndices = [playerIndices, player.playerIndex];
              end
              playerIndices = sort(playerIndices);
              pair_str = mat2str(playerIndices);
              matching_str_key = [matching_str_key, '-', pair_str];
          end

          % matching_str_keyを-で区切り、それをソートする。要素をソートするのではなく、要素の順番をソートする
          matching_str_key = strjoin(sort(strsplit(matching_str_key, '-')), '-');
          % 文字列に変換
          matchings_str_keys{i} = matching_str_key;
      end
      
      % 重複を削除
      [~, unique_indices] = unique(matchings_str_keys, 'stable');
      unique_matchings = matchings(unique_indices);
    end
  end

  methods (Static)
    % 指定された配列の中で最大となりうる候補はそのまま、それ以外の要素は[]にしたcell配列を返す
    % 注意したいのが、arrayとmaxCandidatesの長さは同じである。
    % ex. array = [
    %       x_v1_1 + 6180,
    %       6030,
    %       x_v1_1 + 6140,
    %       x_v3_16 + 6140,
    %       6250,
    %       x_v3_16 + 6400
    %    ]
    %    maxCandidates =   
    %     6x1 の cell 配列
    %       {[x_v1_1 + 6180 ]}
    %       {0x0 double      }
    %       {0x0 double      }
    %       {0x0 double      }
    %       {[6250          ]}
    %       {[x_v3_16 + 6400]}
    function maxCandidates = getMaxCandidates(array)
        numericValues = [];
        symbolicCandidates = {};

        % arrayを全てsymに変換
        array = sym(array);

        % 配列の中の要素を判定
        for i = 1:length(array)
            element = array(i);
            if ~any(isletter(char(element)))  % 数値と判定
                numericValues = [numericValues, double(element)];
            else
                symbolicCandidates{end+1} = element;  % シンボリック変数を格納
            end
        end

        if ~isempty(numericValues)
            maxNumericValue = max(numericValues);
        else
            maxNumericValue = [];
        end

        % 各要素の処理結果をそのままarrayに保持
        maxCandidates = cell(size(array));  % arrayと同じサイズの空のセル配列を作成
        blackList = [];
        for i = 1:length(array)
            element = array(i);
            if ~any(isletter(char(element)))  % 数値の場合
                if ~isempty(maxNumericValue) && element == maxNumericValue && ~ismember(i, blackList)
                    maxCandidates{i} = element;  % 数値の最大値ならそのまま残す
                else
                    blackList = [blackList, i];
                    maxCandidates{i} = [];  % それ以外は[]にする
                end
            else  % シンボリック変数の場合
                candidate = element;
                if ~isempty(maxNumericValue) && isAlways(candidate <= maxNumericValue)
                    blackList = [blackList, i];
                    maxCandidates{i} = [];  % numericValuesの最大値以下のsymbolic変数は削除
                elseif ~isempty(maxNumericValue) && isAlways(candidate > maxNumericValue)
                    maxCandidates{i} = candidate;  % numericValuesの最大値より大きい場合は残す
                    % maxNumericValueが格納されているcellを[]にする
                    for j = 1:length(array)
                        if isequal(array(j), sym(maxNumericValue))
                            blackList = [blackList, j];
                            maxCandidates{j} = [];
                            break;
                        end
                    end
                else
                    % 他のシンボリック変数との比較を行う
                    valid = true;
                    for j = 1:length(symbolicCandidates)
                        other = symbolicCandidates{j};
                        if isAlways(candidate < other)
                            valid = false;  % 他のsymbolic変数より小さい場合は削除
                            break;
                        % elseif isAlways(candidate >= other)
                        %     valid = false;  % 他のsymbolic変数より大きい場合は削除
                        %     break;
                        end
                    end
                    if valid && ~ismember(i, blackList)
                        maxCandidates{i} = candidate;  % 残す
                    else
                        blackList = [blackList, i];
                        maxCandidates{i} = [];  % 削除
                    end
                end
            end
        end

        % 候補がない場合は空にする
        if isempty(maxCandidates)
            maxCandidates = {};
        elseif length(maxCandidates) == 1
            maxCandidates = {maxCandidates{1}};
        end

        if length(maxCandidates) ~= length(array)
            maxCandidates
            array
            error('The length of maxCandidates must be the same as the length of array.');
        end
    end
  end

  methods (Static)
    % maxCandidates同士が同じであるか否かを返す
    function result = areCandidatesEqual(maxCandidates1, maxCandidates2)
        result = false;

        % maxCandidatesから0x0 doubleを削除
        maxCandidates1 = maxCandidates1(~cellfun('isempty', maxCandidates1));
        maxCandidates2 = maxCandidates2(~cellfun('isempty', maxCandidates2));

        if length(maxCandidates1) ~= length(maxCandidates2)
            return;
        end

        % maxCandidatesの要素を並び替えたものを全て出力
        maxCandidates1_permutations = perms(maxCandidates1);

        for i = 1:size(maxCandidates1_permutations, 1)
            maxCandidates1_permutation = maxCandidates1_permutations(i, :);
            
            isSame = true;
            
            initialDiff = maxCandidates1_permutation{1} - maxCandidates2{1};

            for j = 2:length(maxCandidates1_permutation)
                diff = maxCandidates1_permutation{j} - maxCandidates2{j};
                if ~isequal(diff, initialDiff)
                    isSame = false;
                    break;
                end
            end

            if isSame
                result = true;
                return;
            end
        end
    end

    % maxCandidates同士が同じであるか否かを返す
    function result = isCandidatesIncludedInOtherCandidates(maxCandidates1, maxCandidates2)
        result = false;

        % maxCandidatesから0x0 doubleを削除
        maxCandidates1 = maxCandidates1(~cellfun('isempty', maxCandidates1));
        maxCandidates2 = maxCandidates2(~cellfun('isempty', maxCandidates2));

        if length(maxCandidates1) > length(maxCandidates2)
            maxCandidatesShort = maxCandidates2;
            maxCandidatesLong = maxCandidates1;
            if length(maxCandidatesShort) == 1 % maxCandidatesShortの長さが1の場合、無条件でmaxCandidates1とmaxCandidates2が同じであるとみなされてしまうのが問題なので、この場合はfalseを返す
                return;
            end
        else
            maxCandidatesShort = maxCandidates1;
            maxCandidatesLong = maxCandidates2;
        end

        % maxCandidatesの要素を並び替えたものを全て出力
        maxCandidatesShort_permutations = perms(maxCandidatesShort);

        for i = 1:size(maxCandidatesShort_permutations, 1)
            maxCandidatesShort_permutation = maxCandidatesShort_permutations(i, :);
            
            isSame = true;
            
            initialDiff = maxCandidatesShort_permutation{1} - maxCandidatesLong{1};

            for j = 2:length(maxCandidatesShort_permutation)
                diff = maxCandidatesShort_permutation{j} - maxCandidatesLong{j};
                if ~isequal(diff, initialDiff)
                    isSame = false;
                    break;
                end
            end

            if isSame
                result = true;
                return;
            end
        end
    end

    % maxCandidatesの集合の中に、指定されたmaxCandidatesが含まれているか否かを返す
    function result = isIncluded(maxCandidates, maxCandidatesSet)
        result = false;

        for i = 1:length(maxCandidatesSet)
            if UtilsHelper.areCandidatesEqual(maxCandidates, maxCandidatesSet{i})
                result = true;
                return;
            end

            % if UtilsHelper.isCandidatesIncludedInOtherCandidates(maxCandidates, maxCandidatesSet{i})
            %     result = true;
            %     return;
            % end
        end
    end
  end

  % rightvecの条件分岐組み合わせに関するメソッド
  methods (Static)
    function [rightVecCandidates, conditionsVecCandidates] = getRightVecAndConditionsVecCandidates(rightVec, conditionsVec)
        % 入力セル配列を調べて、条件式をグループに分ける
        groups = {};  % グループごとの選択肢を格納するセル配列
        num_elements = [];
        
        for i = 1:length(conditionsVec)
            input = conditionsVec{i};
            % inputの長さが2以上かつinputがgroupsに含まれていない場合
            if length(input) >= 2 && ~any(cellfun(@(x) isequal(x, input), groups))
                groups{end+1} = input;
                num_elements = [num_elements, length(input)];
            end
        end

        % {[400    x_v2_4]}    {[900    x_v2_4]}    {[500    x_v2_4]}    {[x_v2_5    900    x_v2_4]}    {[x_v2_5    400    x_v2_4]}を受け取り、
        % 各要素の何番目のインデックスの要素を取得するかがバリエーションあるので、全て列挙
        % 例えば、[400    x_v2_4]の場合、1, 2の2通り
        % 例えば、[900    x_v2_4]の場合、1, 2の2通り
        % 例えば、[500    x_v2_4]の場合、1, 2の2通り
        % 例えば、[x_v2_5    900    x_v2_4]の場合、1, 2, 3の3通り
        % 例えば、[x_v2_5    400    x_v2_4]の場合、1, 2, 3の3通り
        % これを全て列挙すると、
        % 1, 1, 1, 1, 1
        % 2, 1, 1, 1, 1
        % 1, 2, 1, 1, 1
        % 2, 2, 1, 1, 1
        % 1, 1, 2, 1, 1
        % 2, 1, 2, 1, 1
        % 1, 2, 2, 1, 1
        % 2, 2, 2, 1, 1
        % 1, 1, 1, 2, 1
        % 2, 1, 1, 2, 1
        % 1, 2, 1, 2, 1
        % 2, 2, 1, 2, 1
        % 1, 1, 2, 2, 1
        % 2, 1, 2, 2, 1
        % 1, 2, 2, 2, 1
        % 2, 2, 2, 2, 1
        % 1, 1, 1, 3, 1
        % 2, 1, 1, 3, 1
        % ...
        % 2, 2, 2, 3, 3
        % までの組み合わせが生成される

        % 各配列のインデックスを作成
        index_arrays = arrayfun(@(x) 1:x, num_elements, 'UniformOutput', false);

        % インデックスの組み合わせを作成
        [combinations{1:length(num_elements)}] = ndgrid(index_arrays{:});

        % 組み合わせを一列に変換
        combinations = cell2mat(cellfun(@(x) x(:), combinations, 'UniformOutput', false));

        conditionsVecCandidates = {};
        rightVecCandidates = {};
        for i = 1:length(combinations)
            combination = combinations(i, :);
            conditionsVecCandidate = conditionsVec;
            rightVecCandidate = rightVec;

            for j = 1:length(conditionsVecCandidate)
                if length(conditionsVecCandidate{j}) >= 2
                    % conditionsVecCandidate{j}がgroupsの何番目にあるかidxとして取得
                    idx = find(cellfun(@(x) isequal(x, conditionsVecCandidate{j}), groups));
                    conditionsVecCandidate{j} = conditionsVecCandidate{j}(combination(idx));
                    rightVecCandidate{j} = rightVecCandidate{j}(combination(idx));
                end
            end

            conditionsVecCandidates{end+1} = conditionsVecCandidate;
            rightVecCandidates{end+1} = rightVecCandidate;
        end
    end      
  end
end