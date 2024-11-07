function field_plotter(Players_record,M_record,n_iter)

    field_size = 6;
    % 初期パラメータ
    defaultParameter = 1;

    % メインフィギュアの作成
    fig = figure();
    
    pbaspect([1,1,1])


    % スライダーの作成
    slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', n_iter, 'Value', defaultParameter, ...
        'Units', 'normalized', 'Position', [0.1, 0.05, 0.8, 0.05], 'Callback', @updatePlot, ...
        'SliderStep',[1/(n_iter-1),1/(n_iter-1)]);

    % 初回のプロット
    updatePlot();

    % プロット更新のコールバック関数
    function updatePlot(~, ~)
        % スライダーの値を取得
        iter = floor(slider.Value);

        V_list = Players_record{iter,1};
        PS_list = Players_record{iter,2};
        PC_list = Players_record{iter,3};
        

        % グラフのプロットまたは更新
        if isgraphics(fig, 'figure')

            hold off;
            plot([1,1])
            hold on;
            for i = 1:field_size
                plot([i,i],[1,field_size],'Color',"#7d7d7d")
                plot([1,field_size],[i,i],'Color',"#7d7d7d")
            end
            axis([0.5, field_size+0.5, 0.5, field_size+0.5])

            display_field(V_list, PS_list, PC_list, field_size)
            title(['time index: ' num2str(iter)]);

        end
    end
end

