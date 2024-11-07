clear

seed = rng;

% parameter setting
n_iterations = 300;

length_of_grid = 6; %長方形でもできるように
n_taxi = 2;
n_exp_ps = 2;
n_exp_pc = 2;

% define function
prob_ps_o = prob_origin(length_of_grid,n_exp_ps);
prob_pc_o = prob_origin(length_of_grid,n_exp_pc);
prob_ps_d = @(x,y) prob_destination(length_of_grid,x,y);
prob_pc_d = @(x,y) prob_destination(length_of_grid,x,y);
for iter = 1:1000
    V = repmat(Taxi, n_taxi+1,1);
    V(1).id = 0; % void taxi
    for i = 1:n_taxi
        V(i+1).id = i;
        V(i+1).x = randi(length_of_grid);
        V(i+1).y = randi(length_of_grid);
        V(i+1).operation_remained = floor((i-1)/2);
    end
    [PS, ps_id_max] = generate_customer(prob_ps_o,prob_ps_d,Passenger,0,0);
    ps0 = Passenger;
    ps0.id = 0;
    PS = [ps0;PS];
    [PC, pc_id_max] = generate_customer(prob_pc_o,prob_pc_d,Package,0,0);
    pc0 = Package;
    pc0.id = 0;
    PC = [pc0;PC];
    
    % utility function parameter
    global unit_cost unit_fare_ps unit_fare_pc w_ps w_pc alpha_u_ps;
    unit_cost = 100;
    unit_fare_ps = 120;
    unit_fare_pc = 110;
    w_ps = 50;
    w_pc = 50;
    alpha_u_ps = 1;
    
    [U_platform1, U_taxi1, U_ps1, U_pc1, T_taxi1]=make_u_matrices(V,PS,PC,0);
    [M_opt1, u_max1] = triplet_MILP(U_platform1,U_taxi1);
    

    w_pc = 80;
    
    [U_platform2, U_taxi2, U_ps2, U_pc2, T_taxi2]=make_u_matrices(V,PS,PC,0);
    [M_opt2, u_max2] = triplet_MILP(U_platform2,U_taxi2);
    
    if ~isequal(M_opt1,M_opt2)
        disp('found')
        break
    end
end
transform_M(M_opt1)
transform_M(M_opt2)
display_field(V,PS,PC,length_of_grid)