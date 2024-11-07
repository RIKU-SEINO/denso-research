function prob = prob_origin_flat(N, n_exp)
    prob = zeros(N, N); % N x Nのグリッドを初期化
    uniform_prob = n_exp / (N * N); % 各位置の一様分布の確率を計算

    for i = 1:N
        for j = 1:N
            prob(i, j) = uniform_prob; % 各位置に均等な確率を割り当て
        end
    end
end