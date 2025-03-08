classdef ParamsHelper
  methods (Static)
    function [w, c, r_0, a, m, p, p_, u, r, q] = getSymbolicParams()
      % シンボリック変数の定義
      % syms w c positive
      % syms r_0 [3 1] positive
      % syms a [3 1] positive
      % syms m [3 1] positive
      % syms p [3 1] positive
      % syms p_ [3 3] positive
      % ノード1: 主要都市
      % ノード2: 副中心都市
      % ノード3: 田舎
      w = sym('w', 'positive');
      c = sym('c', 'positive');
      r_0 = sym('r_', [3, 1], 'positive');
      a = sym('a_', [3, 1], 'positive');
      m = sym('m_', [3, 1], 'positive');
      p = sym('p_', [3, 1], 'positive');
      p_ = sym('p_', [3, 3], 'positive');
      % r_0 = [3000; 2500; 1000];
      % a = [150; 50; 10];
      % m = [1; 2; 5];
      % p = [0.9; 0.7; 0.2];
      % p_ = [
      %   0, 1, 0; % 主要中心都市 -> 副中心都市: 1
      %   1, 0, 0; % 副中心都市 -> 主要中心都市: 1
      %   0.7, 0.3, 0; % 田舎 -> 主要中心都市: 0.7, 田舎 -> 副中心都市: 0.3
      % ];
      u = ParamsHelper.calculateTaxiUtilities(c, w);
      r = ParamsHelper.calculatePassengerUtilities(r_0, a);
      q = ParamsHelper.calculateTransitionProbabilityVector(p, p_);
    end

    function u = calculateTaxiUtilities(c,w)
      nodeNum = 3;
      u = sym(zeros(nodeNum, nodeNum, nodeNum));
      for i = 1:nodeNum
        for j = 1:nodeNum
          for k = 1:nodeNum
            u(i, j, k) = -c * (abs(i - j) + abs(j - k)) + w * abs(j - k);
          end
        end
      end
    end

    function r = calculatePassengerUtilities(r_0, a) 
      nodeNum = 3;
      r = sym(zeros(nodeNum, nodeNum));
      for i = 1:nodeNum
        for j = 1:nodeNum
          r(i, j) = r_0(j) - abs(i - j) * a(j);
        end
      end
    end

    function transitionProbabilityVector = calculateTransitionProbabilityVector(p, p_)
      transitionProbabilityVector = sym(zeros(27, 1));

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
