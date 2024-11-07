function [inc_U_v_opt, inc_U_ps_opt, inc_U_pc_opt, fval] = optimize_incentives_3(M_opt, U_v, U_ps, U_pc)
    %効率化，線形制約
    % インセンティブ変数の初期値
    [i, j, k] = size(M_opt);
    inc_U_v = zeros(i, j, k);
    inc_U_ps = zeros(i, j, k);
    inc_U_pc = zeros(i, j, k);
    initial_incentives = [inc_U_v(:); inc_U_ps(:); inc_U_pc(:)];
    
    % 目的関数
    objective = @(incentives) sum(incentives.^2);
    
    % 制約の設定
    [A, b, Aeq, beq] = linear_constraints(M_opt, U_v, U_ps, U_pc);
    
    % 最適化オプションの設定
    options = optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'off');
    
    % 最適化の実行
    [incentives_opt, fval] = fmincon(@(incentives) objective(incentives), initial_incentives, A, b, Aeq, beq, [], [], [], options);
    
    % 結果の表示
    inc_U_v_opt = reshape(incentives_opt(1:numel(inc_U_v)), size(inc_U_v));
    inc_U_ps_opt = reshape(incentives_opt(numel(inc_U_v)+1:numel(inc_U_v)+numel(inc_U_ps)), size(inc_U_ps));
    inc_U_pc_opt = reshape(incentives_opt(numel(inc_U_v)+numel(inc_U_ps)+1:end), size(inc_U_pc));
    
%     disp('Optimal incentives for taxis:');
%     disp(inc_U_v_opt);
%     disp('Optimal incentives for passengers:');
%     disp(inc_U_ps_opt);
%     disp('Optimal incentives for packages:');
%     disp(inc_U_pc_opt);
%     disp('Minimum sum of squares of incentives:');
%     disp(fval);
end

function [A, b, Aeq, beq] = linear_constraints(M_opt, U_v, U_ps, U_pc)
    [i, j, k] = size(M_opt);
    inc_U_v = zeros(i, j, k);
    inc_U_ps = zeros(i, j, k);
    inc_U_pc = zeros(i, j, k);
    
    % マッチが存在するインデックスを取得
    [matched_i, matched_j, matched_k] = ind2sub(size(M_opt), find(M_opt));
    
    % 制約数の計算
    num_constraints = i * j * k * length(matched_i);
    
    % 制約用配列の事前割り当て
    A = zeros(num_constraints, 3*i*j*k);
    b = zeros(num_constraints, 1);
    
    % インセンティブを0にする制約用配列の初期化
    ceq_idx = 1;
    Aeq = zeros(numel(M_opt)*3 + 1, 3*i*j*k);
    beq = zeros(numel(M_opt)*3 + 1, 1);

    % マッチしていない組のインセンティブを0にする制約
    for l = 1:i
        for m = 1:j
            for n = 1:k
                if M_opt(l, m, n) == 0
                    idx = sub2ind([i, j, k], l, m, n);
                    Aeq(ceq_idx, idx) = 1;
                    ceq_idx = ceq_idx + 1;
                    Aeq(ceq_idx, numel(inc_U_v) + idx) = 1;
                    ceq_idx = ceq_idx + 1;
                    Aeq(ceq_idx, numel(inc_U_v) + numel(inc_U_ps) + idx) = 1;
                    ceq_idx = ceq_idx + 1;
                end
            end
        end
    end
    
    % 制約の設定
    c_idx = 1;
    for l = 1:i
        for m = 1:j
            for n = 1:k
                if M_opt(l, m, n) == 0
                    for idx = 1:length(matched_i)
                        y1 = matched_j(idx);
                        z1 = matched_k(idx);
                        x2 = matched_i(idx);
                        z2 = matched_k(idx);
                        x3 = matched_i(idx);
                        y3 = matched_j(idx);
                        
                        % 制約条件の生成
                        if n == 1 && m == 1
                            % 乗客も貨物もない場合
                            lhs = zeros(1, 3*i*j*k);
                            lhs(sub2ind([i, j, k], l, m, n)) = 1;
                            rhs = zeros(1, 3*i*j*k);
                            rhs(sub2ind([i, j, k], l, y1, z1)) = -1;
                            rhs(numel(inc_U_v) + sub2ind([i, j, k], l, y1, z1)) = -1;
                            A(c_idx, :) = lhs - rhs;
                            b(c_idx) = -U_v(l, m, n);
                        elseif n == 1
                            % 貨物がない場合
                            lhs = zeros(1, 3*i*j*k);
                            lhs(sub2ind([i, j, k], l, m, n)) = 1;
                            lhs(numel(inc_U_v) + sub2ind([i, j, k], l, m, n)) = 1;
                            rhs = zeros(1, 3*i*j*k);
                            rhs(sub2ind([i, j, k], l, y1, z1)) = -1;
                            rhs(numel(inc_U_v) + sub2ind([i, j, k], x2, m, z2)) = -1;
                            rhs(numel(inc_U_v) + numel(inc_U_ps) + sub2ind([i, j, k], x2, m, z2)) = -1;
                            A(c_idx, :) = lhs - rhs;
                            b(c_idx) = -(U_v(l, m, n) + U_ps(l, m, n));
                        elseif m == 1
                            % 乗客がない場合
                            lhs = zeros(1, 3*i*j*k);
                            lhs(sub2ind([i, j, k], l, m, n)) = 1;
                            lhs(numel(inc_U_v) + numel(inc_U_ps) + sub2ind([i, j, k], l, m, n)) = 1;
                            rhs = zeros(1, 3*i*j*k);
                            rhs(sub2ind([i, j, k], l, y1, z1)) = -1;
                            rhs(numel(inc_U_v) + sub2ind([i, j, k], l, y1, z1)) = -1;
                            rhs(numel(inc_U_v) + numel(inc_U_ps) + sub2ind([i, j, k], x3, y3, n)) = -1;
                            A(c_idx, :) = lhs - rhs;
                            b(c_idx) = -(U_v(l, m, n) + U_pc(l, m, n));
                        else
                            % 乗客と貨物がいる場合
                            lhs = zeros(1, 3*i*j*k);
                            lhs(sub2ind([i, j, k], l, m, n)) = 1;
                            lhs(numel(inc_U_v) + sub2ind([i, j, k], l, m, n)) = 1;
                            lhs(numel(inc_U_v) + numel(inc_U_ps) + sub2ind([i, j, k], l, m, n)) = 1;
                            rhs = zeros(1, 3*i*j*k);
                            rhs(sub2ind([i, j, k], l, y1, z1)) = -1;
                            rhs(numel(inc_U_v) + sub2ind([i, j, k], x2, m, z2)) = -1;
                            rhs(numel(inc_U_v) + numel(inc_U_ps) + sub2ind([i, j, k], x3, y3, n)) = -1;
                            A(c_idx, :) = lhs - rhs;
                            b(c_idx) = -(U_v(l, m, n) + U_ps(l, m, n) + U_pc(l, m, n));
                        end
                        c_idx = c_idx + 1;
                    end
                end
            end
        end
    end
    
    % インセンティブの和が0になる制約
    Aeq(end, :) = [ones(1, numel(inc_U_v)), ones(1, numel(inc_U_ps)), ones(1, numel(inc_U_pc))];
    beq(end) = 0;
end

