clear;

addpath('./class');

%% Parameter Settings

% viがpsjを1つ運ぶ際に得る報酬
w = 500; % タクシーが乗客を1ノード先に運ぶ際に得る報酬
c = 10; % タクシーが乗客を1ノード先に運ぶ際にかかるコスト
u = calculateTaxiUtilities(c, w);

% 乗客がマッチした時に得る効用
r_0 = [1000, 1500, 1000]; % 乗客が待ち時間0でタクシーとマッチした時に得る効用
alpha = [50, 100, 50]; % 乗客が単位時間で低減する効用
m = [1, 5, 2]; % 乗客が出現してからタクシーが到着するまでの時間
r = calculatePassengerUtilities(r_0, alpha, m);

% 遷移確率ベクトル
p_i = [0.8; 0.6; 0.1]; % 乗客が出現する確率
p_jk = [
  0,   0.2, 0.8;
  0.4, 0,   0.6;
  0.7, 0.3, 0
]; % 出現した乗客がどのノードを目的地とするかの確率
q = TransitionHelper.calculateTransitionProbabilityVector(p_i, p_jk);

% 64通りの状況について、全てのプレイヤの期待効用ベクトルをsymbolic変数として定義
playerNames = {'v1', 'ps1', 'v2', 'ps2', 'v3', 'ps3'};
s_range = 0:63;
for i = 1:length(playerNames)
    for j = s_range
        x.([playerNames{i} '_' num2str(j)]) = sym([playerNames{i} '_' num2str(j)]);
    end
end


% 64通りの状況について、次のステップ
situationNumber = 6;
% ps1(=playerIndex=2)のみ出現
currentSituation = Situation(situationNumber);
appearedPlayerIndices = [2]; % appearedPlayerIndicesの各要素とappearedPlayerDestinationNodesの各要素は対応している
appearedPlayerDestinationNodes = [3]; % appearedPlayerIndicesの各要素とappearedPlayerDestinationNodesの各要素は対応している
disappearedPlayerIndices = [];
destinationNodes = zeros(6, 1);
for i = 1:length(appearedPlayerIndices)
    appearedPlayerIndex = appearedPlayerIndices(i);
    destinationNodes(appearedPlayerIndex) = appearedPlayerDestinationNodes(i);
end
nextSituation = currentSituation.createNextSituation(appearedPlayerIndices, disappearedPlayerIndices, destinationNodes);
[taxis, passengers] = nextSituation.getMatchablePlayers(m);
playerMatchings = generateMatchings(taxis, passengers);




%% Helper Functions

% タクシーのマッチ効用テンソル
% u(i,j,k): viがpsjをkに運ぶ際に得る利益
function u = calculateTaxiUtilities(c, w)
  nodeNum = 3;
  u = zeros(nodeNum, nodeNum, nodeNum);
  for i = 1:nodeNum
    for j = 1:nodeNum
      for k = 1:nodeNum
        u(i, j, k) = -c * abs(i - j) + w * abs(j - k);
      end
    end
  end
end

% 乗客のマッチ効用行列
% r(i,j): psjがm_jステップ待機した後にviに乗車した際に得る利益
% jが決まればm_jも決まるので、乗客の待機時間は引数に含めない
function r = calculatePassengerUtilities(r_0, alpha, m)
  nodeNum = 3;
  r = zeros(nodeNum, nodeNum, nodeNum);
  for i = 1:nodeNum
    for j = 1:nodeNum
      r(i, j) = r_0(j) - abs(i - j) * alpha(j) - m(j) * alpha(j);
    end
  end
end

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

  matchings = removeDuplicateMatchings(matchings);
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

