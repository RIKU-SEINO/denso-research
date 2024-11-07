function is_feasible = check_feasibility(M)
    is_feasible = 0;
    [l,m,n] = size(M);
    if M(1,1,1) == 1
        return
    end
    for i = 2:l
        if sum(M(i,:,:),"all") ~= 1
            return
        end
    end
    for j = 2:m
        if sum(M(:,j,:),"all") ~= 1
            return
        end
        if sum(M(1,j,2:n),"all") ~= 0
            return
        end
    end
    for k = 2:n
        if sum(M(:,:,k),"all") ~= 1
            return
        end
        if sum(M(1,2:m,k),"all") ~= 0
            return
        end
    end
    
    is_feasible = 1;
end