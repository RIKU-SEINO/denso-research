classdef TransitionHelper
  properties (Constant)
    % 乗客の出現組み合わせ行列（乗客の行き先は考慮しない）
    emergedPairsPassenger = [
      0, 0, 0, 0, 0, 0; %何も出現しない
      0, 1, 0, 0, 0, 0; %ps1のみ出現
      0, 0, 0, 1, 0, 0; %ps2のみ出現
      0, 1, 0, 1, 0, 0; %ps1とps2が出現
      0, 0, 0, 0, 0, 1; %ps3のみ出現
      0, 1, 0, 0, 0, 1; %ps1とps3が出現
      0, 0, 0, 1, 0, 1; %ps2とps3が出現
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現
    ].';

    % 乗客の出現組み合わせ行列（乗客の行き先も考慮している）
    emergedPairsPassengerWithDestionation = [
      0, 0, 0, 0, 0, 0; %何も出現しない
      0, 1, 0, 0, 0, 0; %ps1のみ出現(ps1はノード2に移動したい)
      0, 1, 0, 0, 0, 0; %ps1のみ出現(ps1はノード3に移動したい)
      0, 0, 0, 1, 0, 0; %ps2のみ出現(ps2はノード1に移動したい)
      0, 0, 0, 1, 0, 0; %ps2のみ出現(ps2はノード3に移動したい)
      0, 1, 0, 1, 0, 0; %ps1とps2が出現(ps1はノード2に、ps2はノード1に移動したい)
      0, 1, 0, 1, 0, 0; %ps1とps2が出現(ps1はノード3に、ps2はノード1に移動したい)
      0, 1, 0, 1, 0, 0; %ps1とps2が出現(ps1はノード2に、ps2はノード3に移動したい)
      0, 1, 0, 1, 0, 0; %ps1とps2が出現(ps1はノード3に、ps2はノード3に移動したい)
      0, 0, 0, 0, 0, 1; %ps3のみ出現(ps3はノード1に移動したい)
      0, 0, 0, 0, 0, 1; %ps3のみ出現(ps3はノード2に移動したい)
      0, 1, 0, 0, 0, 1; %ps1とps3が出現(ps1はノード2に、ps3はノード1に移動したい)
      0, 1, 0, 0, 0, 1; %ps1とps3が出現(ps1はノード3に、ps3はノード1に移動したい)
      0, 1, 0, 0, 0, 1; %ps1とps3が出現(ps1はノード2に、ps3はノード2に移動したい)
      0, 1, 0, 0, 0, 1; %ps1とps3が出現(ps1はノード3に、ps3はノード2に移動したい)
      0, 0, 0, 1, 0, 1; %ps2とps3が出現(ps2はノード1に、ps3はノード1に移動したい)
      0, 0, 0, 1, 0, 1; %ps2とps3が出現(ps2はノード3に、ps3はノード1に移動したい)
      0, 0, 0, 1, 0, 1; %ps2とps3が出現(ps2はノード1に、ps3はノード2に移動したい)
      0, 0, 0, 1, 0, 1; %ps2とps3が出現(ps2はノード3に、ps3はノード2に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード1に、ps3はノード1に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード1に、ps3はノード1に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード3に、ps3はノード1に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード3に、ps3はノード1に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード1に、ps3はノード2に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード1に、ps3はノード2に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード3に、ps3はノード2に移動したい)
      0, 1, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード3に、ps3はノード2に移動したい)
    ].';

    % 乗客の出現組み合わせ行列（乗客の行き先も考慮し、各要素が1以上の場合は、それは乗客の目的地のノード番号である）
    emergedPairsPassengerWithDestionationValued = [
      0, 0, 0, 0, 0, 0; %何も出現しない
      0, 2, 0, 0, 0, 0; %ps1のみ出現(ps1はノード2に移動したい)
      0, 3, 0, 0, 0, 0; %ps1のみ出現(ps1はノード3に移動したい)
      0, 0, 0, 1, 0, 0; %ps2のみ出現(ps2はノード1に移動したい)
      0, 0, 0, 3, 0, 0; %ps2のみ出現(ps2はノード3に移動したい)
      0, 2, 0, 1, 0, 0; %ps1とps2が出現(ps1はノード2に、ps2はノード1に移動したい)
      0, 3, 0, 1, 0, 0; %ps1とps2が出現(ps1はノード3に、ps2はノード1に移動したい)
      0, 2, 0, 3, 0, 0; %ps1とps2が出現(ps1はノード2に、ps2はノード3に移動したい)
      0, 3, 0, 3, 0, 0; %ps1とps2が出現(ps1はノード3に、ps2はノード3に移動したい)
      0, 0, 0, 0, 0, 1; %ps3のみ出現(ps3はノード1に移動したい)
      0, 0, 0, 0, 0, 2; %ps3のみ出現(ps3はノード2に移動したい)
      0, 2, 0, 0, 0, 1; %ps1とps3が出現(ps1はノード2に、ps3はノード1に移動したい)
      0, 3, 0, 0, 0, 1; %ps1とps3が出現(ps1はノード3に、ps3はノード1に移動したい)
      0, 2, 0, 0, 0, 2; %ps1とps3が出現(ps1はノード2に、ps3はノード2に移動したい)
      0, 3, 0, 0, 0, 2; %ps1とps3が出現(ps1はノード3に、ps3はノード2に移動したい)
      0, 0, 0, 1, 0, 1; %ps2とps3が出現(ps2はノード1に、ps3はノード1に移動したい)
      0, 0, 0, 3, 0, 1; %ps2とps3が出現(ps2はノード3に、ps3はノード1に移動したい)
      0, 0, 0, 1, 0, 2; %ps2とps3が出現(ps2はノード1に、ps3はノード2に移動したい)
      0, 0, 0, 3, 0, 2; %ps2とps3が出現(ps2はノード3に、ps3はノード2に移動したい)
      0, 2, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード1に、ps3はノード1に移動したい)
      0, 3, 0, 1, 0, 1; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード1に、ps3はノード1に移動したい)
      0, 2, 0, 3, 0, 1; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード3に、ps3はノード1に移動したい)
      0, 3, 0, 3, 0, 1; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード3に、ps3はノード1に移動したい)
      0, 2, 0, 1, 0, 2; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード1に、ps3はノード2に移動したい)
      0, 3, 0, 1, 0, 2; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード1に、ps3はノード2に移動したい)
      0, 2, 0, 3, 0, 2; %ps1とps2とps3が出現(ps1はノード2に、ps2はノード3に、ps3はノード2に移動したい)
      0, 3, 0, 3, 0, 2; %ps1とps2とps3が出現(ps1はノード3に、ps2はノード3に、ps3はノード2に移動したい)
    ].';

    % タクシーの出現組み合わせ行列
    emergedPairsTaxi = [
      0, 0, 0, 0, 0, 0; %何も出現しない
      1, 0, 0, 0, 0, 0; %v1のみ出現
      0, 0, 1, 0, 0, 0; %v2のみ出現
      1, 0, 1, 0, 0, 0; %v1とv2が出現
      0, 0, 0, 0, 1, 0; %v3のみ出現
      1, 0, 0, 0, 1, 0; %v1とv3が出現
      0, 0, 1, 0, 1, 0; %v2とv3が出現
      1, 0, 1, 0, 1, 0; %v1とv2とv3が出現
    ].';
  end

  % 遷移確率ベクトルを計算する
  methods (Static)
    function transitionProbabilityVector = calculateTransitionProbabilityVector(p_i, p_jk)

      TransitionHelper.validatePjk(p_i, p_jk);

      transitionProbabilityVector = zeros(27, 1);

      transitionProbabilityVector(1) = (1 - p_i(1)) * (1 - p_i(2)) * (1 - p_i(3));

      transitionProbabilityVector(2) = p_i(1)*p_jk(1, 2) * (1 - p_i(2)) * (1 - p_i(3));
      transitionProbabilityVector(3) = p_i(1)*p_jk(1, 3) * (1 - p_i(2)) * (1 - p_i(3));

      transitionProbabilityVector(4) = (1 - p_i(1)) * p_i(2)*p_jk(2, 1) * (1 - p_i(3));
      transitionProbabilityVector(5) = (1 - p_i(1)) * p_i(2)*p_jk(2, 3) * (1 - p_i(3));

      transitionProbabilityVector(6) = p_i(1)*p_jk(1, 2) * p_i(2)*p_jk(2, 1) * (1 - p_i(3));
      transitionProbabilityVector(7) = p_i(1)*p_jk(1, 3) * p_i(2)*p_jk(2, 1) * (1 - p_i(3));
      transitionProbabilityVector(8) = p_i(1)*p_jk(1, 2) * p_i(2)*p_jk(2, 3) * (1 - p_i(3));
      transitionProbabilityVector(9) = p_i(1)*p_jk(1, 3) * p_i(2)*p_jk(2, 3) * (1 - p_i(3));

      transitionProbabilityVector(10) = (1 - p_i(1)) * (1 - p_i(2)) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(11) = (1 - p_i(1)) * (1 - p_i(2)) * p_i(3)*p_jk(3, 2);

      transitionProbabilityVector(12) = p_i(1)*p_jk(1, 2) * (1 - p_i(2)) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(13) = p_i(1)*p_jk(1, 3) * (1 - p_i(2)) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(14) = p_i(1)*p_jk(1, 2) * (1 - p_i(2)) * p_i(3)*p_jk(3, 2);
      transitionProbabilityVector(15) = p_i(1)*p_jk(1, 3) * (1 - p_i(2)) * p_i(3)*p_jk(3, 2);

      transitionProbabilityVector(16) = (1 - p_i(1)) * p_i(2)*p_jk(2, 1) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(17) = (1 - p_i(1)) * p_i(2)*p_jk(2, 3) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(18) = (1 - p_i(1)) * p_i(2)*p_jk(2, 1) * p_i(3)*p_jk(3, 2);
      transitionProbabilityVector(19) = (1 - p_i(1)) * p_i(2)*p_jk(2, 3) * p_i(3)*p_jk(3, 2);

      transitionProbabilityVector(20) = p_i(1)*p_jk(1, 2) * p_i(2)*p_jk(2, 1) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(21) = p_i(1)*p_jk(1, 3) * p_i(2)*p_jk(2, 1) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(22) = p_i(1)*p_jk(1, 2) * p_i(2)*p_jk(2, 3) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(23) = p_i(1)*p_jk(1, 3) * p_i(2)*p_jk(2, 3) * p_i(3)*p_jk(3, 1);
      transitionProbabilityVector(24) = p_i(1)*p_jk(1, 2) * p_i(2)*p_jk(2, 1) * p_i(3)*p_jk(3, 2);
      transitionProbabilityVector(25) = p_i(1)*p_jk(1, 3) * p_i(2)*p_jk(2, 1) * p_i(3)*p_jk(3, 2);
      transitionProbabilityVector(26) = p_i(1)*p_jk(1, 2) * p_i(2)*p_jk(2, 3) * p_i(3)*p_jk(3, 2);
      transitionProbabilityVector(27) = p_i(1)*p_jk(1, 3) * p_i(2)*p_jk(2, 3) * p_i(3)*p_jk(3, 2);
    end
  end

  % p_iとp_jkのバリデーションを行う
  methods (Static)
    function validatePjk(p_i, p_jk)
      if length(p_i) ~= size(p_jk, 1)
        error('p_i must have the same length as the number of rows of p_jk');
      end

      if length(p_i) ~= size(p_jk, 2)
        error('p_i must have the same length as the number of columns of p_jk');
      end

      if any(p_i < 0) || any(p_i > 1)
        error('all elements of p_i must be between 0 and 1');
      end

      if any(any(p_jk < 0)) || any(any(p_jk > 1))
        error('all elements of p_jk must be between 0 and 1');
      end

      for j = 1:size(p_jk, 1)
        if p_jk(j, j) ~= 0
          error('p_jj must be a matrix with zeros on the diagonal');
        end
      end

      for j = 1:size(p_jk, 1)
        if sum(p_jk(j, :)) ~= 1
          error(fprintf('sum of row %d of p_jk must be 1', j));
        end
      end
    end
  end

  methods (Static)
    % グラフに必要なoriginsとdestinationsを全て取得する
    function [origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5] = getAllODPairs(transitions)
      origins1 = [];%プレイヤが出現する直前の状況番号
      origins2 = [];%プレイヤが出現した直後、マッチする前の状況番号
      origins3 = [];%origins1のうち、出現するプレイヤがタクシーである状況番号
      origins4 = [];%origins2のうち、異ノードマッチである状況番号
      origins5 = [];%セルフループ
      destinations1 = [];%プレイヤが出現した直後、マッチする前の状況番号
      destinations2 = [];%プレイヤが消滅した直後の状況番号
      destinations3 = [];%destinations1のうち、出現したプレイヤがタクシーである状況番号
      destinations4 = [];%destinations2のうち、異ノードマッチによってプレイヤが消滅した後の状況番号
      destinations5 = [];%セルフループ

      for i = 0:63
        for j = 0:63
          transition = transitions.transitionValuedCellArray{i+1, j+1};
          isTransitionable = transitions.transitionBinaryCellArray{i+1, j+1};
          emergedPlayerIndices = transition('emerged');
          disappearedPlayerIndices = transition('disappeared');
          if isempty(emergedPlayerIndices) && isempty(disappearedPlayerIndices) && isTransitionable
            origins5 = [origins5, i+1];%正の整数である必要があるため仕方なく+1
            destinations5 = [destinations5, j+1];%正の整数である必要があるため仕方なく+1
          elseif ~isempty(emergedPlayerIndices)
            origins1 = [origins1, i+1];%正の整数である必要があるため仕方なく+1
            destinations1 = [destinations1, j+1];%正の整数である必要があるため仕方なく+1
            % 状況番号の増加j-iが1, 4, 16, 5, 17, 20, 21のいずれかである場合、出現するプレイヤがタクシーである
            if ismember(j-i, [1, 4, 16, 5, 17, 20, 21])
              origins3 = [origins3, i+1];%正の整数である必要があるため仕方なく+1
              destinations3 = [destinations3, j+1];%正の整数である必要があるため仕方なく+1
            end
          elseif ~isempty(disappearedPlayerIndices)
            % origins2 = [origins2, i+1];%正の整数である必要があるため仕方なく+1
            % destinations2 = [destinations2, j+1];%正の整数である必要があるため仕方なく+1
            % % 状況番号の減少i-jが3, 12, 48, 15, 51, 60, 63のいずれでもない場合、異ノードマッチによってプレイヤが消滅した後の状況番号
            % if ~ismember(i-j, [3, 12, 48, 15, 51, 60, 63])
            %   % origins4 = [origins4, i+1];%正の整数である必要があるため仕方なく+1
            %   % destinations4 = [destinations4, j+1];%正の整数である必要があるため仕方なく+1
            % end
            % 状況番号の減少i-jが3, 12, 48, 15, 51, 60, 63のいずれでもない場合、異ノードマッチによってプレイヤが消滅した後の状況番号

            %ver2. v1, ps2が出現している状況から、v1, ps2が消滅している状況への遷移は起こり得ない。なぜかというと、v1, ps2という状況になっている段階で、v1とps2はマッチしないことを選択した過去があるため、その後においてもv1とps2がマッチすることはないからである。（By hayakawa）
            origins2 = [origins2, i+1];%正の整数である必要があるため仕方なく+1
            destinations2 = [destinations2, j+1];%正の整数である必要があるため仕方なく+1
          end
        end
      end
    end
  end

  % 状況遷移をネットワークとして可視化する
  methods (Static)
    function [h,G] = visualizeTransitionNetwork(origins1, origins2, origins3, origins4, destinations1, destinations2, destinations3, destinations4, origins5, destinations5)
      % ノードとエッジを統合
      allOrigins = [origins1, origins2, origins5];
      allDestinations = [destinations1, destinations2, destinations5];

      % ユニークなノードを取得
      uniqueNodes = unique([allOrigins, allDestinations]); % 全ノードを取得
      nodeLabels = arrayfun(@(x) sprintf('%d', x-1), uniqueNodes, 'UniformOutput', false); % ノードのラベルを生成

      % nodeLabelsに対して、その状況において出現しているプレイヤの情報を追加
      nodeLabels2 = cell(1, length(nodeLabels));
      for i = 1:length(nodeLabels)
        nodeNumber = str2num(nodeLabels{i});
         % situationHelperのconvertToPresencePairTextメソッドを使って、プレイヤの情報を取得
        nodeLabels2{i} = sprintf('%s: %s', nodeLabels{i}, SituationHelper.convertToPresencePairText(nodeNumber));
      end

      % ノード番号を新しいインデックスにマッピング
      nodeMapping = containers.Map(uniqueNodes, 1:length(uniqueNodes));
      mappedOrigins = arrayfun(@(x) nodeMapping(x), allOrigins);
      mappedDestinations = arrayfun(@(x) nodeMapping(x), allDestinations);

      % グラフを作成
      G = digraph(mappedOrigins, mappedDestinations);

      % グラフを描画
      figure;
      h = plot(G, 'Layout', 'layered', 'NodeLabel', nodeLabels2);
      title('状況遷移のグラフ');
      h.EdgeColor = 'blue';
      h.NodeColor = 'blue';

      % origins1: 乗客もしくはタクシーが出現
      % origins2: 同ノードマッチもしくは異ノードマッチ
      % origins3: タクシーが出現
      % origins4: 異ノードマッチ

      % タクシーの出現は赤色の実線エッジ
      highlightedOrigins = arrayfun(@(x) nodeMapping(x), origins3);
      highlightedDestinations = arrayfun(@(x) nodeMapping(x), destinations3);
      highlight(h, highlightedOrigins, highlightedDestinations, 'EdgeColor', 'red');

      % マッチは黒色の点線エッジ
      highlightedOrigins = arrayfun(@(x) nodeMapping(x), origins2);
      highlightedDestinations = arrayfun(@(x) nodeMapping(x), destinations2);
      highlight(h, highlightedOrigins, highlightedDestinations, 'LineStyle', ':', 'EdgeColor', 'black');

      % 遷移後、状況がまだ変わる場合は黒ノード
      highlightedOrigins = arrayfun(@(x) nodeMapping(x), [origins2, origins3]);
      highlight(h, highlightedOrigins, 'NodeColor', 'black');

      % セルフループは緑色の実線エッジ
      highlightedOrigins = arrayfun(@(x) nodeMapping(x), origins5);
      highlightedDestinations = arrayfun(@(x) nodeMapping(x), destinations5);
      highlight(h, highlightedOrigins, highlightedDestinations, 'EdgeColor', 'green', 'LineStyle', '-');
    end
  end
end