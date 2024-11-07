function prob = prob_destination(N,x,y)
    prob = prob_origin_flat(N,1);
    prob(x,y) = 0;
    prob = prob / sum(prob,'all');
    
end