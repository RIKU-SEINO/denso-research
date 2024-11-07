clear
parameter_setting

% ディレクトリのパスを指定
%% EDIT ME! （実行環境によってディレクトリパスを変更する必要がある）%%
% directory_path = "./datasets/ps2pc2_type05";もしMATLABの実行環境がこのディレクトリにある場合はこちらを使う
% それ以外の場合は以下のように自分の環境に合わせて設定する
directory_path = "/Users/rikuseino/Downloads/東京工業大学/denso-research/dev/datasets/ps2pc2_type05";
%% END OF EDIT ME! %%

% 指定したディレクトリ内の.matファイルの情報を取得
mat_files_info = dir(fullfile(directory_path, '*.mat'));

% .matファイルの数を取得
num_mat_files = length(mat_files_info);

% .matファイルを順番に読み込み
for i = 6
    % .matファイルの絶対パスを取得
    mat_file_path = fullfile(directory_path, mat_files_info(i).name);

    % .matファイルを読み込み
    load(mat_file_path);

    % ここで読み込んだデータに対する処理を行う（例: loaded_data.variable_name）

    main_exit

end