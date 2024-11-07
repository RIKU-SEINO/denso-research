PS_index_to_pop = [];
PC_index_to_pop = [];

for triplet = 1:length(V_list)*length(PS_list)*length(PC_list)
    V_index = ceil(triplet/length(PS_list)/length(PC_list));
    PS_index = ceil((triplet-(V_index-1)*length(PS_list)*length(PC_list))/length(PC_list));
    PC_index = mod(triplet-1,length(PC_list)) + 1;

    if M_opt(V_index,PS_index,PC_index) == 1
        if V_index ~= 1
            V_list_all(V_list(V_index).id + 1).operation_remained = T_taxi(V_index,PS_index,PC_index);
            V_list_all(V_list(V_index).id + 1).utility = U_taxi(V_index,PS_index,PC_index);
%             %incentive
%             V_list_all(V_list(V_index).id + 1).incentived_u = U_taxi(V_index,PS_index,PC_index)+inc_U_v_opt(V_index,PS_index,PC_index);
%             V_list_all(V_list(V_index).id + 1).incentive =inc_U_v_opt(V_index,PS_index,PC_index);

            if PS_index ~= 1 || PC_index ~= 1
                V_archive = [V_archive, V_list_all(V_list(V_index).id + 1)];
            end
            %ブロッキングペアを検出
            if 0%PS_index * PC_index > 1
                if U_taxi(V_index,PS_index,PC_index)<U_taxi(V_index,PS_index,1) && U_ps(V_index,PS_index,PC_index)<U_ps(V_index,PS_index,1);
                    iter,V_list(V_index),PS_list(PS_index),PC_list(PC_index)
                    hold off;
                    plot([1,1])
                    hold on;
                    for i = 1:6
                        plot([i,i],[1,6],'Color',"#7d7d7d")
                        plot([1,6],[i,i],'Color',"#7d7d7d")
                    end
                    axis([0.5, 6+0.5, 0.5, 6+0.5])
                    %display_field(V_list(V_index),PS_list(PS_index),PC_list(PC_index),6)
                end
            end

            if PS_index ~= 1
                V_list_all(V_list(V_index).id + 1).x = PS_list(PS_index).x_d;
                V_list_all(V_list(V_index).id + 1).y = PS_list(PS_index).y_d;
                PS_list(PS_index).utility = U_ps(V_index,PS_index,PC_index);
%                 %inc
%                 PS_list(PS_index).incentived_u = U_ps(V_index,PS_index,PC_index)+inc_U_ps_opt(V_index,PS_index,PC_index);
%                 PS_list(PS_index).incentive = inc_U_ps_opt(V_index,PS_index,PC_index);

                PS_list(PS_index).t_m = t0;
                if PC_index == 1
                    PS_list(PS_index).is_mixed = 0;
                else
                    PS_list(PS_index).is_mixed = 1;
                end
                PS_archive = [PS_archive, PS_list(PS_index)];
                PS_index_to_pop = [PS_index_to_pop, PS_index];
            end
            if PC_index ~= 1
                V_list_all(V_list(V_index).id + 1).x = PC_list(PC_index).x_d;
                V_list_all(V_list(V_index).id + 1).y = PC_list(PC_index).y_d;
                PC_list(PC_index).utility = U_pc(V_index,PS_index,PC_index);
%                 %inc
%                 PC_list(PC_index).incentived_u = U_pc(V_index,PS_index,PC_index)+inc_U_pc_opt(V_index,PS_index,PC_index);
%                 PC_list(PC_index).incentive = inc_U_pc_opt(V_index,PS_index,PC_index);
                
                PC_list(PC_index).t_m = t0;
                if PS_index == 1
                    PC_list(PC_index).is_mixed = 0;
                else
                    PC_list(PC_index).is_mixed = 1;
                end

                PC_archive = [PC_archive, PC_list(PC_index)];
                PC_index_to_pop = [PC_index_to_pop, PC_index];
            end
            if PS_index ~= 1 && PC_index ~= 1 && Drop_pc_first(V_index,PS_index,PC_index)
                V_list_all(V_list(V_index).id + 1).x = PS_list(PS_index).x_d;
                V_list_all(V_list(V_index).id + 1).y = PS_list(PS_index).y_d;
            end
        end
        
    end
    
end
PS_list(PS_index_to_pop) = [];
PC_list(PC_index_to_pop) = [];