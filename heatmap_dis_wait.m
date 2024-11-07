
numDataPoints = length(PS_archive);

Distances = zeros(numDataPoints, 1);
waittimes = zeros(numDataPoints, 1);


for i = 1:numDataPoints
    x_o = PS_archive(i).x_o;  
    y_o = PS_archive(i).y_o; 
    x_d = PS_archive(i).x_d; 
    y_d = PS_archive(i).y_d; 
    
   
    Distances(i) = abs(x_o - x_d) + abs(y_o - y_d);
    
    waittimes(i) = PS_archive(i).t_m - PS_archive(i).t0;
end

% 待ち時間を10以下に制限
validIndices = waittimes <= 60;
Distances = Distances(validIndices);
waittimes = waittimes(validIndices);

% ビン数を設定
numBinsX = max(Distances); 
numBinsY = 60; 


[counts, binEdgesX, binEdgesY] = histcounts2(Distances, waittimes, [numBinsX numBinsY]);


figure;
imagesc('XData', binEdgesX, 'YData', binEdgesY, 'CData', counts');
colorbar;
set(gca, 'YDir', 'normal'); 
title('Heatmap of Distance vs. Waittime (Waittime ≤ 20)');
xlabel('|x_o - x_d| + |y_o - y_d| (Distance)');
ylabel('Waittime');
