classdef ParamsHelper
  methods (Static)
    function [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q] = get_symbolic_params()
      persistent cached_params;
      if ~isempty(cached_params)
        [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q] = cached_params{:};
        return;
      end

      % タクシーの即時報酬に関するパラメータ
      syms 'w' 'positive';
      syms 'c' 'positive';
      syms 'a' 'positive';
      u_v = ParamsHelper.utility_taxi(w, c, a);
      u_v_positive = u_v{1};
      u_v_negative = u_v{2};

      % 乗客の即時報酬に関するパラメータ
      % == Assumption ==
      % ノード1には乗客は出現しない
      syms r_2 'positive';
      syms r_3 'positive';
      syms b_2 'real' 'positive';
      syms b_3 'real' 'positive';
      r = [0; r_2; r_3];
      b = [0; b_2; b_3];
      u_ps = ParamsHelper.utility_passenger(r, b);
      u_ps_positive = u_ps{1};
      u_ps_negative = u_ps{2};

      % 乗客の出現に関するパラメータ
      syms p_2 'real' 'positive';
      syms p_3 'real' 'positive';
      p = [0; p_2; p_3];
      assume(0 < p_2 & p_2 <= 1);
      assume(0 < p_3 & p_3 <= 1);
      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];

      % 割引率
      syms 'g' 'positive';
      assume(0 <= g & g < 1);

      % 一般の場合はtrans_prob_vecを使う
      % q = ParamsHelper.trans_prob_vec(p, p_);
      % == Assumption == 
      % ps_{2,1}またはps_{3,1}のみ出現することを前提としているので、trans_prob_vec_only_ps21_ps31を使う
      q = ParamsHelper.trans_prob_vec_only_ps21_ps31(p, p_);

      cached_params = {w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q};
    end

    function [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q, V_init, x_init] = get_valued_params()
      persistent cached_params_valued;
      if ~isempty(cached_params_valued)
        [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q, V_init, x_init] = cached_params_valued{:};
        return;
      end

      % タクシーの即時報酬に関するパラメータ
      w = 2000;
      c = 10;
      a = 100;
      u_v = ParamsHelper.utility_taxi(w, c, a);
      u_v_positive = double(u_v{1});
      u_v_negative = double(u_v{2});

      % 乗客の即時報酬に関するパラメータ
      r = [0; 1500; 1250];
      b = [0; 100; 50];
      u_ps = ParamsHelper.utility_passenger(r, b);
      u_ps_positive = double(u_ps{1});
      u_ps_negative = double(u_ps{2});

      % 乗客の出現に関するパラメータ
      p = [0; 0.8; 0.2];
      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];
      
      % 割引率
      g = 0;

      % 一般の場合はtrans_prob_vecを使う
      % q = ParamsHelper.trans_prob_vec(p, p_);
      % == Assumption == 
      % ps_{2,1}またはps_{3,1}のみ出現することを前提としているので、trans_prob_vec_only_ps21_ps31を使う
      q = double(ParamsHelper.trans_prob_vec_only_ps21_ps31(p, p_));

      V_init = 1000*ones(1, length(VariablesHelper.init_state_values()));
      x_init = 1000*ones(1, size(VariablesHelper.init_expected_utilities(), 1) * size(VariablesHelper.init_expected_utilities(), 2));

      cached_params_valued = {w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q, V_init, x_init};
    end

    function u_v = utility_taxi(w, c, a)
      u_v_positive = sym(zeros(3, 3, 3));
      for i = 1:3
        for j = 1:3
          for k = 1:3
            u_v_positive(i, j, k) = -c*(abs(i-j)+abs(j-k)) + w*abs(j-k);
          end
        end
      end
      u_v_negative = -a;
      u_v = {u_v_positive, u_v_negative};
    end

    function u_ps = utility_passenger(r, b)
      u_ps_positive = sym(zeros(3, 3));
      for i = 1:3
        for j = 1:3
          u_ps_positive(i, j) = r(j) - b(j)*abs(i-j);
        end
      end
      u_ps_negative = -b;
      u_ps = {u_ps_positive, u_ps_negative};
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

    function q = trans_prob_vec_only_ps21_ps31(p, p_)
      q = sym(zeros(4, 1));

      q(1) = (1 - p(1)) * (1 - p(2)) * (1 - p(3));

      q(2) = (1 - p(1)) * p(2)*p_(2, 1) * (1 - p(3));

      q(3) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 1);

      q(4) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
    end

    function expr = evaluate_params(expr)
      % シンボリックな式のパラメータだけを数値的に評価する
      % 
      % Parameters:
      %   expr (sym): シンボリックな式
      % Returns:
      %   expr (sym): パラメータを数値的に評価した式。変数はsymbolicのまま
      [w, c, a, ~, ~, r, b, ~, ~, p, p_, g, ~] = ParamsHelper.get_symbolic_params();
      [w_val, c_val, a_val, ~, ~, r_val, b_val, ~, ~, p_val, p__val, g_val, ~, ~, ~] = ParamsHelper.get_valued_params();
      all_symbolic_params = [
        w, c, a, reshape(r.', 1, []), reshape(b.', 1, []), reshape(p.', 1, []), reshape(p_.', 1, []), g
      ];
      all_valued_params = [
        w_val, c_val, a_val, reshape(r_val.', 1, []), reshape(b_val.', 1, []), reshape(p_val.', 1, []), reshape(p__val.', 1, []), g_val
      ];
      
      expr = subs(expr, all_symbolic_params, all_valued_params);
    end
  end
end
