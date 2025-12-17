classdef ConstraintVisualizer
  % ConstraintVisualizer 線形制約領域の可視化クラス (Final Complete Version)
  %
  % Features:
  %   - 3平面交差法による厳密な領域描画 (3D)
  %   - 目的関数によるグラデーション/等高線表示
  %   - メッシュ細分化による高精細描画 (2D/3D両対応)
  %   - 線分退化時のグラデーション描画対応 (2D)

  properties (Access = public)
    A_eq double           % 等式制約の係数行列
    b_eq double           % 等式制約の定数項
    IneqSets struct       % 構造体配列: .A (不等式制約の係数行列), .b (不等式制約の定数項)
    Defaults double       % デフォルト値
    NumVars int32         % 変数の数
    
    % --- Visualization Settings ---
    
    % 目的関数 (例: @(x) log10(sum(x.^2, 2)))
    % 設定時はグラデーション、空の場合は UnifiedColor を使用
    ObjectiveFunction function_handle = function_handle.empty;
  end

  properties (Access = private)
    ViewListener  % 視点変更リスナー
  end

  methods (Access = public)
    function obj = ConstraintVisualizer(n, defaults)
      obj.NumVars = n;
      obj.Defaults = defaults(:);
      obj.A_eq = zeros(0, n);
      obj.b_eq = zeros(0, 1);
      obj.IneqSets = struct('A', {}, 'b', {});
    end

    function obj = setEquality(obj, A, b)
      obj.A_eq = A;
      obj.b_eq = b(:);
    end

    function obj = addInequalitySet(obj, A, b)
      idx = length(obj.IneqSets) + 1;
      obj.IneqSets(idx).A = A;
      obj.IneqSets(idx).b = b(:);
    end

    function plot(obj, viewDims, varargin)
      % メイン描画メソッド
      % オプション引数:
      %   'Title' - グラフタイトル
      %   'XLabel', 'YLabel', 'ZLabel' - 軸ラベル
      %   'XLim', 'YLim', 'ZLim' - 軸範囲
      %   'ColorbarWidth' - カラーバーの幅
      %   'ColorbarLabel' - カラーバーラベル
      %   'FontName' - フォント名
      %   'FontSize' - フォントサイズ
      %   'TitleFontSize' - タイトルフォントサイズ
      
      obj.validateDims(viewDims);
      options = obj.parseOptions(viewDims, varargin{:});
      obj.setupFigure(viewDims, options);

      for i = 1:length(obj.IneqSets)
        % 1. 射影 (Project)
        [A_sub, b_sub, A_eq_sub, b_eq_sub] = obj.projectConstraints(obj.IneqSets(i), viewDims);

        % 2. 描画 (Draw)
        if length(viewDims) == 2
          obj.drawRegion2D(A_sub, b_sub, A_eq_sub, b_eq_sub, options);
        else
          obj.drawRegion3D(A_sub, b_sub, A_eq_sub, b_eq_sub, options);
        end
      end

      % Defaultsの点をプロット（必要な場合のみ）
      pointHandle = [];
      if options.PlotDefaultPoint
        pointHandle = obj.plotDefaultPoint(viewDims, options);
      end

      obj.finalizeFigure(viewDims, pointHandle, options);
    end

    function filepath = save(~, varargin)
      % 現在の Figure を .fig として保存する
      %
      % Args:
      %   BaseName (char): 拡張子なしのファイル名
      %   Directory (char): 保存先ディレクトリ（例: 'result/fig'）
      %   FigureHandle (matlab.ui.Figure): 保存対象の Figure（省略時は gcf）
      %
      % Returns:
      %   filepath (char): 保存した .fig のパス
      p = inputParser;
      addParameter(p, 'BaseName', '', @ischar);
      addParameter(p, 'Directory', '', @ischar);
      addParameter(p, 'FigureHandle', [], @(h) isempty(h) || ishghandle(h));
      parse(p, varargin{:});
      opts = p.Results;

      if isempty(opts.BaseName)
        error('BaseName を指定してください（例: viz.save(''BaseName'',''pi_8_bp_positive_cons_fixed_value_projection'')）');
      end

      fig = opts.FigureHandle;
      if isempty(fig)
        fig = gcf;
      end

      outDir = opts.Directory;
      if isempty(outDir)
        outDir = pwd;
      end
      if ~exist(outDir, 'dir')
        mkdir(outDir);
      end

      filepath = fullfile(outDir, [opts.BaseName, '.fig']);
      savefig(fig, filepath);
    end
  end

  %% --- Private Methods: 3D Logic ---
  methods (Access = private)
    
    function drawRegion3D(obj, A, b, A_eq, b_eq, options)
      % 1. 制約平面の収集
      [Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq] = ...
          obj.collectPlanes(A, b, A_eq, b_eq, options);

      % 2. 頂点計算 (3平面交差全探索)
      verts = obj.computeVertices3D(Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq);

      % 3. 形状生成と描画
      if ~isempty(verts)
        obj.renderShape3D(verts, options);
      end
    end

    function verts = computeVertices3D(~, Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq)
      verts = [];
      numPlanes = length(Planes_b);
      combs = nchoosek(1:numPlanes, 3);
      tol = 1e-5;

      for k = 1:size(combs, 1)
        idx = combs(k, :);
        subA = Planes_A(idx, :);
        subb = Planes_b(idx);

        if rcond(subA) < 1e-10, continue; end
        pt = (subA \ subb)';

        if any(Check_A * pt' > Check_b + tol), continue; end
        if ~isempty(Check_A_eq)
          if any(abs(Check_A_eq * pt' - Check_b_eq) > tol), continue; end
        end
        verts = [verts; pt]; %#ok<AGROW>
      end
      
      if ~isempty(verts)
        verts = uniquetol(verts, 1e-4, 'ByRows', true);
      end
    end

    function renderShape3D(obj, verts, options)
      hold on;
      if size(verts, 1) < 3, return; end

      % 1. 初期メッシュ生成
      try
        faces = convhull(verts(:, 1), verts(:, 2), verts(:, 3));
      catch
        % 平面退化時のフォールバック
        center = mean(verts, 1);
        coords_shifted = verts - center;
        [~, ~, V_axis] = svd(coords_shifted, 0);
        coords_2d = coords_shifted * V_axis(:, 1:2);
        try
          faces = delaunay(coords_2d(:,1), coords_2d(:,2));
        catch
          return; 
        end
      end
      
      if isempty(faces), return; end

      % 2. メッシュ細分化
      [verts_refined, faces_refined] = obj.refineMesh(verts, faces, 3);
      
      % 3. 色属性決定
      [cData, faceColor, faceAlpha] = obj.determineColorAttributes(verts_refined, options);
      
      % 4. 描画
      trisurf(faces_refined, ...
              verts_refined(:, 1), verts_refined(:, 2), verts_refined(:, 3), ...
              cData, ...
              'FaceColor', faceColor, ...
              'FaceAlpha', faceAlpha, ...
              'EdgeColor', 'none');
    end
  end

  %% --- Private Methods: 2D Logic ---
  methods (Access = private)
    
    function drawRegion2D(obj, A, b, A_eq, b_eq, options)
      if ~isempty(A_eq)
        A = [A; A_eq; -A_eq];
        b = [b; b_eq; -b_eq];
      end

      verts = obj.computeVertices2D(A, b, options);

      if ~isempty(verts)
        obj.renderShape2D(verts, options);
      end
    end

    function verts = computeVertices2D(~, A, b, options)
      verts = [];
      linprog_options = optimoptions('linprog', 'Display', 'off', 'Algorithm', 'dual-simplex');
      lb = -options.Bounds * ones(2, 1); 
      ub =  options.Bounds * ones(2, 1);

      thetas = linspace(0, 2*pi, 60)';
      directions = [cos(thetas), sin(thetas); 1 1; 1 -1; -1 1; -1 -1];

      for k = 1:size(directions, 1)
        try
          [x, ~, exitflag] = linprog(-directions(k, :), A, b, [], [], lb, ub, linprog_options);
          if exitflag == 1, verts = [verts; x']; end %#ok<AGROW>
        catch
        end
      end
      if ~isempty(verts), verts = uniquetol(verts, 1e-5, 'ByRows', true); end
    end

    function renderShape2D(obj, verts, options)
      [cData, ~, faceAlpha] = obj.determineColorAttributes(verts, options);
      nVerts = size(verts, 1);
      useGradient = ~isempty(cData);
      
      if nVerts >= 3
        try
          % 多角形として描画
          % patchを使うため、線形補間で色がつくように頂点順序を整える
          k = convhull(verts(:, 1), verts(:, 2));
          
          % NOTE: 多角形の内部まで滑らかにしたい場合はDelaunay+Refineが必要だが
          % 2Dのfill/patchは頂点カラー補間が効くため、まずはこれで対応
          if useGradient
            patch('Vertices', verts, 'Faces', k, 'FaceVertexCData', cData, ...
                  'FaceColor', 'interp', 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
          else
            fill(verts(k, 1), verts(k, 2), options.UnifiedColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
          end
        catch
          % convhull失敗時は線分とみなす
          obj.drawGradientLine(verts, useGradient, options);
        end
      elseif nVerts == 2
        % 線分
        obj.drawGradientLine(verts, useGradient, options);
      elseif nVerts == 1
        % 点
        color = options.UnifiedColor;
        if useGradient, color = cData; end
        scatter(verts(:, 1), verts(:, 2), 50, color, 'filled', 'MarkerEdgeColor', 'k');
      end
    end

    function drawGradientLine(obj, verts, useGradient, options)
        % 線分を細分化してグラデーション描画する
        [~, idx] = sortrows(verts); 
        sortedVerts = verts(idx, :);
        
        ptStart = sortedVerts(1, :);
        ptEnd   = sortedVerts(end, :);
        
        if useGradient
            % 線分を100分割して色を計算
            t = linspace(0, 1, 100)';
            fineVerts = ptStart + (ptEnd - ptStart) .* t;
            cDataFine = obj.ObjectiveFunction(fineVerts);
            
            % surface関数で色付き線を描画 (EdgeColor='interp')
            surface([fineVerts(:,1) fineVerts(:,1)], ...
                    [fineVerts(:,2) fineVerts(:,2)], ...
                    zeros(size(fineVerts,1), 2), ...
                    [cDataFine cDataFine], ...
                    'FaceColor', 'none', 'EdgeColor', 'interp', 'LineWidth', 2);
        else
            plot([ptStart(1) ptEnd(1)], [ptStart(2) ptEnd(2)], ...
                 'Color', options.UnifiedColor, 'LineWidth', 2);
        end
    end
  end

  %% --- Private Methods: Point Plotting ---
  methods (Access = private)
    
    function h = plotDefaultPoint(obj, viewDims, options)
      % Defaultsの点を射影して描画
      point_projected = obj.Defaults(viewDims);
      
      if length(viewDims) == 2
        h = scatter(point_projected(1), point_projected(2), ...
                    options.DefaultPointSize, options.DefaultPointColor, ...
                    'filled', ...
                    'Marker', options.DefaultPointMarker, ...
                    'MarkerEdgeColor', options.DefaultPointEdgeColor, ...
                    'LineWidth', options.DefaultPointLineWidth);
      else
        h = scatter3(point_projected(1), point_projected(2), point_projected(3), ...
                     options.DefaultPointSize, options.DefaultPointColor, ...
                     'filled', ...
                     'Marker', options.DefaultPointMarker, ...
                     'MarkerEdgeColor', options.DefaultPointEdgeColor, ...
                     'LineWidth', options.DefaultPointLineWidth);
      end
      
      % UserDataに元の座標を保存
      set(h, 'UserData', struct('FullDimPoint', obj.Defaults, 'ViewDims', viewDims));
    end
    
    function txt = dataCursorUpdateFcn(obj, event_obj, viewDims)
      % データカーソルのカスタム表示関数
      pos = get(event_obj, 'Position');
      
      % 表示テキストの構築
      txt = cell(length(viewDims) + 1, 1);
      for i = 1:length(viewDims)
        txt{i} = sprintf('x_{%d}: %.4f', viewDims(i), pos(i));
      end
      
      % 目的関数値の表示(設定されている場合)
      if ~isempty(obj.ObjectiveFunction)
        objValue = obj.ObjectiveFunction(obj.Defaults');
        txt{end} = sprintf('Objective: %.4f', objValue);
      else
        txt = txt(1:end-1);  % 目的関数がない場合は最後の行を削除
      end
    end
  end

  %% --- Private Methods: Utilities ---
  methods (Access = private)
    
    function options = parseOptions(~, viewDims, varargin)
      % オプション引数のパース
      p = inputParser;
      
      % デフォルトのラベルとタイトル
      default_title = sprintf('%dD Slice Visualization (Dims: %s)', length(viewDims), mat2str(viewDims));
      default_xlabel = sprintf('x_{%d}', viewDims(1));
      default_ylabel = sprintf('x_{%d}', viewDims(2));
      if length(viewDims) == 3
        default_zlabel = sprintf('x_{%d}', viewDims(3));
      else
        default_zlabel = '';
      end
      
      % デフォルト値
      default_bounds = 100;
      default_unified_color = [0, 0.4470, 0.7410];
      default_contour_levels = 20;
      
      % パラメータ定義
      addParameter(p, 'Title', default_title, @ischar);
      addParameter(p, 'XLabel', default_xlabel, @ischar);
      addParameter(p, 'YLabel', default_ylabel, @ischar);
      addParameter(p, 'ZLabel', default_zlabel, @ischar);
      addParameter(p, 'XLim', [-default_bounds, default_bounds], @(x) isnumeric(x) && length(x) == 2);
      addParameter(p, 'YLim', [-default_bounds, default_bounds], @(x) isnumeric(x) && length(x) == 2);
      addParameter(p, 'ZLim', [-default_bounds, default_bounds], @(x) isnumeric(x) && length(x) == 2);
      addParameter(p, 'Bounds', default_bounds, @isnumeric);  % 内部計算用
      addParameter(p, 'ColorbarWidth', [], @(x) isempty(x) || isnumeric(x));
      addParameter(p, 'ColorbarLabel', 'Objective Value', @ischar);
      addParameter(p, 'ColorbarLimits', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));  % カラーバーの数値範囲 [min, max]
      addParameter(p, 'FontName', 'Times New Roman', @ischar);
      addParameter(p, 'FontSize', 18, @isnumeric);
      addParameter(p, 'TitleFontSize', 20, @isnumeric);
      addParameter(p, 'UnifiedColor', default_unified_color, @(x) isnumeric(x) && length(x) == 3);
      addParameter(p, 'ContourLevels', default_contour_levels, @isnumeric);
      
      % Defaults点（最適解のマーク）設定
      addParameter(p, 'PlotDefaultPoint', true, @islogical);
      addParameter(p, 'DefaultPointMarker', 'o', @ischar);
      addParameter(p, 'DefaultPointSize', 120, @isnumeric);
      addParameter(p, 'DefaultPointColor', 'r'); % MATLAB ColorSpec
      addParameter(p, 'DefaultPointEdgeColor', 'k'); % MATLAB ColorSpec
      addParameter(p, 'DefaultPointLineWidth', 2.0, @isnumeric);
      addParameter(p, 'DefaultPointAlwaysOnTop', false, @islogical);
      addParameter(p, 'DefaultPointDepthOffset', [], @(x) isempty(x) || isnumeric(x));
      
      % ラベル位置調整用オプション
      addParameter(p, 'XLabelPosition', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 3));
      addParameter(p, 'YLabelPosition', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 3));
      addParameter(p, 'ZLabelPosition', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 3));
      addParameter(p, 'XLabelRotation', [], @(x) isempty(x) || isnumeric(x));
      addParameter(p, 'YLabelRotation', [], @(x) isempty(x) || isnumeric(x));
      addParameter(p, 'ZLabelRotation', [], @(x) isempty(x) || isnumeric(x));
      
      % 動的ラベル位置更新
      addParameter(p, 'AutoUpdateLabelPosition', false, @islogical);
      addParameter(p, 'LabelOffset', 0, @isnumeric);
      
      parse(p, varargin{:});
      options = p.Results;
    end
      
    function [newVerts, newFaces] = refineMesh(~, verts, faces, iterations)
      % 共通メッシュ細分化ロジック
      newVerts = verts;
      newFaces = faces;
      edgeMap = []; 
      tempNewVerts = [];
      nextVertIdx = 0;

      for iter = 1:iterations
        nF = size(newFaces, 1);
        nV = size(newVerts, 1);
        nextFaces = zeros(nF * 4, 3);
        
        edgeMap = containers.Map('KeyType', 'char', 'ValueType', 'double');
        tempNewVerts = [];
        nextVertIdx = nV + 1;
        
        for i = 1:nF
          v1 = newFaces(i, 1);
          v2 = newFaces(i, 2);
          v3 = newFaces(i, 3);
          m1 = getMidPoint(v1, v2);
          m2 = getMidPoint(v2, v3);
          m3 = getMidPoint(v3, v1);
          
          baseIdx = (i-1)*4;
          nextFaces(baseIdx+1, :) = [v1, m1, m3];
          nextFaces(baseIdx+2, :) = [v2, m2, m1];
          nextFaces(baseIdx+3, :) = [v3, m3, m2];
          nextFaces(baseIdx+4, :) = [m1, m2, m3];
        end
        
        if ~isempty(tempNewVerts)
            newVerts = [newVerts; tempNewVerts]; %#ok<AGROW>
        end
        newFaces = nextFaces;
      end

      % Nested helper
      function [midIdx] = getMidPoint(idxA, idxB)
         if idxA < idxB, key = sprintf('%d_%d', idxA, idxB);
         else,           key = sprintf('%d_%d', idxB, idxA); end
         
         if isKey(edgeMap, key)
             midIdx = edgeMap(key);
         else
             midPt = (newVerts(idxA, :) + newVerts(idxB, :)) / 2;
             tempNewVerts = [tempNewVerts; midPt]; 
             midIdx = nextVertIdx;
             edgeMap(key) = midIdx;
             nextVertIdx = nextVertIdx + 1;
         end
      end
    end

    function [cData, faceColor, faceAlpha] = determineColorAttributes(obj, verts, options)
      useGradient = ~isempty(obj.ObjectiveFunction);
      if useGradient
        cData = obj.ObjectiveFunction(verts);
        faceColor = 'interp';
        faceAlpha = 0.8;
      else
        cData = [];
        faceColor = options.UnifiedColor;
        faceAlpha = 0.6;
      end
    end

    function [A_sub, b_sub, A_eq_sub, b_eq_sub] = projectConstraints(obj, ineqSet, viewDims)
      allDims = 1:obj.NumVars;
      fixedDims = setdiff(allDims, viewDims);
      x_fixed = obj.Defaults(fixedDims);

      A_full = ineqSet.A; 
      b_full = ineqSet.b;
      A_sub = A_full(:, viewDims);
      b_sub = b_full - A_full(:, fixedDims) * x_fixed;

      if ~isempty(obj.A_eq)
        A_eq_sub = obj.A_eq(:, viewDims);
        b_eq_sub = obj.b_eq - obj.A_eq(:, fixedDims) * x_fixed;
      else
        A_eq_sub = []; b_eq_sub = [];
      end
    end

    function [Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq] = collectPlanes(~, A, b, A_eq, b_eq, options)
      Planes_A = A; Planes_b = b;
      if ~isempty(A_eq), Planes_A = [Planes_A; A_eq]; Planes_b = [Planes_b; b_eq]; end
      
      I = eye(3);
      Box_A = [I; -I];
      Box_b = repmat(options.Bounds, 6, 1);
      
      Planes_A = [Planes_A; Box_A]; Planes_b = [Planes_b; Box_b];
      Check_A = [A; Box_A]; Check_b = [b; Box_b];
      Check_A_eq = A_eq; Check_b_eq = b_eq;
    end

    function validateDims(~, viewDims)
      m = length(viewDims);
      if m ~= 2 && m ~= 3
        error('可視化は2次元または3次元のみ対応しています。');
      end
    end

    function setupFigure(obj, viewDims, options)
      m = length(viewDims);
      figure; hold on; grid on;
      
      % タイトルと軸ラベルの設定
      title(options.Title, ...
            'Interpreter', 'latex', ...
            'FontSize', options.TitleFontSize, ...
            'FontName', options.FontName);
      
      hXLabel = xlabel(options.XLabel, ...
                       'Interpreter', 'latex', ...
                       'FontName', options.FontName, ...
                       'FontSize', options.FontSize);
      if ~isempty(options.XLabelPosition)
        hXLabel.Position = options.XLabelPosition;
      end
      if ~isempty(options.XLabelRotation)
        hXLabel.Rotation = options.XLabelRotation;
      end
      
      hYLabel = ylabel(options.YLabel, ...
                       'Interpreter', 'latex', ...
                       'FontName', options.FontName, ...
                       'FontSize', options.FontSize);
      if ~isempty(options.YLabelPosition)
        hYLabel.Position = options.YLabelPosition;
      end
      if ~isempty(options.YLabelRotation)
        hYLabel.Rotation = options.YLabelRotation;
      end
      
      if m == 3
        hZLabel = zlabel(options.ZLabel, ...
                         'Interpreter', 'latex', ...
                         'FontName', options.FontName, ...
                         'FontSize', options.FontSize);
        if ~isempty(options.ZLabelPosition)
          hZLabel.Position = options.ZLabelPosition;
        end
        if ~isempty(options.ZLabelRotation)
          hZLabel.Rotation = options.ZLabelRotation;
        end
        view(3);
      end
      
      % 軸のスタイル設定（論文用）
      set(gca, ...
          'FontName', options.FontName, ...
          'FontSize', options.FontSize, ...
          'LineWidth', 1.5, ...
          'Box', 'off');
      
      % 軸プロパティの詳細設定
      xaxisproperties = get(gca, 'XAxis');
      yaxisproperties = get(gca, 'YAxis');
      xaxisproperties.TickLabelInterpreter = 'latex';
      xaxisproperties.FontSize = options.FontSize;
      yaxisproperties.TickLabelInterpreter = 'latex';
      yaxisproperties.FontSize = options.FontSize;
      
      if m == 3
        zaxisproperties = get(gca, 'ZAxis');
        zaxisproperties.TickLabelInterpreter = 'latex';
        zaxisproperties.FontSize = options.FontSize;
      end
      
      % カラーバーの設定
      if ~isempty(obj.ObjectiveFunction)
        if options.ContourLevels > 0
          colormap(parula(options.ContourLevels));
        else
          colormap('parula');
        end
        cb = colorbar;
        cb.Label.String = options.ColorbarLabel;
        cb.Label.Interpreter = 'latex';
        cb.Label.FontSize = options.FontSize;
        cb.Label.FontName = options.FontName;
        
        % カラーバーの幅設定
        if ~isempty(options.ColorbarWidth)
          cb.Position(3) = options.ColorbarWidth;
        end
      end
    end

    function finalizeFigure(obj, viewDims, pointHandle, options)
      % 描画後の仕上げ（軸範囲設定・カラーバー調整・データカーソル・ラベル追従）
      % Args:
      %   viewDims (double vec): 可視化する次元のインデックス (長さ2または3)
      %   pointHandle (graphics handle): Defaults点プロットのハンドル
      %   options (struct): parseOptions の結果
      % Returns: なし
      xlim(options.XLim);
      ylim(options.YLim);
      if length(viewDims) == 3
        zlim(options.ZLim);
      end
      
      % カラーバーの数値範囲設定
      if ~isempty(options.ColorbarLimits)
        clim(options.ColorbarLimits);
      end
      
      % グリッド設定（論文用）
      grid on;
      ax = gca;
      ax.GridAlpha = 0.3;
      
      hold off;
      
      % データカーソルモードのカスタム関数を設定（モード自体は有効化しない）
      if ~isempty(pointHandle)
        dcm = datacursormode(gcf);
        set(dcm, 'UpdateFcn', @(~, event_obj) obj.dataCursorUpdateFcn(event_obj, viewDims));
      end

      % Defaults点を常に表側に見せる（カメラ方向に微小オフセット＋描画順）
      if ~isempty(pointHandle) && options.DefaultPointAlwaysOnTop && length(viewDims) == 3
        ax = gca;
        try
          % 半透明サーフェスの描画順が崩れないよう、depth を優先
          ax.SortMethod = 'depth';
        catch
        end
        try
          uistack(pointHandle, 'top');
        catch
        end

        obj.updateDefaultPointOnTop(ax, pointHandle, viewDims, options);

        % 既存のViewListenerがあれば上書きせず、複数保持できるようにする
        listener = addlistener(ax, 'View', 'PostSet', ...
          @(~,~) obj.updateDefaultPointOnTop(ax, pointHandle, viewDims, options));
        if isempty(obj.ViewListener)
          obj.ViewListener = listener;
        else
          obj.ViewListener(end+1) = listener; %#ok<AGROW>
        end
      end
      % 動的ラベル位置更新
      if options.AutoUpdateLabelPosition
         obj.ViewListener = addlistener(gca, 'View', 'PostSet', ...
            @(~,~) obj.updateLabelPositions(gca, viewDims, options));
         obj.updateLabelPositions(gca, viewDims, options);
      end
    end

    function updateDefaultPointOnTop(obj, ax, pointHandle, viewDims, options)
      % Defaults点をカメラ方向に微小オフセットして前面に見せる
      % Args:
      %   ax (axes)
      %   pointHandle (graphics handle)
      %   viewDims (double vec)
      %   options (struct)
      % Returns: なし
      try
        data = get(pointHandle, 'UserData');
        fullPoint = data.FullDimPoint(:);
      catch
        fullPoint = obj.Defaults(:);
      end

      p = fullPoint(viewDims);
      cp = ax.CameraPosition(:);
      p = p(:);
      dir = cp - p;
      n = norm(dir);
      if n < 1e-12, return; end
      dir = dir / n;

      if isempty(options.DefaultPointDepthOffset)
        depthOffset = max(1e-3 * options.Bounds, 1e-6);
      else
        depthOffset = options.DefaultPointDepthOffset;
      end

      p2 = p + dir * depthOffset;
      set(pointHandle, 'XData', p2(1), 'YData', p2(2), 'ZData', p2(3));
      try
        uistack(pointHandle, 'top');
      catch
      end
    end

    function updateLabelPositions(~, ax, viewDims, options)
      % 軸ラベルの配置を動的に更新する（視点に追従）
      % Args:
      %   ax (axes): 対象の Axes
      %   viewDims (double vec): 可視化している次元 (長さ2または3)
      %   options (struct): parseOptions の結果（LabelOffset 利用）
      % Returns: なし
      offset = options.LabelOffset; 
      if offset == 0, return; end
      
      xlims = ax.XLim;
      ylims = ax.YLim;
      zlims = ax.ZLim;
      
      if length(viewDims) == 3
        offset_val = abs(offset); 
        cp = ax.CameraPosition;
        
        % --- X Label (Y近傍, Zは下) ---
        y_edge = selectNearEdge(cp(2), ylims);
        z_edge = zlims(1);
        ax.XLabel.Position = [mean(xlims), y_edge + sign(y_edge) * offset_val, ...
                                            z_edge + sign(z_edge) * offset_val];
        
        % --- Y Label (X近傍, Zは下) ---
        x_edge = selectNearEdge(cp(1), xlims);
        z_edge = zlims(1);
        ax.YLabel.Position = [x_edge + sign(x_edge) * offset_val, ...
                              mean(ylims), ...
                              z_edge + sign(z_edge) * offset_val];
        
        % --- Z Label (視点から見て左側の縦稜線) ---
         [x_edge, y_edge] = selectLeftVerticalEdge(cp, xlims, ylims);
         z_offset = offset_val * 0.7; % Z軸ラベルは少し軸寄りにする
         ax.ZLabel.Position = [x_edge + sign(x_edge) * z_offset, ...
                               y_edge + sign(y_edge) * z_offset, ...
                               mean(zlims)];

        ax.XLabel.HorizontalAlignment = 'center';
        ax.YLabel.HorizontalAlignment = 'center';
        ax.ZLabel.HorizontalAlignment = 'center';
      else
        % 2D
        ax.XLabel.Position = [xlims(2) + offset, 0];
        ax.YLabel.Position = [0, ylims(2) + offset];
      end
      
      % --- Local Helper Functions ---
      function edge = selectNearEdge(camPosVal, lims)
        % Args: camPosVal (double), lims (1x2 double)
        % Returns: edge (double) - camera に近い側の端
        if abs(camPosVal - lims(1)) < abs(camPosVal - lims(2))
          edge = lims(1);
        else
          edge = lims(2);
        end
      end
      
      function [xe, ye] = selectLeftVerticalEdge(camPos, xl, yl)
        % Args: camPos (1x3 double), xl/yl (1x2 double)
        % Returns: xe, ye (double) - 視点から見て左側の縦稜線のX/Y座標
        x_mean = mean(xl); y_mean = mean(yl);
        if camPos(1) > x_mean && camPos(2) > y_mean     % Q1 (++,++)
          xe = xl(2); ye = yl(1);
        elseif camPos(1) < x_mean && camPos(2) > y_mean % Q2 (-,+)
          xe = xl(2); ye = yl(2);
        elseif camPos(1) < x_mean && camPos(2) < y_mean % Q3 (-,-)
          xe = xl(1); ye = yl(2);
        else                                            % Q4 (+,-)
          xe = xl(1); ye = yl(1);
        end
      end
    end
  end
end