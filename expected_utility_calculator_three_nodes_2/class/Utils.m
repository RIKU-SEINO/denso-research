classdef Utils
  methods (Static)
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

    function result = is_allowed_skip_validation()
      stack = dbstack;
      allowed_skip_validation_methods = {
        % メソッド名, スタックの深さ
        {'PlayerSet.get_all_passenger_sets', 4}
      };

      for i = 1:length(allowed_skip_validation_methods)
        allowed_skip_method = allowed_skip_validation_methods{i}{1};
        allowed_skip_method_depth = allowed_skip_validation_methods{i}{2};
        try
          if strcmp(stack(allowed_skip_method_depth).name, allowed_skip_method)
            result = true;
            return
          end
        catch
          % pass
        end
      end

      result = false;
    end

    function clear_cache()
      persistent cache;
      if ~isempty(cache)
          cache = containers.Map('KeyType', 'char', 'ValueType', 'any'); % キャッシュを空のマップにリセット
          fprintf('Cache cleared.\n');
      end
    end
  end
end