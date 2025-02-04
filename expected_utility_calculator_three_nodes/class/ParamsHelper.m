classdef ParamsHelper
  methods (Static)
    function [w, c, r_0, a, m, p, p_, u, r, q, d] = getSymbolicParams()
      % シンボリック変数の定義
      % syms w c positive
      % syms r_0 [3 1] positive
      % syms a [3 1] positive
      % syms m [3 1] positive
      % syms p [3 1] positive
      % syms p_ [3 3] positive
      w = 500;
      c = 100;
      r_0 = [1000; 4000; 2000];
      a = [10; 50; 20];
      m = [3; 1; 4];
      p = [0.8; 0.6; 0.1];
      p_ = [
        0, 0.2, 0.8;
        0.4, 0, 0.6;
        0.7, 0.3, 0;
      ];
      u = ParamsHelper.calculateTaxiUtilities(c, w);
      r = ParamsHelper.calculatePassengerUtilities(r_0, a);
      q = ParamsHelper.calculateTransitionProbabilityVector(p, p_);

      d = [
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

    function u = calculateTaxiUtilities(c,w)
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

    function r = calculatePassengerUtilities(r_0, a) 
      nodeNum = 3;
      r = zeros(nodeNum, nodeNum);
      for i = 1:nodeNum
        for j = 1:nodeNum
          r(i, j) = r_0(j) - abs(i - j) * a(j);
        end
      end
    end

    function transitionProbabilityVector = calculateTransitionProbabilityVector(p, p_)
      transitionProbabilityVector = zeros(27, 1);

      transitionProbabilityVector(1) = (1 - p(1)) * (1 - p(2)) * (1 - p(3));

      transitionProbabilityVector(2) = p(1)*p_(1, 2) * (1 - p(2)) * (1 - p(3));
      transitionProbabilityVector(3) = p(1)*p_(1, 3) * (1 - p(2)) * (1 - p(3));

      transitionProbabilityVector(4) = (1 - p(1)) * p(2)*p_(2, 1) * (1 - p(3));
      transitionProbabilityVector(5) = (1 - p(1)) * p(2)*p_(2, 3) * (1 - p(3));

      transitionProbabilityVector(6) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * (1 - p(3));
      transitionProbabilityVector(7) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * (1 - p(3));
      transitionProbabilityVector(8) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * (1 - p(3));
      transitionProbabilityVector(9) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * (1 - p(3));

      transitionProbabilityVector(10) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 1);
      transitionProbabilityVector(11) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 2);

      transitionProbabilityVector(12) = p(1)*p_(1, 2) * (1 - p(2)) * p(3)*p_(3, 1);
      transitionProbabilityVector(13) = p(1)*p_(1, 3) * (1 - p(2)) * p(3)*p_(3, 1);
      transitionProbabilityVector(14) = p(1)*p_(1, 2) * (1 - p(2)) * p(3)*p_(3, 2);
      transitionProbabilityVector(15) = p(1)*p_(1, 3) * (1 - p(2)) * p(3)*p_(3, 2);

      transitionProbabilityVector(16) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      transitionProbabilityVector(17) = (1 - p(1)) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      transitionProbabilityVector(18) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      transitionProbabilityVector(19) = (1 - p(1)) * p(2)*p_(2, 3) * p(3)*p_(3, 2);

      transitionProbabilityVector(20) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      transitionProbabilityVector(21) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      transitionProbabilityVector(22) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      transitionProbabilityVector(23) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      transitionProbabilityVector(24) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      transitionProbabilityVector(25) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      transitionProbabilityVector(26) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * p(3)*p_(3, 2);
      transitionProbabilityVector(27) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * p(3)*p_(3, 2);
    end
  end
end
