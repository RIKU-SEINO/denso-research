function [M_opt, u_max] = triplet_matching(U, l, m, n, M_opt, u_max, current_M, depth)
    if nargin < 2
        [l,m,n] = size(U);
        current_M = zeros(l,m,n);
        depth = l;
        M_opt = current_M;
        u_max = -1e10;

    end
    
    if depth == 0
        for i_ = 2:m
            current_M(1,i_,1) = ~ sum(current_M(2:l,i_,:),"all");
        end
        for j_ = 2:n
            current_M(1,1,j_) = ~ sum(current_M(2:l,:,j_),"all");
        end
        if check_feasibility(current_M)
            u_tmp = sum(U.*current_M,"all");

            if u_tmp > u_max
                u_max = u_tmp;
                M_opt = current_M;
            end
        else
            
        end
        
    else
        for i = 1:m
            for j = 1:n
            % 現在のループ変数の値を設定
            current_M(depth,:,:) = 0;
            current_M(depth,i,j) = 1;
            % 次のネストされたループを呼び出す
            [M_opt, u_max] = triplet_matching(U, l, m, n,M_opt,u_max, current_M, depth-1);
            end
        end
    end
end