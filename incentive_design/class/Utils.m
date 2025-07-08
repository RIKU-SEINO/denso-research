classdef Utils
  methods (Static)
    function result = ismember(obj, objs)
      % objがobjsの中に含まれているか判定する
      % 
      % Parameters:
      %   obj (any): 判定対象のオブジェクト
      %   objs (cell): 判定対象のオブジェクトの集合
      %
      % Returns:
      %   result (logical): 含まれている場合は true, そうでない場合は false

      result = false;
      for i = 1:length(objs)
        if isequal(obj, objs{i})
          result = true;
          break;
        end
      end
    end
    
    function diff_objs = obj_setdiff(objs1, objs2)
      % objs1からobjs2を引いた差集合を返す
      % 
      % Parameters:
      %   objs1 (cell): 引かれる集合
      %   objs2 (cell): 引く集合
      %
      % Returns:
      %   diff_objs (cell): 差集合
      diff_objs = {};
      for i = 1:length(objs1)
        obj1 = objs1{i};
        found = false;
        for j = 1:length(objs2)
          obj2 = objs2{j};
          if eq(obj1, obj2)
            found = true;
            break;
          end
        end
        if ~found
          diff_objs{end+1, 1} = obj1;
        end
      end
    end

    function organized_expr = organize_expr(expr, vars)
      % シンボリック式exprを整理する
      % 
      % Parameters:
      %   expr (sym): 整理対象の式
      %   vars (sym[]): くくる変数の配列
      %
      % Returns:
      %   expr (sym): 整理された式

      organized_expr = sym(0);
      organized_exprs = children(collect(expr, vars));
      for i = 1:length(organized_exprs)
        organized_expr = organized_expr + simplify(organized_exprs{i});
      end

      if ~isequal(simplify(expr - organized_expr), sym(0))
        assignin('base', 'expr', expr)
        assignin('base', 'organized_expr', organized_expr)
        error('整理後の式が整理前と一致していません')
      end
    end

    function plot_max_symbolic_funcs_3d(funcs, args, xlim, ylim, grid_res)
      % 複数のシンボリック関数funcsについて、
      % xlim, ylimで指定した範囲で最大値をとる関数を色分けして3Dプロット
      %
      % funcs   : シンボリック関数のベクトルまたはセル配列
      % args    : 変数名のセル配列
      % xlim    : [xmin xmax]
      % ylim    : [ymin ymax]
      % grid_res: (任意) グリッドの分解能。省略時100。
      
      if nargin < 4
        grid_res = 100;
      end
  
      if iscell(funcs)
        funcs = [funcs{:}];
      end
  
      n = numel(funcs);
  
      vars = sym(args);
      if numel(vars) ~= 2
        error('関数は必ず2変数を使ってください。');
      end
      vx = vars(1);
      vy = vars(2);
  
      % グリッド生成
      [X, Y] = meshgrid(linspace(xlim(1), xlim(2), grid_res), linspace(ylim(1), ylim(2), grid_res));
  
      func_handles = cell(1, n);
      for i = 1:n
        func_handles{i} = matlabFunction(funcs(i), 'Vars', [vx vy]);
      end
  
      F_all = zeros(size(X,1), size(X,2), n);
      for i = 1:n
        F_all(:,:,i) = func_handles{i}(X, Y);
      end
  
      [Fmax, maxIdx] = max(F_all, [], 3);
  
      colors = jet(n);
  
      rgb_map = zeros([size(X), 3]);
      for k = 1:n
        mask = (maxIdx == k);
        for c = 1:3
          channel = rgb_map(:,:,c);
          channel(mask) = colors(k,c);
          rgb_map(:,:,c) = channel;
        end
      end
  
      figure
      surf(X, Y, Fmax, rgb_map, 'EdgeColor', 'none');
      xlabel(char(vx));
      ylabel(char(vy));
      title('最大値関数の高さと種類で色分けした3Dサーフェス');
      grid on
      view(45,30)
      axis tight
    end

    function plot_inequality_region_with_inputs( ...
      ineq, ...
      all_params, ...
      default_params_values, ...
      params_condition, ...
      x_range, y_range, ...
      x_param, y_param, ...
      title_str, ...
      ineq_symtrue_text, ...
      ineq_symfalse_text, ...
      grid_res ...
    )
      % 不等式を満たす領域を、入力パラメータを変更できるようにGUIで表示
      % 
      % Parameters:
      %   ineq (sym): 不等式
      %   all_params (sym[]): すべてのパラメータの配列
      %   default_params_values (double[]): all_paramsのデフォルト値
      %   params_condition (sym): パラメータ条件。特にない場合はsymtrueを渡す
      %   x_range (1,2) double: x軸の範囲
      %   y_range (1,2) double: y軸の範囲
      %   x_param (string): x軸にとるパラメータの名前
      %   y_param (string): y軸にとるパラメータの名前
      %   title_str (string): タイトル
      %   ineq_symtrue_text (string): 不等式が真の場合のテキスト
      %   ineq_symfalse_text (string): 不等式が偽の場合のテキスト
      %   grid_res (int): グリッドの分解能
      %
      % Returns:
      %   None（GUIで表示するため）

      arguments
        ineq
        all_params
        default_params_values
        params_condition
        x_range (1,2) double
        y_range (1,2) double
        x_param {mustBeTextScalar}
        y_param {mustBeTextScalar}
        title_str = 'Inequality Region'
        ineq_symtrue_text = 'True'
        ineq_symfalse_text = 'False'
        grid_res = 10
      end

      x_sym = sym(x_param);
      y_sym = sym(y_param);
    
      % === 全シンボリック変数の取得 ===
      all_vars = all_params;
      edit_vars = setdiff(all_vars, [x_sym, y_sym]);
      [~, idx] = ismember(all_vars, edit_vars);
      edit_vars = edit_vars(idx(idx ~= 0));
      default_params_values_edit = default_params_values(ismember(all_vars, edit_vars));

      all_vars_in_ineq = symvar(ineq);
      edit_vars_in_ineq = setdiff(all_vars_in_ineq, [x_sym, y_sym]);
      [~, idx] = ismember(all_vars, edit_vars_in_ineq);
      edit_vars_in_ineq = edit_vars_in_ineq(idx(idx ~= 0));
      no_dependency_edit_vars = ~ismember(edit_vars, edit_vars_in_ineq);
    
      % === GUI用figureとaxes作成 ===
      f = figure('Name', 'Interactive Inequality Plot', 'NumberTitle', 'off');
      ax = axes('Parent', f, 'Position', [0.1 0.3 0.85 0.65]);
    
      % === 各入力パラメータ（軸以外）に対してedit box生成 ===
      nEdits = numel(edit_vars);
      editBoxes = gobjects(1, nEdits);

      % === 位置設定用：左寄せ＋5個で折り返し ===
      startX = 0.12;
      startY = 0.1;
      spacingX = 0.18;
      spacingY = 0.08;
      labelWidth = 0.1;
      editWidth = 0.08;
      labelHeight = 0.05;
      editHeight = 0.05;
      nCols = 4;  % 1行あたり最大表示数
    
      for i = 1:nEdits
        varname = char(edit_vars(i));
        if no_dependency_edit_vars(i)
          varname_show = sprintf('(%s)', varname);
        else
          varname_show = varname;
        end

        col = mod(i-1, nCols);
        row = floor((i-1)/nCols);

        xLabel = startX + col * spacingX;
        xEdit  = xLabel + labelWidth;
        yPos   = startY - row * spacingY;
    
        % ラベル
        uicontrol('Style', 'text', ...
          'Units', 'normalized', ...
          'Position', [xLabel, yPos, labelWidth, labelHeight], ...
          'String', varname_show, ...
          'HorizontalAlignment', 'right', ...
          'FontWeight', 'bold');

        % 入力欄
        editBoxes(i) = uicontrol('Style', 'edit', ...
          'Units', 'normalized', ...
          'Position', [xEdit, yPos, editWidth, editHeight], ...
          'String', num2str(default_params_values_edit(i)), ...
          'Tag', varname, ...
          'Callback', @(src, ~) update_plot());
      end
    
      % === 描画更新関数 ===
      function update_plot()
        assigned_ineq = ineq;
    
        % 各 edit box の値で変数を代入
        for k = 1:nEdits
          val = str2double(editBoxes(k).String);
          if isnan(val)
            val = 0;
            editBoxes(k).String = '0';
          end
          params_condition = simplify(subs(params_condition, sym(editBoxes(k).Tag), val));
          assigned_ineq = subs(assigned_ineq, sym(editBoxes(k).Tag), val);
        end

        is_invalid_params = simplify(params_condition == symfalse);
        assigned_ineq = simplify(assigned_ineq);
    
        % タイトル用のパラメータ表示
        param_info = strjoin(arrayfun( ...
          @(h) sprintf('%s=%s', h.Tag, h.String), ...
          editBoxes, 'UniformOutput', false), ', ');

        if is_invalid_params
          title_str = sprintf('%s (invalid parameters)', title_str);
        end
    
        % 描画
        cla(ax);
        axis(ax, 'equal');
        Utils.plot_inequality_region( ...
          assigned_ineq, ...
          x_range, y_range, ...
          sprintf('%s (%s)', title_str, param_info), ...
          grid_res, ...
          ax, ...
          x_param, ...
          y_param, ...
          ineq_symtrue_text, ...
          ineq_symfalse_text ...
        );
      end
    
      % === 初期描画 ===
      update_plot();
    end      
    
    function h = plot_inequality_region( ...
      ineq, ...
      x_range, y_range, ...
      title_str, ...
      grid_res, ...
      ax, ...
      x_param, ...
      y_param, ...
      ineq_symtrue_text, ...
      ineq_symfalse_text ...
    )
      % 不等式を満たす領域をGUIで表示する補助関数
      % 
      % Parameters:
      %   ineq (sym): 不等式
      %   x_range (1,2) double: x軸の範囲
      %   y_range (1,2) double: y軸の範囲
      %   title_str (string): タイトル
      %   grid_res (int): グリッドの分解能
      %   ax (axes): 描画先のaxes
      %   x_param (string): x軸の変数名
      %   y_param (string): y軸の変数名
      %   ineq_symtrue_text (string): 不等式が真の場合のテキスト
      %   ineq_symfalse_text (string): 不等式が偽の場合のテキスト
      %
      % Returns:
      %   h (gobject): 描画されたグラフのハンドル

      % 変数名をシンボルに変換
      x = sym(x_param);
      y = sym(y_param);

      simplified_ineq = simplify(ineq);
    
      % グリッド生成
      x_vals = linspace(x_range(1), x_range(2), grid_res);
      y_vals = linspace(y_range(1), y_range(2), grid_res);
      [X, Y] = meshgrid(x_vals, y_vals);
    
      % 不等式を関数化して評価
      if isequal(simplified_ineq, symtrue)
        Z = ones(size(X));
      elseif isequal(simplified_ineq, symfalse)
        Z = zeros(size(X));
      else
        f_handle = matlabFunction(ineq, 'Vars', [x, y]);
        Z = f_handle(X, Y);
      end
    
      % 可視化
      h = imagesc(x_vals, y_vals, double(Z), 'Parent', ax);
      axis(ax, 'xy');
      axis(ax, 'image');
      colormap([1 1 1; 0.2 0.6 1]);
      clim(ax, [0, 1]);
      xlabel(ax, char(x));
      ylabel(ax, char(y));
      grid(ax, 'on');
      title(ax, title_str);

      if isequal(simplified_ineq, symtrue)
        text(mean(x_range), mean(y_range), ineq_symtrue_text, ...
            'Parent', ax, 'HorizontalAlignment', 'center', ...
            'FontSize', 14, 'Color', 'green', 'FontWeight', 'bold');
      elseif isequal(simplified_ineq, symfalse)
        text(mean(x_range), mean(y_range), ineq_symfalse_text, ...
            'Parent', ax, 'HorizontalAlignment', 'center', ...
            'FontSize', 14, 'Color', 'red', 'FontWeight', 'bold');
      end
    end      
  end
end