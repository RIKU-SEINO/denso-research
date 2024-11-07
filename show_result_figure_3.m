% show results
figure
numBins = 20;

subplot(3, 3, 1)
list_taxi_utility = arrayfun(@(v) v.utility, V_archive);
list_taxi_utility = round(list_taxi_utility ,3);
histogram(list_taxi_utility,numBins)
title('taxi utility')
xlabel('Taxi utility')
ylabel('the number of taxies')
xlim([-80, 160])
ylim([0,300])


subplot(3, 3, 2)
ps_utility_list = arrayfun(@(ps) ps.utility, PS_archive);
ps_utility_list = round(ps_utility_list ,3);
histogram(ps_utility_list,numBins)
title('PS utility')
xlabel('PS utilily')
ylabel('the number of PS')
xlim([-50, 140])
ylim([0,280])

subplot(3, 3, 3)
list_pc_utility = arrayfun(@(pc) pc.utility, PC_archive);
list_pc_utility = round(list_pc_utility ,3);
histogram(list_pc_utility,numBins)
title('PC utility')
xlabel('PC utility')
ylabel('the number of PC')
xlim([-40, 80])
ylim([0,600])

subplot(3, 3, 4)
list_taxi_utility_inc = arrayfun(@(v) v.incentive, V_archive);
list_taxi_utility_inc = round(list_taxi_utility_inc ,3);
histogram(list_taxi_utility_inc,numBins)
title('incentive of taxi ')
xlabel('incentive')
ylabel('the number of taxies')
xlim([-80, 160])
ylim([0,300])

subplot(3, 3, 5)
ps_utility_list_inc = arrayfun(@(ps) ps.incentive, PS_archive);
ps_utility_list_inc = round(ps_utility_list_inc ,3);
histogram(ps_utility_list_inc,numBins)
title('incentive of PS')
xlabel('incentive')
ylabel('the number of PS')
xlim([-50, 140])
ylim([0,280])

subplot(3, 3, 6)
list_pc_utility_inc = arrayfun(@(pc) pc.incentive, PC_archive);
list_pc_utility_inc = round(list_pc_utility_inc ,3);
histogram(list_pc_utility_inc,numBins)
title('incentive of PC')
xlabel('incentive')
ylabel('the number of PC')
xlim([-40, 80])
ylim([0,600])


subplot(3, 3, 7)
list_inc_taxi_utility = arrayfun(@(v) v.incentived_u, V_archive);
list_inc_taxi_utility = round(list_inc_taxi_utility,3);
histogram(list_inc_taxi_utility,numBins)
title('incentived utility of Taxi')
xlim([-80, 160])
ylim([0,300])

subplot(3, 3, 8)
list_inc_ps_utility = arrayfun(@(ps) ps.incentived_u, PS_archive);
list_inc_ps_utility = round(list_inc_ps_utility,3);
histogram(list_inc_ps_utility,numBins)
title('incentived utility of PS')
xlim([-50, 140])
ylim([0,280])

subplot(3, 3, 9)
list_inc_pc_utility = arrayfun(@(pc) pc.incentived_u, PC_archive);
list_inc_pc_utility = round(list_inc_pc_utility,3);
histogram(list_inc_pc_utility,numBins)
title('incentived utility of PC')
xlim([-40, 80])
ylim([0,600])

