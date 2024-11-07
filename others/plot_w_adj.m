% 新しいデータを読み込む
data = [
    1.5 20 207.05 598.05 60161 21.35 7.6;
    2   20 210.6  598.05 60166 22.05 7.5;
    2.5 20 210.35 598.05 59905 22.95 7.35;
    3   20 209.6  598.05 60109 21.9  7.45;
];

% データを行列として分解
adj_w = data(:, 1);
GroupCount = data(:, 2);
mean_adjusted_count = data(:, 3);
mean_total_people = data(:, 4);
mean_true_utility = data(:, 5)/60029;
mean_5_step_ps = data(:, 6);
mean_10_step_ps = data(:, 7);

% サブプロットで独立した折れ線グラフを作成
figure;
% データを行列として分解
adj_w = data(:, 1);
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
plot(adj_w, mean_adjusted_count, '-o', 'LineWidth', 2);
title('Mean Adjusted Count', 'FontSize', 16); % フォントサイズを14に設定
xlabel('w', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean Adjusted Count', 'FontSize', 14);% フォントサイズを12に設定
ylim([0,450])
grid on;


% サブプロット3: 平均真の効用
subplot(2, 2, 2);
plot(adj_w, mean_true_utility, '-o', 'LineWidth', 2);
title('Mean True Utility', 'FontSize', 16); % フォントサイズを14に設定
xlabel('w', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean True Utility', 'FontSize', 14);
% フォントサイズを12に設定
ylim([0.9975,1.0025])
grid on;

% サブプロット4: 平均5ステップ以上待ったPS数
subplot(2, 2, 3);
plot(adj_w, mean_5_step_ps, '-o', 'LineWidth', 2);
title('Mean 5 Step PS', 'FontSize', 16); % フォントサイズを14に設定
xlabel('w', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean 5 Step PS', 'FontSize', 14); 
ylim([21,24])
% フォントサイズを12に設定
grid on;

% サブプロット5: 平均10ステップ以上待ったPS数
subplot(2, 2, 4);
plot(adj_w, mean_10_step_ps, '-o', 'LineWidth', 2);
title('Mean 10 Step PS', 'FontSize', 16); % フォントサイズを14に設定
xlabel('w', 'FontSize', 14); % フォントサイズを12に設定
ylabel('Mean 10 Step PS', 'FontSize', 14); % フォントサイズを12に設定
ylim([7.3,8.8])
grid on;