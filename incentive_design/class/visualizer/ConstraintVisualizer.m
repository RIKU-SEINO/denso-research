classdef ConstraintVisualizer
  % ConstraintVisualizer 線形制約領域の可視化クラス (Final Complete Version)
  %
  % Features:
  %   - 3平面交差法による厳密な領域描画 (3D)
  %   - 目的関数によるグラデーション/等高線表示
  %   - メッシュ細分化による高精細描画 (2D/3D両対応)
  %   - 線分退化時のグラデーション描画対応 (2D)

  properties (Access = public)
    A_eq double
    b_eq double
    IneqSets struct       % 構造体配列: .A, .b
    Defaults double       % デフォルト値
    NumVars int32
    Bounds double = 100;  % 描画範囲
    
    % --- Visualization Settings ---
    
    % 目的関数 (例: @(x) log10(sum(x.^2, 2)))
    % 設定時はグラデーション、空の場合は UnifiedColor を使用
    ObjectiveFunction function_handle = function_handle.empty;
    
    % 等高線の設定 (0: 滑らか, N: N段階の離散カラー)
    ContourLevels double = 20; 

    % 単色塗り時の色
    UnifiedColor = [0, 0.4470, 0.7410];
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

    function plot(obj, viewDims)
      % メイン描画メソッド
      obj.validateDims(viewDims);
      obj.setupFigure(viewDims);

      for i = 1:length(obj.IneqSets)
        % 1. 射影 (Project)
        [A_sub, b_sub, A_eq_sub, b_eq_sub] = obj.projectConstraints(obj.IneqSets(i), viewDims);

        % 2. 描画 (Draw)
        if length(viewDims) == 2
          obj.drawRegion2D(A_sub, b_sub, A_eq_sub, b_eq_sub);
        else
          obj.drawRegion3D(A_sub, b_sub, A_eq_sub, b_eq_sub);
        end
      end

      obj.finalizeFigure(viewDims);
    end
  end

  %% --- Private Methods: 3D Logic ---
  methods (Access = private)
    
    function drawRegion3D(obj, A, b, A_eq, b_eq)
      % 1. 制約平面の収集
      [Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq] = ...
          obj.collectPlanes(A, b, A_eq, b_eq);

      % 2. 頂点計算 (3平面交差全探索)
      verts = obj.computeVertices3D(Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq);

      % 3. 形状生成と描画
      if ~isempty(verts)
        obj.renderShape3D(verts);
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

    function renderShape3D(obj, verts)
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
      [cData, faceColor, faceAlpha] = obj.determineColorAttributes(verts_refined);
      
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
    
    function drawRegion2D(obj, A, b, A_eq, b_eq)
      if ~isempty(A_eq)
        A = [A; A_eq; -A_eq];
        b = [b; b_eq; -b_eq];
      end

      verts = obj.computeVertices2D(A, b);

      if ~isempty(verts)
        obj.renderShape2D(verts);
      end
    end

    function verts = computeVertices2D(obj, A, b)
      verts = [];
      options = optimoptions('linprog', 'Display', 'off', 'Algorithm', 'dual-simplex');
      lb = -obj.Bounds * ones(2, 1); 
      ub =  obj.Bounds * ones(2, 1);

      thetas = linspace(0, 2*pi, 60)';
      directions = [cos(thetas), sin(thetas); 1 1; 1 -1; -1 1; -1 -1];

      for k = 1:size(directions, 1)
        try
          [x, ~, exitflag] = linprog(-directions(k, :), A, b, [], [], lb, ub, options);
          if exitflag == 1, verts = [verts; x']; end %#ok<AGROW>
        catch
        end
      end
      if ~isempty(verts), verts = uniquetol(verts, 1e-5, 'ByRows', true); end
    end

    function renderShape2D(obj, verts)
      [cData, ~, faceAlpha] = obj.determineColorAttributes(verts);
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
            fill(verts(k, 1), verts(k, 2), obj.UnifiedColor, 'FaceAlpha', faceAlpha, 'EdgeColor', 'none');
          end
        catch
          % convhull失敗時は線分とみなす
          obj.drawGradientLine(verts, useGradient);
        end
      elseif nVerts == 2
        % 線分
        obj.drawGradientLine(verts, useGradient);
      elseif nVerts == 1
        % 点
        color = obj.UnifiedColor;
        if useGradient, color = cData; end
        scatter(verts(:, 1), verts(:, 2), 50, color, 'filled', 'MarkerEdgeColor', 'k');
      end
    end

    function drawGradientLine(obj, verts, useGradient)
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
                 'Color', obj.UnifiedColor, 'LineWidth', 2);
        end
    end
  end

  %% --- Private Methods: Utilities ---
  methods (Access = private)
      
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

    function [cData, faceColor, faceAlpha] = determineColorAttributes(obj, verts)
      useGradient = ~isempty(obj.ObjectiveFunction);
      if useGradient
        cData = obj.ObjectiveFunction(verts);
        faceColor = 'interp';
        faceAlpha = 0.8;
      else
        cData = [];
        faceColor = obj.UnifiedColor;
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

    function [Planes_A, Planes_b, Check_A, Check_b, Check_A_eq, Check_b_eq] = collectPlanes(obj, A, b, A_eq, b_eq)
      Planes_A = A; Planes_b = b;
      if ~isempty(A_eq), Planes_A = [Planes_A; A_eq]; Planes_b = [Planes_b; b_eq]; end
      
      I = eye(3);
      Box_A = [I; -I];
      Box_b = repmat(obj.Bounds, 6, 1);
      
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

    function setupFigure(obj, viewDims)
      m = length(viewDims);
      figure; hold on; grid on;
      title(sprintf('%dD Slice Visualization (Dims: %s)', m, mat2str(viewDims)));
      xlabel(['x_{' num2str(viewDims(1)) '}']);
      ylabel(['x_{' num2str(viewDims(2)) '}']);
      if m == 3, zlabel(['x_{' num2str(viewDims(3)) '}']); view(3); end
      
      if ~isempty(obj.ObjectiveFunction)
        if obj.ContourLevels > 0
          colormap(parula(obj.ContourLevels));
        else
          colormap('parula');
        end
        cb = colorbar;
        cb.Label.String = 'Objective Value';
      end
    end

    function finalizeFigure(obj, viewDims)
      limit = obj.Bounds;
      xlim([-limit limit]);
      ylim([-limit limit]);
      if length(viewDims) == 3, zlim([-limit limit]); end
      hold off;
    end
  end
end