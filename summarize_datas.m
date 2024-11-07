% データの平均値を格納する変数を初期化
timeline_n_taxi = zeros(300,1);
timeline_n_ps = zeros(300,1); 
timeline_n_pc = zeros(300,1);
list_operation_length = [];
timeline_mixed_ratio = zeros(300,2);
ps_utility_list = [];
list_taxi_utility = [];
ps_waittime_list = [];
pc_waittime_list = [];

numFiles = 0;

% ディレクトリのパスを指定
directoryPath = './results/0501/';

% ディレクトリ内の.matファイルを取得
matFiles = dir(fullfile(directoryPath, '*.mat'));

for fileIdx = 1:length(matFiles)
    filename = fullfile(directoryPath, matFiles(fileIdx).name);
    
    % .matファイルを読み込む
    loadedData = load(filename);
    
    data = loadedData.yourVariableName;
    totalData = totalData + data;
    numFiles = numFiles + 1;
    
end

% データの平均値を計算
if numFiles > 0
    meanData = totalData / numFiles;
    disp('データの平均値:');
    disp(meanData);
else
    disp('有効なデータが見つかりませんでした。');
end
