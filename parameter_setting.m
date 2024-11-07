clear

% parameter setting
t0_max = 300;
timewindow_width = 1;

length_of_grid = 6; %長方形でもできるように
n_taxi = 20;
n_exp_ps = 2;
n_exp_pc = 2;

% utility function parameter
global unit_cost unit_fare_ps unit_fare_pc w_ps w_pc alpha_u_ps alpha_u_ps_1;
unit_cost = 100;
unit_fare_ps = 150;
unit_fare_pc = 120;
w_ps = 60;
w_pc = 30;
alpha_u_ps = 1;
alpha_u_ps_1 = 2;
