function display_field(V_list, PS_list, PC_list, field_size)

for v = reshape(V_list,1,[])
    if v.id == 0
        continue
    end
    plot(v.x,v.y,'ob')
    point_name = "v" + num2str(v.id);
    text(v.x+0.1,v.y-0.1, point_name,'Interpreter','tex','Color','b')
end

for ps = reshape(PS_list,1,[])
    if ps.id == 0
        continue
    end
    plot(ps.x_o,ps.y_o,'or')
    point_name = "ps" + num2str(ps.id) + "_o";
    text(ps.x_o+0.1,ps.y_o+0.1, point_name,'Interpreter','tex','Color','r')

    plot(ps.x_d,ps.y_d,'xr')
    point_name = "ps" + num2str(ps.id) + "_d";
    text(ps.x_d+0.1,ps.y_d+0.1, point_name,'Interpreter','tex','Color','r')
end

for pc = reshape(PC_list,1,[])
    if pc.id == 0
        continue
    end
    plot(pc.x_o,pc.y_o,'o','Color',"#7E2F8E")
    point_name = "pc" + num2str(pc.id) + "_o";
    text(pc.x_o-0.2,pc.y_o-0.2, point_name,'Interpreter','tex','Color',"#7E2F8E")

    plot(pc.x_d,pc.y_d,'x','Color',"#7E2F8E")
    point_name = "pc" + num2str(pc.id) + "_d";
    text(pc.x_d-0.2,pc.y_d-0.2, point_name,'Interpreter','tex','Color',"#7E2F8E")
end
end