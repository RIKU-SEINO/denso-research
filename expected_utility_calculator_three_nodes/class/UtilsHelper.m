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
end