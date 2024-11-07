% 座標軸の生成
[x, y] = meshgrid(1:5, 1:5);

% 格子点をプロット
scatter(x(:), y(:), 'k', 'filled') 
hold on

% 特定の格子点を赤くプロット
scatter(x(2,4), y(2,4), 'r', 'filled')

% 罫線を引く
for i = 1:5
    plot([i, i], [1, 5], 'k')  % 垂直線
    plot([1, 5], [i, i], 'k')  % 水平線
end

% 軸の範囲とラベルを設定
axis([0.5 5.5 0.5 5.5])
xlabel('X')
ylabel('Y')
title('5x5 Grid')

% 格子点と罫線が見えるように軸を調整
set(gca,'XTick',1:5,'YTick',1:5,...
        'XTickLabel',[],'YTickLabel',[],...
        'XGrid','off','YGrid','off')

axis square

% 各格子点にテキストを表示 (ただし赤くプロットした点は除く)
index = 1;
for i = 1:size(x, 1)
    for j = 1:size(x, 2)
        if i ~= 2 || j ~= 4  % (3,3)の位置を除く
            text(x(i,j)+0.2, y(i,j)+0.2, '1/24', 'Color', 'k')
            index = index + 1;
        end
    end
end