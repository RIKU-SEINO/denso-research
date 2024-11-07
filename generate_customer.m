function [Customer_list,id_max] = generate_customer(prob_o,prob_d,customer_class,id,t0)
node_size = size(prob_o);
Customer_list = [];
for x_o = 1:node_size(1)
    for y_o = 1:node_size(2)
        if rand < prob_o(x_o,y_o)
            Customer_tmp = customer_class;
            Customer_tmp.id = id+1;
            id = id + 1;
            Customer_tmp.x_o = x_o;
            Customer_tmp.y_o = y_o;
            Customer_tmp.t0 = t0;

            threshold = rand;
            prob_sum = 0;
            prob_distribution = prob_d(x_o,y_o);
            for node_d = 1:node_size(1)*node_size(2)
                x_d = mod(node_d-1, node_size(1))+1;
                y_d = ceil(node_d/node_size(1));
                prob_sum = prob_sum + prob_distribution(x_d,y_d);
                if prob_sum > threshold
                    Customer_tmp.x_d = x_d;
                    Customer_tmp.y_d = y_d;
                    break
                end
            end

            Customer_list = [Customer_list; Customer_tmp];

        end
    end
end
id_max = id;
end