function [M_opt, u_max] = triplet_MILP_with_variance(U, U_v, U_ps)
    [i, j, k] = size(U);

    % 目的関数の係数ベクトルを再形成
    f = reshape(U, [], 1);

    % 制約の設定
    Aeq = zeros(i+2*j+2*k-5, length(f));
    constraint_cnt = 1;

    % 全てのプレイヤーが1つのトリプレットに属することを保証する制約
    % タクシー
    for ii = 2:i
        A_tmp = zeros(size(U));
        A_tmp(ii, :, :) = 1;
        Aeq(constraint_cnt, :) = reshape(A_tmp, 1, []);
        constraint_cnt = constraint_cnt + 1;
    end

    % 乗客
    for jj = 2:j
        A_tmp = zeros(size(U));
        A_tmp(:, jj, :) = 1;
        Aeq(constraint_cnt, :) = reshape(A_tmp, 1, []);
        constraint_cnt = constraint_cnt + 1;
    end

    % パッケージ
    for kk = 2:k
        A_tmp = zeros(size(U));
        A_tmp(:, :, kk) = 1;
        Aeq(constraint_cnt, :) = reshape(A_tmp, 1, []);
        constraint_cnt = constraint_cnt + 1;
    end

    % タクシーなしのマッチングを防ぐ制約
    for jjj = 2:j
        A_tmp = zeros(size(U));
        A_tmp(1, jjj, 2:k) = 1;
        Aeq(constraint_cnt, :) = reshape(A_tmp, 1, []);
        constraint_cnt = constraint_cnt + 1;
    end

    for kkk = 2:k
        A_tmp = zeros(size(U));
        A_tmp(1, 2:j, kkk) = 1;
        Aeq(constraint_cnt, :) = reshape(A_tmp, 1, []);
        constraint_cnt = constraint_cnt + 1;
    end

    beq = [ones(i+j+k-3, 1); zeros(j+k-2, 1)];

    % 不等式制約の設定
    A = zeros(i-1, length(f));
    b = zeros(i-1, 1);

    for iii = 2:i
        A_tmp = zeros(size(U));
        A_tmp(iii, :, :) = U_v(iii, :, :);
        A(iii-1, :) = reshape(A_tmp, 1, []);
        b(iii-1, 1) = U_v(iii, 1, 1);
    end

    % 初期解の設定
    x0 = zeros(length(f), 1);

    % 目的関数
    function obj = objective(x)
        linear_term = -f' * x';
        variance_term = var(f .* x);
        lambda = 1; % 分散の重みを調整するパラメータ
        obj = linear_term + lambda * variance_term;
    end

    % 制約関数
    function [c, ceq] = constraints(x)
        % 不等式制約は -A * x <= b
        c = A * x' - b;
        % 等式制約は Aeq * x = beq
        ceq = Aeq * x' - beq;
    end

    % 変数の下限と上限
    lb = zeros(length(f), 1);
    ub = [0; ones(length(f)-1, 1)];

    % 整数制約を考慮した遺伝的アルゴリズムの設定
    intcon = 1:length(f);
    options = optimoptions('ga', 'Display', 'iter', 'UseParallel', true);

    % 遺伝的アルゴリズムによる非線形計画問題の解法
    [x, fval] = ga(@objective, length(f), [], [], Aeq, beq, lb, ub, @constraints, intcon, options);

    % 結果の再構築
    M_opt = reshape(x, [i, j, k]);
    M_opt = round(M_opt);
    u_max = -fval;

    % 結果の検証
    if check_feasibility(M_opt) == 0
        warning('M is unfeasible');
        global error_M;
        error_M = M_opt;
    end
end
