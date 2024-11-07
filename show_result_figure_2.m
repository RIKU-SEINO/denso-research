figure
numBins = 20;

% 縦軸の上限を定数として設定
y_limit_ps_utility = 200;
y_limit_taxi_utility = 200;
y_limit_ps_waittime = 600;

% Subplot 4: Histogram of PS utility
subplot(1, 3, 1)
ps_utility_list = arrayfun(@(ps) ps.utility, PS_archive);
histogram(ps_utility_list, numBins)
title('Histogram of PS utility')
xlabel('PS utility')
ylabel('the number of PS')
xlim([0, 60])
ylim([0, y_limit_ps_utility])

% Subplot 5: Histogram of taxi utility
subplot(1, 3, 2)
list_taxi_utility = arrayfun(@(v) v.utility, V_archive);
histogram(list_taxi_utility, numBins)
title('Histogram of taxi utility')
xlabel('Taxi utility')
ylabel('the number of taxis')
xlim([-100, 170])
ylim([0, y_limit_taxi_utility])

% Subplot 6: Histogram of ps waiting time
subplot(1, 3, 3)
ps_waittime_list = arrayfun(@(ps) ps.t_m - ps.t0, PS_archive);
%bins = linspace(0, max(ps_waittime_list), numBins+1);
bins = linspace(0, 20, numBins+1);
histogram(ps_waittime_list, 'BinEdges',bins)
legend('ps')

title('Histogram of ps waiting time')
xlabel('waiting time')
ylabel('the number of PS')
xlim([0, 20])
ylim([0, y_limit_ps_waittime])