function [U_ps_adjusted, U_platform_adjusted, adjusted_count,sigma_factor,adj_w] = adjust_weights(U_platform, U_ps)
    % U_platformのサイズを取得
    [i, j, k] = size(U_platform);

    %parameter
    sigma_factor = 0.5;
    adj_w=2;
    % 第1次元と第3次元に沿って合計を計算し、サイズ1の次元を削除
    U_sum = squeeze(sum(sum(U_platform, 1), 3));
    
    % 合計の平均と標準偏差を計算
    U_mean = mean(U_sum);
    U_std = std(U_sum);
    
    % 平均よりsigma_factor * σ以上下回る要素を特定する論理インデックスを作成
   
    index = (U_sum < (U_mean - sigma_factor * U_std));
    index(1)=false;

    % U_psのコピーを作成
    U_ps_adjusted = U_ps;
    
    % 調整された人数をカウント
    adjusted_count = sum(index);
   
    
    % 条件に一致する要素を増加s
    for jj = 2:j
        if index(jj)
            U_ps_adjusted(:, jj, :) = U_ps_adjusted(:, jj, :) * adj_w; % 調整係数は必要に応じて変更
        end
    end
    
    % U_platformを更新する。
    U_platform_adjusted = U_platform - U_ps + U_ps_adjusted;
end
