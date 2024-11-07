currentDateTime = datestr(now, 'mmddHHMMSS');
filename = strcat('./results/',currentDateTime);
save(strcat(filename,'.mat'))
saveas(gcf,strcat(filename,'.fig'))