
N = 6;     
n_exp = 2; 
prob = prob_origin(N, n_exp);

figure;
heatmap(prob);
title('Probability Heatmap');
xlabel('X ');
ylabel('Y ');
colorbar;
