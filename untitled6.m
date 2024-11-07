% パラメータの設定
mu = 0;         % 平均
sigma = 1;      % 標準偏差

% xの範囲を設定
x = 0:0.01:5;

% ガウス関数の定義
f = (1/(sigma * sqrt(2 * pi))) * exp(-(x - mu).^2 / (2 * sigma^2));
g = 1.1*(1/(sigma * sqrt(2 * pi))) * exp(-(x - mu).^2 / (2 * sigma^2))-0.4*0.1;

% プロット
figure;
plot(x, f, 'LineWidth', 3);  % fのラインの太さを2に設定
hold on
plot(x, g, 'LineWidth', 3);  % gのラインの太さを2に設定
ylim([0,0.5])
xlabel('t');
ylabel('utility of PS');
grid on;


