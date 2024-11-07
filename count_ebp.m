function [num_ebp_violations, violation_counts,total_counts] = count_ebp(M_opt, U_v, U_ps, U_pc)
    
    num_ebp_violations = 0;
    
    % 各ケースごとの違反数を格納する配列
    violation_counts = zeros(1, 7);
    total_counts= zeros(1, 7);

    [i, j, k] = size(M_opt);
    
    [matched_i, matched_j, matched_k] = ind2sub(size(M_opt), find(M_opt));
    
    for l = 1:i
        for m = 1:j
            for n = 1:k
                if M_opt(l, m, n) == 0
                    y1 = matched_j(matched_i == l);
                    z1 = matched_k(matched_i == l);
                    x2 = matched_i(matched_j == m);
                    z2 = matched_k(matched_j == m);
                    x3 = matched_i(matched_k == n);
                    y3 = matched_j(matched_k == n);
                    
                    if l ~= 1 && m ~= 1 && n ~= 1
                        % 乗客と貨物がいる場合
                        violation = U_v(l, m, n) + U_ps(l, m, n) + U_pc(l, m, n) - ...
                            (U_v(l, y1, z1) + U_ps(x2, m, z2) + U_pc(x3, y3, n));
                        case_idx = 1;
                    elseif l ~= 1 && m ~= 1
                        % 貨物がない場合
                        violation = U_v(l, m, n) + U_ps(l, m, n) - (U_v(l, y1, z1) + U_ps(x2, m, z2));
                        case_idx = 2;
                    elseif l ~= 1 && n ~= 1
                        % 乗客がない場合
                        violation = U_v(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + U_pc(x3, y3, n));
                        case_idx = 3;
                    elseif m ~= 1 && n ~= 1
                        % タクシーがいない場合
                        violation = 0;
                        case_idx = 4;
                    elseif l ~= 1
                        % タクシーだけいる場合
                        violation = U_v(l, m, n) - U_v(l, y1, z1);
                        case_idx = 5;
                    elseif m ~= 1
                        % 乗客だけいる場合
                        violation = U_ps(l, m, n) - U_ps(x2, m, z2);
                        case_idx = 6;
                    elseif n ~= 1
                        % 貨物だけいる場合
                        violation = U_pc(l, m, n) - U_pc(x3, y3, n);
                        case_idx = 7;
                    else
                        violation = 0;
                        case_idx = 0;
                    end
                    
                    if violation > 0
%                         disp([l,m,n])
                        num_ebp_violations = num_ebp_violations + 1;
                        if case_idx > 0
                            violation_counts(case_idx) = violation_counts(case_idx) + 1;
                        end
                    end
                    if case_idx ~= 0 && case_idx ~= 4
                            total_counts(case_idx) = total_counts(case_idx) + 1;
                    end
                end
            end
        end
    end
end
