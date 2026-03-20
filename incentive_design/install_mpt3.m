%% tbxmanager による MPT 一式（依存サブモジュール含む）のインストール
%

clc;
disp('----------------------------------------------');
disp('Toolbox マネージャを用いた MPT のインストール');
disp('----------------------------------------------');
disp(' ');
fprintf(['Toolbox マネージャをインストールする親フォルダを選んでください。\n',...
      '指定した場所に新しいフォルダ "tbxmanager" が作成されます。\n',...
      'すでに "tbxmanager" がある場合は、クリーンインストールのため完全に削除します。\n',...
      'キャンセルした場合は、現在のフォルダに Toolbox マネージャをインストールします。\n']);

% インストール先の親フォルダ
default_dir = pwd;
c = uigetdir(pwd);
if isequal(c,0);
    fprintf(['フォルダが指定されませんでした。\n',... 
        'Toolbox マネージャを現在のフォルダ "%s" にインストールします。\n'],default_dir);
    c = default_dir;
end
 
% 親フォルダ直下に tbxmanager を作成（既存は削除してから再インストール）
d = [c,filesep,'tbxmanager'];
if isequal(exist(d,'dir'),7)
    disp(['クリーンインストールのため既存の "tbxmanager" を削除します: ', d]);
    try
        rmdir(d, 's');
    catch ME
        error(['既存フォルダ "%s" を削除できませんでした。\n手動で削除するか、別のパスを選んでください。\n%s'], d, ME.message);
    end
    if isequal(exist(d,'dir'),7)
        error('フォルダ "%s" を完全に削除できませんでした。', d);
    end
end
disp('フォルダ "tbxmanager" を作成しています。');
out = mkdir(d);
if ~out
    error(['フォルダ "%s" の作成中にエラーが発生しました。\n',...
          'Toolbox マネージャは手動でインストールしてください。'],d); 
end

cd(d);

% MPT2 や YALMIP など、MPT と競合しうるツールボックスをパスから外す
disp(' ');
disp('MPT と競合しうるツールボックスを MATLAB のパスから削除しています。');
rmpath(genpath(fileparts(which('mpt_init'))));
rmpath(genpath(fileparts(which('yalmipdemo'))));


% Toolbox マネージャをダウンロード
disp(' ');
disp('インターネットから Toolbox マネージャをダウンロードしています。');
[f, dl_ok] = urlwrite('http://www.tbxmanager.com/tbxmanager.m', 'tbxmanager.m');
rehash;

if isequal(dl_ok,0)
    error('Toolbox マネージャをダウンロードできませんでした。インストールを続行できません。');
end

% 必要なモジュールをすべてインストール
tbxmanager install mpt mptdoc cddmex fourier glpkmex hysdel lcp sedumi yalmip 

% パス設定用の初期化ファイル startup.m を作成
disp(' ');
disp('初期化ファイル "startup.m" を作成・更新しています。');
p = which('startup.m');
if isempty(p)
    p = [d,filesep,'startup.m'];
end
fid = fopen(p,'a');
if isequal(fid,-1)
    error(['初期化ファイル "startup.m" を変更できませんでした。',...
           'フォルダ "%s" 内の該当ファイルを手動で開き、次の行を追加してください:  tbxmanager restorepath'],p);
end
fprintf(fid,'tbxmanager restorepath\n');
fclose(fid);
disp('ファイルを更新しました。');

cd(default_dir);

disp(' ');
disp('MATLAB のパスに tbxmanager を追加しています。');
addpath(d);

disp(' ');
disp('今後のセッション用にパスを保存しています。');
status = savepath;

if status
    fprintf('デフォルトの場所にパスを保存できませんでした。\npathdef.m を保存するフォルダを指定してください。');
    cn = uigetdir(pwd);
    if isequal(cn,0)
        disp(' ');
        fprintf('フォルダが指定されなかったため、現在のフォルダ "%s" に pathdef.m を保存します。\n\n',default_dir);
        cn = default_dir;
    end
    sn = savepath([cn,filesep,'pathdef.m']);
    if sn
        error(['パスを自動保存できませんでした。\n',...
            'MATLAB メニューの「パスの設定」から手動でパスを保存してください。']);
    end
end

disp(' ');
disp('インストールが完了しました。');
disp('次回 MATLAB を起動すると、ツールボックスが自動的に初期化されます。');

disp(' ');
disp('MPT を初期化しています。');

% Apple Silicon（arm64）では Intel 用 LCP MEX が動作しないため注意を表示
if ismac
    [~, result] = system('uname -m');
    if contains(result, 'arm64')
        disp(' ');
        disp('=== Apple Silicon Mac をお使いの場合の注意 ===');
        disp('LCPソルバー (lcp.mexmaci64) はIntel Mac用のため動作しません。');
        disp('MPTはLCPソルバーなしでも大部分の機能が使用可能です。');
        disp('「無効な MEX ファイル」エラーが表示されても無視して構いません。');
        disp('================================================');
        disp(' ');
    end
end

try
    mpt_init;
catch ME
    if contains(ME.message, 'lcp') || contains(ME.message, 'MEX')
        disp(' ');
        disp('警告: LCP関連のエラーが発生しましたが、MPTは使用可能です。');
        disp('エラー詳細:');
        disp(ME.message);
    else
        rethrow(ME);
    end
end

disp(' ');
disp('=== インストール後の注意 ===');
disp('「関数または変数 ''y'' が認識されません」というエラーが');
disp('表示される場合がありますが、これは無害なエラーです。');
disp('インストールは正常に完了しています。');
disp('===========================');