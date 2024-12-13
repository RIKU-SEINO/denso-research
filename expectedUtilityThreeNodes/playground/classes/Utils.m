classdef Utils
  methods (Static)
    function writeTxtFile(fileName, content)
      %% EDIT ME! （実行環境によってディレクトリパスを変更する必要がある）%%
      % directoryPath = "./expectedUtilityThreeNodes/playground/data";もしMATLABの実行環境がこのディレクトリにある場合はこちらを使う
      % それ以外の場合は以下のように自分の環境に合わせて設定する
      directoryPath = '/Users/rikuseino/Downloads/東京工業大学/denso-research/dev/expectedUtilityThreeNodes/playground/data';
      %% END OF EDIT ME! %%

      % パスを生成
      filePath = fullfile(directoryPath, strcat(fileName, '.txt'));
      
      % ファイルを開く
      [fileID, errMsg] = fopen(filePath, 'w');
      if fileID == -1
        error('ファイルを開けませんでした: %s', errMsg);
      end
      
      % ファイルを閉じるためのクリーンアップオブジェクトを作成
      cleaner = onCleanup(@() fclose(fileID));
      
      % 内容を書き込む（改行文字を正しく処理）
      fprintf(fileID, '%s\n', content);
    end
  end
end

