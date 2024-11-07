function [u_taxi,u_ps,u_pc,t_taxi,drop_pc_first] = utility_triplet_with_type(taxi,ps,pc,t)
    case_index = (taxi.id ~= 0)*1 + (ps.id ~= 0)*2 + (pc.id ~= 0)*4;

    u_taxi = 0;
    u_ps = 0;
    u_pc = 0;
    t_taxi = 0;
    drop_pc_first = 0;

    switch case_index
        case 0 % taxi, ps, pc are all void
            return
            
        case 1 % taxi isn't void, ps and pc are void
            u_taxi = 0;
            return
            
        case 2 % ps isn't void, taxi and pc are void
            u_ps = 0; % expected utility in the future
            return

        case 4 % pc isn't void, taxi and ps are void
            u_pc = 0; % expected utility in the future
            return

        case 5 % ps is void, taxi and pc are not void
            l_taxi = abs(taxi.x-pc.x_o) + abs(taxi.y-pc.y_o) + abs(pc.x_o-pc.x_d) + abs(pc.y_o-pc.y_d);
            l_pc = abs(pc.x_o-pc.x_d) + abs(pc.y_o-pc.y_d);

            u_taxi = utility_taxi(l_taxi,0,l_pc);
            u_ps = 0;
            u_pc = utility_pc();
            t_taxi = l_taxi;
            return

        case 3 % pc is void, taxi and ps are not void 
            l_taxi = abs(taxi.x-ps.x_o) + abs(taxi.y-ps.y_o) + abs(ps.x_o-ps.x_d) + abs(ps.y_o-ps.y_d);
            l_ps = abs(ps.x_o-ps.x_d) + abs(ps.y_o-ps.y_d);

            u_taxi = utility_taxi(l_taxi,l_ps,0);
            u_ps = utility_ps_with_type(ps,l_taxi,t);
            u_pc = 0;
            t_taxi = l_taxi;
            return

        case 6 % unfeasible: taxi is void, ps and pc are not void
            u_taxi = 0;
            u_ps = 0;
            u_pc = 0;
            return

        case 7 % mixed package-passanger
            u_total = -Inf;
            u_taxi = -Inf;
            u_ps = -Inf;
            u_pc = -Inf;

            x_o_set = [ps.x_o,pc.x_o];
            y_o_set = [ps.y_o,pc.y_o];
            x_d_set = [ps.x_d,pc.x_d];
            y_d_set = [ps.y_d,pc.y_d];
            
            l_ps = abs(ps.x_o-ps.x_d) + abs(ps.y_o-ps.y_d);
            l_pc = abs(pc.x_o-pc.x_d) + abs(pc.y_o-pc.y_d);

            for i=1:2
                for j=1:2
                    l_taxi = abs(taxi.x-x_o_set(i)) + abs(taxi.y-y_o_set(i))  ...
                    + abs(x_o_set(i)-x_o_set(3-i)) + abs(y_o_set(i)-y_o_set(3-i)) ...
                    + abs(x_d_set(j)-x_o_set(3-i)) + abs(y_d_set(j)-y_o_set(3-i)) ...
                    + abs(x_d_set(j)-x_d_set(3-j)) + abs(y_d_set(j)-y_d_set(3-j)) ;
                    u_taxi_tmp = utility_taxi(l_taxi,l_ps,l_pc);
                    l_v_ps = l_taxi;
                    if j == 1
                        l_v_ps = l_taxi - abs(x_d_set(i)-x_d_set(3-i)) - abs(y_d_set(i)-y_d_set(3-i));
                    end
                    if j == 2
                        drop_pc_first = 1;
                    end
                    u_ps_tmp = utility_ps_with_type(ps,l_v_ps,t);
                    u_pc_tmp = utility_pc();
                    if u_taxi_tmp + u_ps_tmp + u_pc_tmp > u_total
                        u_total = u_taxi_tmp + u_ps_tmp + u_pc_tmp;
                        u_taxi = u_taxi_tmp;
                        u_ps = u_ps_tmp;
                        u_pc = u_pc_tmp;
                        t_taxi = l_taxi;
                    end
                end
            end
            return
    
    end
    warning('Cannot calculate the utility')
    return;
end