% データを読み込む
data = [
    0.4 20 419.05 598.05 60068 22.35 7.65;
    0.6 20 328.95 598.05 59948 21.75 7.55;
    0.8 20 210.6 598.05 60166 22.05 7.5;
    1 20 115.05 598.05 60086 21.95 7.95;
    1.2 20 45.25 598.05 60129 22.9 8.4;
    1.4 20 16.1 598.05 60070 23.15 8.6;
    1.6 20 4.45 598.05 60029 23.3 8.7;
    1.8 20 0.8 598.05 60029 23.3 8.7;
];

% データを行列として分解
sigma_factor = data(:, 1);
GroupCount = data(:, 2);
mean_adjusted_count = data(:, 3);
mean_total_people = data(:, 4);
mean_true_utility = data(:, 5)/60029;
mean_5_step_ps = data(:, 6);
mean_10_step_ps = data(:, 7);

% サブプロットで独立した折れ線グラフを作成
figure;

% サブプロット1: 平均調整回数
subplot(2, 2, 1);
plot(sigma_factor, mean_adjusted_count, '-o', 'LineWidth', 2);
title('Mean Adjusted Count', 'FontSize', 16); % フォントサイズを14に設定
xlabel('n', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean Adjusted Count', 'FontSize', 14); % フォントサイズを12に設定
ylim([0,450])
grid on;


% サブプロット3: 平均真の効用
subplot(2, 2, 2);
plot(sigma_factor, mean_true_utility, '-o', 'LineWidth', 2);
title('Mean True Utility', 'FontSize', 16); % フォントサイズを14に設定
xlabel('n', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean True Utility', 'FontSize', 14); % フォントサイズを12に設定
ylim([0.9975,1.0025])
grid on;

% サブプロット4: 平均5ステップ以上待ったPS数
subplot(2, 2, 3);
plot(sigma_factor, mean_5_step_ps, '-o', 'LineWidth', 2);
title('Mean 5 Step PS', 'FontSize', 16); % フォントサイズを14に設定
xlabel('n', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean 5 Step PS', 'FontSize', 14); % フォントサイズを12に設定
ylim([21,24])
grid on;

% サブプロット5: 平均10ステップ以上待ったPS数
subplot(2, 2, 4);
plot(sigma_factor, mean_10_step_ps, '-o', 'LineWidth', 2);
title('Mean 10 Step PS', 'FontSize', 16); % フォントサイズを14に設定
xlabel('n', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean 10 Step PS', 'FontSize', 14); % フォントサイズを12に設定
ylim([7.3,8.8])
grid on;