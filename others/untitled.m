clear

taxi = randi(10,2,2);
ps_o = randi(10,2,2);
ps_d = randi(10,2,2);
pc_o = randi(10,2,2);
pc_d = randi(10,2,2);

figure
hold on
grid on

scatter(taxi(1,:),taxi(2,:),"black","x")
scatter(ps_o(1,:),ps_o(2,:),"blue","x")
scatter(ps_d(1,:),ps_d(2,:),"blue","o")
scatter(pc_o(1,:),pc_o(2,:),"red","x")
scatter(pc_d(1,:),pc_d(2,:),"red","o")

text(taxi(1,:), taxi(2,:), string(1:size(taxi,2)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Color', 'black')
text(ps_o(1,:), ps_o(2,:), string(1:size(ps_o,2)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Color', 'blue')
text(ps_d(1,:), ps_d(2,:), string(1:size(ps_d,2)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Color', 'blue')
text(pc_o(1,:), pc_o(2,:), string(1:size(pc_o,2)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Color', 'red')
text(pc_d(1,:), pc_d(2,:), string(1:size(pc_o,2)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', 'Color', 'red')

xlim([0,11])
ylim([0,11])