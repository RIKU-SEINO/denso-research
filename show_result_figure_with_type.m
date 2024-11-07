% show results
figure
numBins = 30;

xlim1=-60;
xlim2=90;
ylim2=140;
% subplot(2, 3, 1)
% hold on
% plot(timeline_n_taxi)
% plot(timeline_n_ps)
% plot(timeline_n_pc)
% legend('taxi', 'passenger', 'package')
% title('Timeline of the number of the players')
% xlabel('time')
% ylabel('the number of the players')
% subplot(2, 3, 1)
% list_inc_ps_utility = arrayfun(@(ps) ps.incentived_u, PS_archive);
% list_inc_ps_utility = round(list_inc_ps_utility,3);
% histogram(list_inc_ps_utility)

subplot(2, 3, 1)
ps0_utility_list = arrayfun(@(ps) ps.utility, PS_archive_0);
ps0_utility_list = round(ps0_utility_list ,3);
histogram(ps0_utility_list)
title('Histogram of PS0 utility')
xlabel('PS utilily')
ylabel('the number of PS0')
xlim([xlim1, xlim2])
ylim([0,ylim2])

subplot(2, 3, 2)
ps1_utility_list = arrayfun(@(ps) ps.utility, PS_archive_1);
ps1_utility_list = round(ps1_utility_list ,3);
histogram(ps1_utility_list)
title('Histogram of PS1 utility')
xlabel('PS utilily')
ylabel('the number of PS1')
xlim([xlim1, xlim2])
ylim([0,ylim2])

% subplot(2, 3, 2)
% list_operation_length = arrayfun(@(v) v.operation_remained, V_archive);
% histogram(list_operation_length)
% title('Histogram of operation length')
% xlabel('length of operation')
% ylabel('the number of operation')

% subplot(2, 3, 2)
% list_inc_taxi_utility = arrayfun(@(v) v.incentived_u, V_archive);
% list_inc_taxi_utility = round(list_inc_taxi_utility,3);
% histogram(list_inc_taxi_utility)

subplot(2, 3, 3)
plot(timeline_mixed_ratio(:,1:2))
legend('ps0', 'ps1')
ylim([0,1])
grid on
title('Timeline of mixed ratio')
xlabel('time')
ylabel('the ratio of mixed PS')

% subplot(2, 3, 4)
% ps0_utility_list_inc = arrayfun(@(ps) ps.incentive, PS_archive_0);
% ps0_utility_list_inc = round(ps0_utility_list_inc ,3);
% histogram(ps0_utility_list_inc,numBins)
% title('incentive of PS0')
% xlabel('incentive')
% ylabel('the number of PS0')
% xlim([xlim1, xlim2])
% ylim([0,ylim2])
% % ps_utility_list = arrayfun(@(ps) ps.utility, PS_archive);
% % ps_utility_list = round(ps_utility_list ,3);
% % histogram(ps_utility_list)
% % title('Histogram of PS utility')
% % xlabel('PS utilily')
% % ylabel('the number of PS')

% subplot(2, 3, 5)
% ps1_utility_list_inc = arrayfun(@(ps) ps.incentive, PS_archive_1);
% ps1_utility_list_inc = round(ps1_utility_list_inc ,3);
% histogram(ps1_utility_list_inc,numBins)
% title('incentive of PS1')
% xlabel('incentive')
% ylabel('the number of PS1')
% xlim([xlim1, xlim2])
% ylim([0,ylim2])
% % list_taxi_utility = arrayfun(@(v) v.utility, V_archive);
% % list_taxi_utility = round(list_taxi_utility ,3);
% % histogram(list_taxi_utility)
% % title('Histogram of taxi utility')
% % xlabel('Taxi utility')
% % ylabel('the number of taxies')

subplot(2, 3, 6)
hold on
ps0_waittime_list = arrayfun(@(ps) ps.t_m - ps.t0, PS_archive_0);
ps1_waittime_list = arrayfun(@(ps) ps.t_m - ps.t0, PS_archive_1);

bins = linspace(0, max(max(ps0_waittime_list), max(ps1_waittime_list)), numBins + 1);

histogram(ps0_waittime_list, 'BinEdges', bins, 'Normalization', 'probability')
histogram(ps1_waittime_list, 'BinEdges', bins, 'Normalization', 'probability')

legend('ps0','ps1')

title('Normalized Histogram of ps  waiting time')
xlabel('waiting time')
ylabel('the ratio of PS')

