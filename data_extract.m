list_taxi_utility = arrayfun(@(v) v.utility, V_archive);
ps_waittime_list = arrayfun(@(ps) ps.t_m - ps.t0, PS_archive);
pc_waittime_list = arrayfun(@(pc) pc.t_m - pc.t0, PC_archive);
list_operation_length = arrayfun(@(v) v.operation_remained, V_archive);
list_ps_utility = arrayfun(@(ps) ps.utility, PS_archive);
list_pc_utility = arrayfun(@(pc) pc.utility, PC_archive);

avg_uv = mean(list_taxi_utility)
avg_ups = mean(list_ps_utility);
avg_upc = mean(list_pc_utility);
avg_dist = mean(list_operation_length)
avg_ps_wait = mean(ps_waittime_list)
avg_pc_wait = mean(pc_waittime_list)
mix_ps = timeline_mixed_ratio(end,1)
mix_pc = timeline_mixed_ratio(end,2)

sum_utility = sum(list_taxi_utility)+sum(list_ps_utility)+sum(list_pc_utility)

