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
  end
end