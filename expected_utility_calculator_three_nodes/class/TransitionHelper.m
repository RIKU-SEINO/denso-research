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
end