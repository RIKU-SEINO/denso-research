function prob = prob_origin(N,n_exp)
    prob = zeros(N,N);
    prob_sum = 0;
    for i = 1:N
        for j = 1:N
            prob(i,j) = exp((-(i-N/5)^2-(j-N/5)^2)/N) + exp((-(i-4*N/5)^2-(j-4*N/5)^2)/N);
            prob_sum = prob_sum + prob(i,j);
        end
    end
    prob = prob / prob_sum * n_exp;
end