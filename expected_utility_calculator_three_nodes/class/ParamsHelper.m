classdef ParamsHelper
  properties (Constant)
    w = 500; % タクシーが乗客を1ノード先に運ぶ際に得る報酬
    c = 100; % タクシーが乗客を1ノード先に運ぶ際にかかるコスト
    u = ParamsHelper.calculateTaxiUtilities(ParamsHelper.c, ParamsHelper.w); % タクシーが乗客を1ノード先に運ぶ際に得る利益

    r_0 = [1000, 4000, 2000]; % 乗客が待ち時間0でタクシーとマッチした時に得る効用
    alpha = [10, 50, 20]; % 乗客が1ステップ待つごとに失う効用
    m = [3, 1, 4]; % 乗客が出現してからタクシーが到着するまでの時間
    r = ParamsHelper.calculatePassengerUtilities(ParamsHelper.r_0, ParamsHelper.alpha); % 乗客がマッチした時に得る効用

    p_i = [0.8; 0.6; 0.1]; % 乗客が出現する確率
    p_jk = [
      0,   0.2, 0.8;
      0.4, 0,   0.6;
      0.7, 0.3, 0
    ]; % 出現した乗客がどのノードを目的地とするかの確率
    q = ParamsHelper.calculateTransitionProbabilityVector(ParamsHelper.p_i, ParamsHelper.p_jk); % 遷移確率ベクトル

    destinationNodesCandidates = [
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
  end

  methods (Static)
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

    % 乗客のマッチ効用テンソル
    % r(i,j): psjがviに乗車した際に得る利益
    % viがnステップ後に現れる場合、-n\alphaを忘れずに
    function r = calculatePassengerUtilities(r_0, alpha)
      nodeNum = 3;
      r = zeros(nodeNum, nodeNum);
      for i = 1:nodeNum
        for j = 1:nodeNum
          r(i, j) = r_0(j) - abs(i - j) * alpha(j);
        end
      end
    end
  end

  methods (Static)
    function transitionProbabilityVector = calculateTransitionProbabilityVector(p_i, p_jk)

      ParamsHelper.validatePjk(p_i, p_jk);

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
end