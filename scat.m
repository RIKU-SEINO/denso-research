numDataPoints = length(PS_archive);

Distances = zeros(numDataPoints, 1);
waittimes = zeros(numDataPoints, 1);

% マンハッタン距離と待ち時間を計算
for i = 1:numDataPoints
    x_o = PS_archive(i).x_o; 
    y_o = PS_archive(i).y_o; 
    x_d = PS_archive(i).x_d; 
    y_d = PS_archive(i).y_d; 
    
    Distances(i) = abs(x_o - x_d) + abs(y_o - y_d);
    
    waittimes(i) = PS_archive(i).t_m - PS_archive(i).t0;
end

% 相関係数
meanDistances = mean(Distances);
meanWaittimes = mean(waittimes);

numerator = sum((Distances - meanDistances) .* (waittimes - meanWaittimes));
denominator = sqrt(sum((Distances - meanDistances).^2) * sum((waittimes - meanWaittimes).^2));

correlationCoefficient = numerator / denominator;

figure;
scatter(Distances, waittimes, 'filled');
title('Scatter');
xlabel('|x_o - x_d| + |y_o - y_d| (Distance)');
ylabel('Waittime');
grid on;

% 相関係数を表示
disp(['Correlation Coefficient : ', num2str(correlationCoefficient)]);
