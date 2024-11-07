clear
for i = 6
    filename = strcat("./datasets/ps2pc2_3000/",num2str(i));

    seed = rng;
    
    % parameter setting
    n_iterations = 3000;
    
    length_of_grid = 6; %長方形でもできるように
    n_taxi = 50;
    n_exp_ps = 2;
    n_exp_pc = 2;
    
    % define probability
    prob_ps_o = prob_origin_flat(length_of_grid,n_exp_ps); % 要修正：確率が1を超えることがある
    prob_pc_o = prob_origin_flat(length_of_grid,n_exp_pc);
    prob_ps_d = @(x,y) prob_destination(length_of_grid,x,y);
    prob_pc_d = @(x,y) prob_destination(length_of_grid,x,y);

    %type
    prob_type=0.5;
    
    %main
    
    V_dataset = repmat(Taxi, n_taxi+1,1);
    V_dataset(1).id = 0; % void taxi
    for i = 1:n_taxi
        V_dataset(i+1).id = i;
        V_dataset(i+1).x = randi(length_of_grid);
        V_dataset(i+1).y = randi(length_of_grid);
        V_dataset(i+1).operation_remained = floor((i-1)/3);
    end
    
    % generate array
    PS_dataset = Passenger;
    PS_dataset.id = 0;
    PS_dataset.t0 = 0;
    ps_id_max = 0;
    PC_dataset = Package;
    PC_dataset.id = 0;
    PC_dataset.t0 = 0;
    pc_id_max = 0;
    
    for t0 = 1:n_iterations
    % generate ps and pc
        [new_PS, ps_id_max] = generate_customer(prob_ps_o,prob_ps_d,Passenger,ps_id_max,t0);
        %[new_PS, ps_id_max] = generate_customer_with_type(prob_ps_o,prob_ps_d,Passenger,ps_id_max,t0,prob_type);
        PS_dataset = [PS_dataset; new_PS];
        [new_PC, pc_id_max] = generate_customer(prob_pc_o,prob_pc_d,Package,pc_id_max,t0);
        PC_dataset = [PC_dataset; new_PC];
    end
    
    clearvars("pc_id_max","ps_id_max","new_PS","new_PC","t0","i","n_taxi","n_iterations")
    %t0 = 10;
    %PS_dataset(cell2mat(arrayfun(@(ps) ps.t0 == t0, PS_dataset,UniformOutput=false)))
    save(strcat(filename,'.mat'))
end
