% main_adj
%重みの変更
PS_archive = [];
PC_archive = [];
V_archive = [];

n_iter = floor(t0_max/timewindow_width);

%count
total_adjusted_count = 0;

true_utility = zeros(n_iter,1);

total_n_EBP=0;


% statistics
timeline_n_taxi = zeros(n_iter,1);
timeline_n_ps = zeros(n_iter,1);
timeline_n_pc = zeros(n_iter,1);
timeline_n_new_ps = zeros(t0_max,1);
timeline_n_new_pc = zeros(t0_max,1);
timeline_mixed_ratio = zeros(n_iter,2);
Taxi_location = zeros(length_of_grid,length_of_grid);
Matching_matrix = cell(n_iter,1);
Player_set_record = cell(n_iter,3);
Utility_matrix = cell(n_iter,3);
R = 0;

% generate taxies
V_list_all = V_dataset(1:n_taxi+1);

PS_list = Passenger;
PS_list.id = 0;
ps_id_max = 0;
PC_list = Package;
PC_list.id = 0;
pc_id_max = 0;

tic
% main loop
for iter = 1:n_iter

    % except occupied taxi
    V_list = V_list_all(1);
    for i = 2:length(V_list_all)
        v = V_list_all(i);
        if v.operation_remained < timewindow_width
            V_list = [V_list,v];
        end
        Taxi_location(v.x,v.y) = Taxi_location(v.x,v.y)+1;
    end
    
    for t0 = (iter - 1)*timewindow_width + 1:iter*timewindow_width
    % load new ps and pc
    new_PS = PS_dataset(cell2mat(arrayfun(@(ps) ps.t0 == t0 , PS_dataset,UniformOutput=false)));
    PS_list = [PS_list; new_PS];
    new_PC = PC_dataset(cell2mat(arrayfun(@(pc) pc.t0 == t0, PC_dataset,UniformOutput=false)));
    PC_list = [PC_list; new_PC];

    timeline_n_new_ps(t0) = length(new_PS);
    timeline_n_new_pc(t0) = length(new_PC);

    % record the number of players
    timeline_n_taxi(iter) = length(V_list) - 1;
    timeline_n_ps(iter) = length(PS_list) - 1;
    timeline_n_pc(iter) = length(PC_list) - 1;
    end
    % make utility matrice
    
    [U_platform, U_taxi, U_ps, U_pc, T_taxi, Drop_pc_first] = make_u_matrices(V_list,PS_list,PC_list,iter*timewindow_width);

    Utility_matrix{iter,1} = U_taxi;
    Utility_matrix{iter,2} = U_ps;
    Utility_matrix{iter,3} = U_pc;

    % Adjust U weights
    U_platform1=U_platform;
   [U_ps_adjusted, U_platform_adjusted, adjusted_count1,sigma_factor,adj_w] = adjust_weights(U_platform, U_ps);
   total_adjusted_count = total_adjusted_count + adjusted_count1;
   

    % optimize the matching
    [M_opt, u_max] = triplet_MILP(U_platform,U_platform_adjusted,U_taxi,U_ps_adjusted);
    %[M_opt, u_max] = triplet_MILP_with_variance(U_platform,U_taxi,U_ps);
    Matching_matrix{iter} = M_opt;
    Player_set_record{iter,1} = V_list;
    Player_set_record{iter,2} = PS_list;
    Player_set_record{iter,3} = PC_list;

    %混載かつEBPを検出
    [M_EBP,n_EBP]=mixed_EBP(M_opt,U_taxi,U_ps);
    total_n_EBP=total_n_EBP+n_EBP;

    % Calculate true utility 
    true_utility(iter,1) =sum( U_platform1.* M_opt,"all");

    % process matched players
    process_matched_player

    for i = 2:length(V_list_all)
        if V_list_all(i).operation_remained > 0
            V_list_all(i).operation_remained = max(V_list_all(i).operation_remained - timewindow_width,0);
        end
    end

    ps_is_mixed_list = arrayfun(@(ps) ps.is_mixed, PS_archive);
    pc_is_mixed_list = arrayfun(@(pc) pc.is_mixed, PC_archive);
    timeline_mixed_ratio(iter,:) = [sum(ps_is_mixed_list)/length(PS_archive),sum(pc_is_mixed_list)/length(PC_archive)];
end
toc
currentDateTime = datestr(now, 'mmddHHMMSS');

filename = strcat('./results/',currentDateTime);

clearvars currentDateTime Drop_pc_first i M_opt new_PS new_PC PS_index PC_index PC_index_to_pop PS_index_to_pop t0 pc_id_max ps_id_max 


save(strcat(filename,'.mat'))

%show_result_figure
%saveas(gcf,strcat(filename,'.fig'))
disp(['最終的に調整された回数の合計: ', num2str(total_adjusted_count)]);
disp(['合計の人数: ', num2str(sum(timeline_n_new_ps))]);

total_true_utility = sum(true_utility);

% % Calculate the sum of utility
% ps_utility_list = arrayfun(@(ps) ps.utility, PS_archive);
% list_taxi_utility = arrayfun(@(v) v.utility, V_archive);
% pc_list_utility = arrayfun(@(pc) pc.utility, PC_archive);
% 
% % Calculate the total utility
% total_ps_utility = sum(ps_utility_list);
% total_taxi_utility = sum(list_taxi_utility);
% total_pc_utility = sum(pc_list_utility);
% 
% % Calculate the grand total utility
% total_utility = total_ps_utility + total_taxi_utility + total_pc_utility;
% 


disp(['最終的な真の効用の合計: ', num2str(total_true_utility)]);

% % PS_archiveの各要素の待ち時間を計算
% ps_waittime_list_over_5_steps = arrayfun(@(ps) ps.t_m - ps.t0, PS_archive);
% 
% % 5ステップ以上待ったPSの数を計算
% ps_count_over_5_steps = sum(ps_waittime_list_over_5_steps > 5);
% disp(['5ステップ以上待ったPSの数: ', num2str(ps_count_over_5_steps)]);
% 
% % 10ステップ以上待ったPSの数を計算
% ps_count_over_10_steps = sum(ps_waittime_list_over_5_steps > 10);
% disp(['10ステップ以上待ったPSの数: ', num2str(ps_count_over_10_steps)]);
% 
% disp(['sigma_factor: ', num2str(sigma_factor)]);
% disp(['adj_w: ', num2str(adj_w)]);
% disp(['total_n_EBP: ', num2str(total_n_EBP)]);
