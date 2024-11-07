
gridSize = 6;

waittimeSum = zeros(gridSize, gridSize);
waittimeCount = zeros(gridSize, gridSize);

for i = 1:length(PS_archive)
    x = PS_archive(i).x_o; 
    y = PS_archive(i).y_o; 
    waittime = PS_archive(i).t_m - PS_archive(i).t0; 

    waittimeSum(x, y) = waittimeSum(x, y) + waittime;
    waittimeCount(x, y) = waittimeCount(x, y) + 1;
end


averageWaittime = -waittimeSum ./ waittimeCount;



figure;
heatmap(averageWaittime);
title('Average Waittime');
xlabel('X');
ylabel('Y');
colorbar;
