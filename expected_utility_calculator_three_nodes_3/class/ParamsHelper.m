classdef ParamsHelper
  methods (Static)
    function [w, c, r, a, p, p_, u_v, u_ps, q] = get_symbolic_params()
      persistent cached_params;
      if ~isempty(cached_params)
        [w, c, r, a, p, p_, u_v, u_ps, q] = cached_params{:};
        return;
      end

      w = sym('w', 'positive');
      c = sym('c', 'positive');

      syms r_2 'real' 'positive';
      syms r_3 'real' 'positive';
      r = [0; r_2; r_3];

      syms a_2 'real' 'positive';
      syms a_3 'real' 'positive';
      a = [0; a_2; a_3];

      syms p_2 'real' 'positive';
      syms p_3 'real' 'positive';
      p = [0; p_2; p_3];
      assume(0 < p_2 & p_2 <= 1);
      assume(0 < p_3 & p_3 <= 1);

      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];

      u_v = ParamsHelper.utility_taxi(w);

      u_ps = ParamsHelper.utility_passenger(r, a);

      q = ParamsHelper.trans_prob_vec(p, p_);

      cached_params = {w, c, r, a, p, p_, u_v, u_ps, q};
    end

    function [w, c, r, a, p, p_] = get_valued_params()
      persistent cached_params_valued;
      if ~isempty(cached_params_valued)
        [w, c, r, a, p, p_] = cached_params_valued{:};
        return;
      end

      w = 2000;

      c = 100;

      r = [0; 1500; 1500];

      a = [0; 10; 100];

      p = [0; 0.5; 0.5];

      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];

      cached_params_valued = {w, c, r, a, p, p_};
    end

    function u_v = utility_taxi(w)
      u_v = sym(zeros(3, 3));
      for j = 1:3
        for k = 1:3
          u_v(j, k) = w * abs(j - k);
        end
      end
    end

    function u_ps = utility_passenger(r, a)
      u_ps = sym(zeros(3, 3));
      for i = 1:3
        for j = 1:3
          u_ps(i, j) = r(j) - a(j) * abs(i - j);
        end
      end
    end

    function q = trans_prob_vec(p, p_)
      q = sym(zeros(27, 1));

      q(1) = (1 - p(1)) * (1 - p(2)) * (1 - p(3));

      q(2) = p(1)*p_(1, 2) * (1 - p(2)) * (1 - p(3));
      q(3) = p(1)*p_(1, 3) * (1 - p(2)) * (1 - p(3));

      q(4) = (1 - p(1)) * p(2)*p_(2, 1) * (1 - p(3));
      q(5) = (1 - p(1)) * p(2)*p_(2, 3) * (1 - p(3));

      q(6) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * (1 - p(3));
      q(7) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * (1 - p(3));
      q(8) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * (1 - p(3));
      q(9) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * (1 - p(3));

      q(10) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 1);
      q(11) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 2);

      q(12) = p(1)*p_(1, 2) * (1 - p(2)) * p(3)*p_(3, 1);
      q(13) = p(1)*p_(1, 3) * (1 - p(2)) * p(3)*p_(3, 1);
      q(14) = p(1)*p_(1, 2) * (1 - p(2)) * p(3)*p_(3, 2);
      q(15) = p(1)*p_(1, 3) * (1 - p(2)) * p(3)*p_(3, 2);

      q(16) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      q(17) = (1 - p(1)) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      q(18) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      q(19) = (1 - p(1)) * p(2)*p_(2, 3) * p(3)*p_(3, 2);

      q(20) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      q(21) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      q(22) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      q(23) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      q(24) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      q(25) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      q(26) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * p(3)*p_(3, 2);
      q(27) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * p(3)*p_(3, 2);
    end
  end
end
