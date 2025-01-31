function mat = generateExpectedUtilitiesSymbolicMatrix() 
    players = {'v1', 'ps1', 'v2', 'ps2', 'v3', 'ps3'};
    mat = sym(zeros(64, 6));
    for s = 1:64
        for playerIndex = 1:6
            % 動的にシンボリック変数名を作成
            varName = sprintf('x_%s_%d', players{playerIndex}, s-1);
            
            % 配列にシンボリック変数を格納
            mat(s, playerIndex) = sym(varName);
        end
    end
end