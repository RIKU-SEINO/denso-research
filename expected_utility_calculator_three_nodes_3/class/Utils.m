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
  end
end