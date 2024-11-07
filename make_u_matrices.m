function [U_platform, U_taxi, U_ps, U_pc, T_taxi, Drop_pc_first] = make_u_matrices(V_list,PS_list,PC_list,t0)

    % void matrix
    U_platform = zeros(length(V_list), length(PS_list), length(PC_list));
    U_taxi = zeros(length(V_list), length(PS_list), length(PC_list));
    U_ps = zeros(length(V_list), length(PS_list), length(PC_list));
    U_pc = zeros(length(V_list), length(PS_list), length(PC_list));
    T_taxi = zeros(length(V_list), length(PS_list), length(PC_list));
    Drop_pc_first= zeros(length(V_list), length(PS_list), length(PC_list));

    % main part
    for triplet = 1:length(V_list)*length(PS_list)*length(PC_list)
        V_index = ceil(triplet/length(PS_list)/length(PC_list));
        PS_index = ceil((triplet-(V_index-1)*length(PS_list)*length(PC_list))/length(PC_list));
        PC_index = mod(triplet-1,length(PC_list)) + 1;

        % calculate the utility of the triplet
         [u_taxi, u_ps, u_pc, t_taxi,drop_pc_first] = utility_triplet(V_list(V_index),PS_list(PS_index),PC_list(PC_index),t0);
%         [u_taxi, u_ps, u_pc, t_taxi,drop_pc_first] = utility_triplet_with_type(V_list(V_index),PS_list(PS_index),PC_list(PC_index),t0);
        
        U_platform(V_index,PS_index,PC_index) = u_taxi + u_ps + u_pc;
        
        U_taxi(V_index,PS_index,PC_index) = u_taxi;
        U_ps(V_index,PS_index,PC_index) = u_ps;
        U_pc(V_index,PS_index,PC_index) = u_pc;
        T_taxi(V_index,PS_index,PC_index) = t_taxi;
        Drop_pc_first(V_index,PS_index,PC_index) = drop_pc_first;
    end
end