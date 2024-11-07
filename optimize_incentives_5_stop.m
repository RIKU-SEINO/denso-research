function [inc_U_v_opt, inc_U_ps_opt, inc_U_pc_opt, fval] = optimize_incentives_5_stop(M_opt, U_v, U_ps, U_pc)
    % インセンティブ変数の初期値
    [i, j, k] = size(M_opt);
    inc_U_v = zeros(i, j, k);
    inc_U_ps = zeros(i, j, k);
    inc_U_pc = zeros(i, j, k);
    initial_incentives = [inc_U_v(:); inc_U_ps(:); inc_U_pc(:)];
    
    % 目的関数
    objective = @(incentives) sum(incentives.^2);
    
     % 最適化オプションの設定
     options = optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'off');



    % 最適化の実行
    [incentives_opt, fval] = fmincon(@(incentives) objective(incentives), initial_incentives, [], [], [], [], [], [], ...
        @(incentives) blocking_pairs_constraints(incentives, M_opt, U_v, U_ps, U_pc), options);
    
    % 結果の表示
    inc_U_v_opt = reshape(incentives_opt(1:numel(inc_U_v)), size(inc_U_v));
    inc_U_ps_opt = reshape(incentives_opt(numel(inc_U_v)+1:numel(inc_U_v)+numel(inc_U_ps)), size(inc_U_ps));
    inc_U_pc_opt = reshape(incentives_opt(numel(inc_U_v)+numel(inc_U_ps)+1:end), size(inc_U_pc));
    
    disp('Optimal incentives for taxis:');
    disp(inc_U_v_opt);
    disp('Optimal incentives for passengers:');
    disp(inc_U_ps_opt);
    disp('Optimal incentives for packages:');
    disp(inc_U_pc_opt);
    disp('Minimum sum of squares of incentives:');
    disp(fval);
end

function [c, ceq] = blocking_pairs_constraints(incentives, M_opt, U_v, U_ps, U_pc)
    [i, j, k] = size(M_opt);
    inc_U_v = reshape(incentives(1:i*j*k), [i, j, k]);
    inc_U_ps = reshape(incentives(i*j*k+1:2*i*j*k), [i, j, k]);
    inc_U_pc = reshape(incentives(2*i*j*k+1:end), [i, j, k]);
    
    % マッチが存在するインデックスを取得
    [matched_i, matched_j, matched_k] = ind2sub(size(M_opt), find(M_opt));
    
    % 制約数の計算
    num_constraints = i * j * k * length(matched_i);
    
    % 制約用配列の事前割り当て
    c = zeros(num_constraints, 1);
    ceq = zeros(num_constraints + numel(M_opt)*3 + 1, 1);
    ceq_idx = 1;
    
    % マッチしていない組のインセンティブを0にする制約
    for l = 1:i
        for m = 1:j
            for n = 1:k
                if M_opt(l, m, n) == 0
                    ceq(ceq_idx) = inc_U_v(l, m, n);
                    ceq_idx = ceq_idx + 1;
                    ceq(ceq_idx) = inc_U_ps(l, m, n);
                    ceq_idx = ceq_idx + 1;
                    ceq(ceq_idx) = inc_U_pc(l, m, n);
                    ceq_idx = ceq_idx + 1;
                end
            end
        end
    end
    
    % 制約の設定
    c_idx = 1;
    for l = 2:i
        for m = 1:j
            for n = 1:k
                if M_opt(l, m, n) == 0
                    
                       
                     if l == 1 && m == 1 && n == 1
                         % Case 1: l, m, n all equal 1
                         
                     elseif l == 1 && m == 1
                         x2 = matched_i(find(matched_j==m));
                         z2 = matched_k(find(matched_j==m));
                         c_idx = c_idx + 1;
                         c(c_idx) = U_ps(l, m, n) - ( U_ps(x2, m, z2) + inc_U_ps(x2, m, z2));
%                      elseif l == 1 && n == 1
%                          % Case 3: l and n equal 1
%                          c(c_idx) = U_v(l, m, n) + U_ps(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_ps(x2, m, z2) + inc_U_ps(x2, m, z2));
%                      elseif m == 1 && n == 1
%                          % Case 4: m and n equal 1
%                          c(c_idx) = U_v(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1));
%                      elseif l == 1
%                          % Case 5: l equal 1
%                          c(c_idx) = U_v(l, m, n) + U_ps(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_ps(x2, m, z2) + inc_U_ps(x2, m, z2) + U_pc(x3, y3, n) + inc_U_pc(x3, y3, n));
%                      elseif m == 1
%                          % Case 6: m equal 1
%                          c(c_idx) = U_v(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_pc(x3, y3, n) + inc_U_pc(x3, y3, n));
%                      elseif n == 1
%                          % Case 7: n equal 1
%                          c(c_idx) = U_v(l, m, n) + U_ps(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_ps(x2, m, z2) + inc_U_ps(x2, m, z2));
%                      else
%                          % Case 8: none equal 1
%                          c(c_idx) = U_v(l, m, n) + U_ps(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_ps(x2, m, z2) + inc_U_ps(x2, m, z2) + U_pc(x3, y3, n) + inc_U_pc(x3, y3, n));
%                      end
% 
%                         % 制約条件の生成
%                         if n == 1 && m == 1
%                             % 乗客も貨物もない場合
%                             y1 = matched_j(find(matched_i==l));
%                             z1 = matched_k(find(matched_i==l));
%                             c(c_idx) = U_v(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1));
%                         elseif n == 1
%                             % 貨物がない場合
%                             y1 = matched_j(find(matched_i==l));
%                             z1 = matched_k(find(matched_i==l));
%                             x2 = matched_i(find(matched_j==m));
%                             z2 = matched_k(find(matched_j==m));
%                             c(c_idx) = U_v(l, m, n) + U_ps(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_ps(x2, m, z2) + inc_U_ps(x2, m, z2));
%                         elseif m == 1
%                             % 乗客がない場合
%                              y1 = matched_j(find(matched_i==l));
%                              z1 = matched_k(find(matched_i==l));
%                              x3 = matched_i(find(matched_k==n));
%                              y3 = matched_j(find(matched_k==n));
%                              c(c_idx) = U_v(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_pc(x3, y3, n) + inc_U_pc(x3, y3, n));
%                         else
%                             % 乗客と貨物がいる場合
%                              y1 = matched_j(find(matched_i==l));
%                              z1 = matched_k(find(matched_i==l));
%                              x2 = matched_i(find(matched_j==m));
%                              z2 = matched_k(find(matched_j==m));
%                              x3 = matched_i(find(matched_k==n));
%                              y3 = matched_j(find(matched_k==n));
% 
%                              c(c_idx) = U_v(l, m, n) + U_ps(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + inc_U_v(l, y1, z1) + U_ps(x2, m, z2) + inc_U_ps(x2, m, z2) + U_pc(x3, y3, n) + inc_U_pc(x3, y3, n));
%                         end
%                         c_idx = c_idx + 1;
                    
                end
            end
        end
    end
    % インセンティブの和が0になる制約
    ceq(ceq_idx) = sum(inc_U_v(:)) + sum(inc_U_ps(:)) + sum(inc_U_pc(:));
end