% main
PS_archive = [];
PC_archive = [];
V_archive = [];

n_iter = floor(t0_max/timewindow_width);

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
incentived_Utility_matrix = cell(n_iter,3);
total_n_ebp=0;
n_ebp=0;
total_mixed_ebp=0;
mixed_ebp=0;
total_ebp_case= zeros(1, 7);
all_total_count=zeros(1, 7);
n_no_inc=0;
R = 0;

% generate taxies
V_list_all = V_dataset(1:n_taxi+1);

PS_list = Passenger;
PS_list.id = 0;
ps_id_max = 0;
PC_list = Package;
PC_list.id = 0;
pc_id_max = 0;

% total_u_max=0;
% total_utility=0;
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
    %U_platform = adjust_weights(U_platform);


    % optimize the matching
    [M_opt, u_max] = triplet_MILP(U_platform,U_platform,U_taxi,U_ps);
    %[M_opt, u_max] = triplet_MILP_with_variance(U_platform,U_taxi,U_ps);
    Matching_matrix{iter} = M_opt;
    Player_set_record{iter,1} = V_list;
    Player_set_record{iter,2} = PS_list;
    Player_set_record{iter,3} = PC_list;

%      %ebp
%      [~,mixed_ebp]=mixed_EBP(M_opt,U_taxi,U_ps,iter);
%     [n_ebp,ebp_case,total_counts]=count_ebp(M_opt, U_taxi, U_ps, U_pc);
%     total_mixed_ebp=total_mixed_ebp+mixed_ebp;
%     total_n_ebp=total_n_ebp+n_ebp;
%     total_ebp_case=total_ebp_case+ebp_case;
%     all_total_count=all_total_count+total_counts;

%     total_u_max = total_u_max+u_max;
%     %total_utility=total_utility+sum(M_opt.* U_platform,"all");

%     %incentive
%     [inc_U_v_opt,inc_U_ps_opt,inc_U_pc_opt,incentives]=optimize_incentives_5(M_opt,U_taxi,U_ps,U_pc);
% 
%     incentived_Utility_matrix{iter,1} = U_taxi+inc_U_v_opt;
%     incentived_Utility_matrix{iter,2} = U_ps+inc_U_ps_opt;
%     incentived_Utility_matrix{iter,3} = U_pc+inc_U_pc_opt;
 

%     if incentives==0
%         n_no_inc=n_no_inc+1;
%     end

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
     disp(iter)
end
toc
currentDateTime = datestr(now, 'mmddHHMMSS');

filename = strcat('./results/',currentDateTime);

clearvars currentDateTime Drop_pc_first i M_opt new_PS new_PC PS_index PC_index PC_index_to_pop PS_index_to_pop t0 pc_id_max ps_id_max 


save(strcat(filename,'.mat'))

% disp(total_n_ebp)
% for i=1:7
%     disp(total_ebp_case(i))
% end
% 
% disp(total_mixed_ebp)
% 
% disp(n_no_inc)

%disp(num2str(total_u_max))
%disp(num2str(total_utility))

%show_result_figure
%saveas(gcf,strcat(filename,'.fig'))
