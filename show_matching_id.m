function show_matching_id(Player_set_record,Matching_matrix,Utility_matrix,iter)

    V_id_list=arrayfun(@(x) x.id,Player_set_record{iter,1});
    PS_id_list=arrayfun(@(x) x.id,Player_set_record{iter,2});
    PC_id_list=arrayfun(@(x) x.id,Player_set_record{iter,3});
    U_v=Utility_matrix{iter,1};
    U_ps=Utility_matrix{iter,2};
    U_pc=Utility_matrix{iter,3};
    M=Matching_matrix{iter};

    [i,j,k] = size(M);

    disp('M:')
    for l=1:i
        for m=1:j
            for n=1:k
                if M(l,m,n)==1
                    disp(['{', num2str(V_id_list(l)), ',', num2str(PS_id_list(m)), ',', num2str(PC_id_list(n)), '}'])
                end
            end
        end
    end

    disp('EBP:')
    [matched_i, matched_j, matched_k] = ind2sub(size(M), find(M));
     for l = 1:i
        for m = 1:j
            for n = 1:k
                if M(l, m, n) == 0
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
                       
                    elseif l ~= 1 && m ~= 1
                        % 貨物がない場合
                        violation = U_v(l, m, n) + U_ps(l, m, n) - (U_v(l, y1, z1) + U_ps(x2, m, z2));
                        
                    elseif l ~= 1 && n ~= 1
                        % 乗客がない場合
                        violation = U_v(l, m, n) + U_pc(l, m, n) - (U_v(l, y1, z1) + U_pc(x3, y3, n));
                        
                    elseif m ~= 1 && n ~= 1
                        % タクシーがいない場合
                        violation = 0;
                        
                    elseif l ~= 1
                        % タクシーだけいる場合
                        violation = U_v(l, m, n) - U_v(l, y1, z1);
                        
                    elseif m ~= 1
                        % 乗客だけいる場合
                        violation = U_ps(l, m, n) - U_ps(x2, m, z2);
                        
                    elseif n ~= 1
                        % 貨物だけいる場合
                        violation = U_pc(l, m, n) - U_pc(x3, y3, n);
                       
                    else
                        violation = 0;
                        
                    end
                    
                    if violation > 0
                        disp(['{', num2str(V_id_list(l)), ',', num2str(PS_id_list(m)), ',', num2str(PC_id_list(n)), '}'])
                       
                    end
                    
                end
            end
        end
    end
end
