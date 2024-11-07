
gridSize = 6;

utilitySum = zeros(gridSize, gridSize);
utilityCount = zeros(gridSize, gridSize);


for i = 2:length(PS_archive)
    x = PS_archive(i).x_d; 
    y = PS_archive(i).y_d; 
    utility = PS_archive(i).utility; 

   
    utilitySum(x, y) = utilitySum(x, y) + utility;
    utilityCount(x, y) = utilityCount(x, y) + 1;
end


averageUtility = utilitySum ./ utilityCount;


averageUtility(isnan(averageUtility)) = 0;


figure;
heatmap(averageUtility);
title('Average Utility');
xlabel('X');
ylabel('Y');
colorbar;
