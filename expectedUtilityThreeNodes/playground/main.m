addpath(genpath('./classes'));
addpath(genpath('./data'));

% 乗客の出現確率ベクトル
p_i = [0.8; 0.6; 0.1];

% 遷移確率行列
p_jk = [
  0,   0.2, 0.8;
  0.4, 0,   0.6;
  0.7, 0.3, 0
];

% 遷移確率ベクトルを計算
transitionProbabilityVector = TransitionHelper.calculateTransitionProbabilityVector(p_i, p_jk);

situation = Situation(0, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_0, G_0] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(1, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_1, G_1] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(4, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_4, G_4] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(5, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_5, G_5] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(16, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_16, G_16] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(17, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_17, G_17] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(20, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_20, G_20] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(21, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_21, G_21] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);

situation = Situation(37, "situationNumber");
[allSituations, transitions] = situation.enumerateAllSituations2();
[origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
[h_37, G_37] = TransitionHelper.visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5);


% 連想配列の初期化 次のような構造
% {
%  1: {
%    origins1: [1, 2, 3, 4],
%    origins2: [1, 2, 3, 4],
%    origins3: [1, 2, 3, 4],
%    origins4: [1, 2, 3, 4],
%    destinations1: [1, 2, 3, 4],
%    destinations2: [1, 2, 3, 4],
%    destinations3: [1, 2, 3, 4],
%    destinations4: [1, 2, 3, 4]
%  },
%  2: {
% ...
%  },
allSituationNumbersArray = {};
for i = 0:63
  disp("i: " + i);
  situation = Situation(i, "situationNumber");
  [allSituations, transitions] = situation.enumerateAllSituations2();
  [origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = TransitionHelper.getAllODPairs(transitions);
  allSituationNumbers = sort(unique([origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5]));
  allSituationNumbersArray{i + 1} = allSituationNumbers;
end

% ステップ 1: グループ分けとsituationNumberごとの可視化
groups = {}; % groups{i}は、到達可能状況範囲がgroups2{i}である起点状況番号群
groups2 = {}; % groups2{i}はグループiの到達可能状況範囲
for idx = 1:numel(allSituationNumbersArray)
    situationList = allSituationNumbersArray{idx}; % 現在のallSituationsを取得
    matched = false;
    for g = 1:numel(groups)
        if isequal(situationList, groups2{g}) % 同一の内容が既存のグループにあるか確認
            matched = true;
            break;
        end
    end
    if ~matched
        groups{end+1} = [idx-1];
        groups2{end+1} = situationList;
    else
        groups{g} = [groups{g}, idx-1];
    end
end

% 10種類のRGBカラーを生成
colors = {'r', 'g', 'b', 'c', 'm', "#7E2F8E", "#EDB120", 'k'};
G = {G_0, G_1, G_4, G_5, G_16, G_17, G_20, G_21};
hh = {h_0, h_1, h_4, h_5, h_16, h_17, h_20, h_21};
% 各Gに対して、G_21から処理を行う
% 1. G_21のノードを取得し、そのノードをcolorに従って色付けする
% 2. G_21のエッジを取得し、そのエッジをcolorとwidthに従って色付けする
% 3. 1, 2を繰り返し、G_0, G_1, G_4, G_5, G_16, G_17, G_20に対しても同様の処理を行う
for i = 1:numel(G)
    g = G{end-i+1};
    hhh = hh{end-i+1};
    color = colors{end-i+1};
    edges = g.Edges.EndNodes;
    nodeIndex = unique(edges(:));
    nodeLabels = hhh.NodeLabel;
    nodeNums = [];
    for j = 1:numel(nodeLabels)
        str = nodeLabels{j};
        splitStr = split(str, ': ');
        nodeNums = [nodeNums, 1+str2double(splitStr{1})];
    end
    nodeMapping = containers.Map(nodeIndex, nodeNums);
    mappedEdges = cell2mat(cellfun(@(x) nodeMapping(x), num2cell(edges), 'UniformOutput', false));
    mappedNodes = cell2mat(cellfun(@(x) nodeMapping(x), num2cell(nodeIndex), 'UniformOutput', false));

    figure;
    h_new = plot(G_21, 'Layout', 'layered', 'NodeLabel', h_21.NodeLabel);
    h_new.NodeColor = 'k';
    h_new.LineWidth = 1;
    h_new.EdgeColor = 'k';
    highlight(h_new, mappedNodes, 'NodeColor', color);
    highlight(h_new, mappedEdges(:,1), mappedEdges(:,2), 'EdgeColor', color, 'LineWidth', 4);
    hold off;
end


% for situationNumber = 0:63
%   situation = Situation(situationNumber, "situationNumber");

%   SituationHelper.displayAndSaveExpectedUtilityRecurrenceEquations(situation);
% end

% 1. テキストファイルを読み込む
filename = './data/RecurrenceEquations_1.txt'; % ファイル名
fileContent = fileread(filename); % ファイル内容を読み込み

% 正規表現で x と u を抽出
x_matches = regexp(fileContent, 'x_(ps|v)(\d)_(\d+)', 'match');
u_matches = regexp(fileContent, 'u_\d+_\d+_\d+', 'match');

% x と u を一意にする
x_list = unique(x_matches);
u_list = unique(u_matches);

% x_listとu_listをcustom_sort関数を使ってソート
sorted_x_list = sortX(x_list);
sorted_u_list = sortU(u_list);

% ベクトルの初期化 (すべての値を 0 に設定)
vec_x = zeros(1, length(sorted_x_list));
vec_u = zeros(1, length(sorted_u_list));

% 結果を表示
disp('xベクトルの要素:');
disp(sorted_x_list);
disp('初期化された vec_x:');
disp(vec_x);

disp('uベクトルの要素:');
disp(sorted_u_list);
disp('初期化された vec_u:');
disp(vec_u);

% 2. テキストファイルで、---で区切られた部分ごとに漸化式を設計
% x = Px + Ru, Pの行列サイズはxの要素数と同じ, Qの列ベクトルサイズはxの要素数と同じ




% ソート関数
function sorted_vars = sortX(vars)
  % 並べ替えの基準
  prefix_order = {'v1', 'v2', 'v3', 'ps1', 'ps2', 'ps3'};

  % プレフィックスと番号を抽出
  tokens = regexp(vars, 'x_(\w+)_(\d+)', 'tokens'); % 各変数からプレフィックスと番号を抽出

  % 空でないトークンをフィルタリング
  valid_indices = ~cellfun(@isempty, tokens); % 有効なトークンのインデックス
  valid_tokens = tokens(valid_indices); % 有効なトークンだけ取得
  valid_vars = vars(valid_indices); % 対応する変数もフィルタリング

  prefixes = cellfun(@(x) x{1}{1}, valid_tokens, 'UniformOutput', false); % プレフィックス部分を取得
  numbers = cellfun(@(x) str2double(x{1}{2}), valid_tokens); % 番号部分を取得

  % プレフィックスに対応する順序を計算
  [~, prefix_indices] = ismember(prefixes, prefix_order);

  % ソートの基準を作成
  sort_matrix = [prefix_indices(:), numbers(:)]; % プレフィックスの順序と番号を結合
  [~, sort_order] = sortrows(sort_matrix); % ソート順を取得

  % 並べ替え
  sorted_vars = valid_vars(sort_order);
end

function sorted_vars = sortU(vars)
  % 正規表現で `u_i_j_k` の形式を分解
  tokens = regexp(vars, 'u_(\d+)_(\d+)_(\d+)', 'tokens'); % i, j, k を抽出

  % 空でないトークンをフィルタリング
  valid_indices = ~cellfun(@isempty, tokens); % 有効なトークンのインデックス
  valid_tokens = tokens(valid_indices); % 有効なトークンのみ取得
  valid_vars = vars(valid_indices); % 対応する変数もフィルタリング

  % i, j, k をそれぞれ抽出して数値化
  i_vals = cellfun(@(x) str2double(x{1}{1}), valid_tokens);
  j_vals = cellfun(@(x) str2double(x{1}{2}), valid_tokens);
  k_vals = cellfun(@(x) str2double(x{1}{3}), valid_tokens);

  % ソートの基準を作成
  sort_matrix = [i_vals(:), j_vals(:), k_vals(:)]; % i, j, k を結合
  [~, sort_order] = sortrows(sort_matrix); % ソート順を取得

  % 並べ替え
  sorted_vars = valid_vars(sort_order);
end
