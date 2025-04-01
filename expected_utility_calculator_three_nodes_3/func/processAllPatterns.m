function processAllPatterns(processFunction)
  %   すべてのプレイヤ集合のマッチング組み合わせに対して処理を実行する
  %
  %
  %   Paramters:
  %       processFunction - 関数ハンドル。各マッチング組み合わせに適用される処理関数。
  %                         関数の引数として、選択されたマッチングの組み合わせ (cell 配列) を受け取る必要がある。
  %
  %   説明:
  %       この関数は、達成可能なすべてのプレイヤ集合を取得し、それぞれのプレイヤ集合で考えられるマッチングの候補を列挙する。
  %       すべてのプレイヤ集合におけるマッチングの組み合わせを生成し、それぞれに対して指定された processFunction を適用する。
  %
  %   例:
  %       % 例1: 各マッチングの組み合わせを表示
  %       processAllPlayerMatchingPatterns(@(match) disp(match));
  %
  %       % 例2: 各マッチングの組み合わせに対してカスタム処理を実行
  %       processAllPlayerMatchingPatterns(@(match) fprintf('Processing matching: %s\n', strjoin(match, ', ')));
  %
  %
  %   具体例:
  %       例えば、プレイヤ集合 P = {P1, P2, P3, P4} があり、各プレイヤ集合ごとに以下のマッチング候補がある場合:
  %           P1 のマッチング候補: {M_{P1,1}, M_{P1,2}}
  %           P2 のマッチング候補: {M_{P2,1}, M_{P2,2}, M_{P2,3}}
  %           P3 のマッチング候補: {M_{P3,1}, M_{P3,2}}
  %           P4 のマッチング候補: {M_{P4,1}}
  %       これらの組み合わせの総数は 2 * 3 * 2 * 1 = 12 通りあり、それぞれについて processFunction が適用される。

  all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
  num_sets = length(all_possible_player_sets);
  matching_options = cell(1, num_sets);

  % 各プレイヤ集合のマッチング候補を取得
  for i = 1:num_sets
    matching_options{i} = all_possible_player_sets{i}.get_all_possible_player_matchings();
  end

  % すべてのマッチングの組み合わせを処理
  indices = arrayfun(@(i) 1:length(matching_options{i}), 1:num_sets, 'UniformOutput', false);
  [grid{1:num_sets}] = ndgrid(indices{:});
  combination_indices = cell2mat(cellfun(@(x) x(:), grid, 'UniformOutput', false));
  
  for k = 1:size(combination_indices, 1)
    player_matchings = cell(num_sets, 1);
    for j = 1:num_sets
        player_matching = matching_options{j}{combination_indices(k, j)};
        player_matchings{j} = player_matching;
    end
    pattern = Pattern(player_matchings);
    processFunction(pattern);
  end
end