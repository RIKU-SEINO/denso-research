function triplet_set = transform_M(M)
    M_size = size(M);
    triplet_set = [];
    for i = 2:M_size(1)
        for jj = 1:M_size(2)
            k = find(M(i,jj,:));
            if k
                break
            end
        end
        for kk = 1:M_size(3)
            j = find(M(i,:,kk));
            if j
                break
            end
        end
        triplet = [i-1,j-1,k-1];
        triplet_set = [triplet_set; triplet];
    end
end
