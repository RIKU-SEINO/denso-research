classdef ParamsHelper
  methods (Static)
    function [w, c, r_0, a, p, p_, u, r, q] = getSymbolicParams()
      persistent cached_params;
      if ~isempty(cached_params)
        [w, c, r_0, a, p, p_, u, r, q] = cached_params{:};
        return;
      end
      w = sym('w', 'positive');
      % w = 2000;
      c = sym('c', 'positive');
      assume(c < w/2);
      % c = 100;
      % r_0 = sym('r_', [3, 1], 'positive');
      syms r_2 'real' 'positive';
      syms r_3 'real' 'positive';
      r_0 = [0; r_2; r_3];
      % r_0 = [0; 1500; 1500];
      % a = sym('a_', [3, 1], 'positive');
      syms a_2 'real' 'positive';
      syms a_3 'real' 'positive';
      a = [0; a_2; a_3];
      assume(a_2 < r_2);
      assume(a_3 < r_3);
      % a = [0; 50; 50];
      % p = sym('p_', [3, 1], 'positive');
      syms p_21 'real' 'positive';
      syms p_31 'real' 'positive';
      p = [0; p_21; p_31];
      assume(p_21 <= 1);
      assume(p_31 <= 1);
      % p = [0; 0.5; 0.5];
      % p_ = sym('p_', [3, 3], 'positive');
      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];
      u = ParamsHelper.calculateTaxiUtilities(c, w);
      r = ParamsHelper.calculatePassengerUtilities(r_0, a);
      q = ParamsHelper.calculateTransitionProbabilityVector(p, p_);
      cached_params = {w, c, r_0, a, p, p_, u, r, q};
    end

    function u = calculateTaxiUtilities(c, w)
      [i, j, k] = ndgrid(1:3, 1:3, 1:3);
      u = -c * (abs(i - j) + abs(j - k)) + w * abs(j - k);
      u = sym(u);  % シンボリック変数に変換
    end
  
    function r = calculatePassengerUtilities(r_0, a) 
      [i, j] = ndgrid(1:3, 1:3);
      r = r_0(j) - a(j) * abs(i - j);
      r = sym(r);  % シンボリック変数に変換
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
