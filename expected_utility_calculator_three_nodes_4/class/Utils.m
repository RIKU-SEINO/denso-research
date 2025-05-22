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
  end
end