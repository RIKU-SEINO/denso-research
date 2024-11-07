% show results
figure
numBins = 20;

subplot(1, 3, 1)
hold on
plot(timeline_n_ps)
plot(pre_inc_num)

legend('all ps', '2. incentived ps')
title('Timeline of the number of PS')
xlabel('time')
ylabel('the number of the PS')
% subplot(2, 3, 1)
% list_inc_ps_utility = arrayfun(@(ps) ps.incentived_u, PS_archive);
% list_inc_ps_utility = round(list_inc_ps_utility,3);
% histogram(list_inc_ps_utility)

subplot(1, 3, 3)
hold on
plot(timeline_inc)
title('Timeline of total incentives')
xlabel('time')
ylabel('total incentives')
% subplot(2, 3, 2)
% list_operation_length = arrayfun(@(v) v.operation_remained, V_archive);
% histogram(list_operation_length)
% title('Histogram of operation length')
% xlabel('length of operation')
%ylabel('the number of operation')

% subplot(2, 3, 2)
% list_inc_taxi_utility = arrayfun(@(v) v.incentived_u, V_archive);
% list_inc_taxi_utility = round(list_inc_taxi_utility,3);
% histogram(list_inc_taxi_utility)

subplot(1, 3, 2)


plot(-total_inc_record)
hold on
plot(total_preinc_record)
legend('-1.','2.')
grid on
title('Timeline of -1. & 2. incentives')
xlabel('time')
ylabel('incentives')

% subplot(2, 3, 4)
% ps_utility_list = arrayfun(@(ps) ps.utility, PS_archive);
% ps_utility_list = round(ps_utility_list ,3);
% histogram(ps_utility_list)
% title('Histogram of PS utility')
% xlabel('PS utilily')
% ylabel('the number of PS')
% 
% subplot(2, 3, 5)
% list_taxi_utility = arrayfun(@(v) v.utility, V_archive);
% list_taxi_utility = round(list_taxi_utility ,3);
% histogram(list_taxi_utility)
% title('Histogram of taxi utility')
% xlabel('Taxi utility')
% ylabel('the number of taxies')
% 
% subplot(2, 3, 6)
% hold on
% ps_waittime_list = arrayfun(@(ps) ps.t_m - ps.t0, PS_archive);
% pc_waittime_list = arrayfun(@(pc) pc.t_m - pc.t0, PC_archive);
% 
% 
% bins = 0:1:28;
% histogram(ps_waittime_list, 'BinEdges', bins)
% histogram(pc_waittime_list, 'BinEdges', bins)
% legend('ps', 'pc')
% 
% title('Histogram of ps waiting time')
% xlabel('waiting time')
% ylabel('the number of PS')
% 
% 
% xlim([0 28])
% ylim([0 500])
% 
% disp(mean(ps_waittime_list))