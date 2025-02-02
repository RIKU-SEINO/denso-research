classdef Condition
  properties
    expr; % symbolic: 条件式
  end

  methods
    function obj = Condition(expr)
      if nargin == 0
        obj.expr = [];
      else
        obj.expr = simplify(expr);
      end
    end

    function expr = getExpression(obj)
      expr = obj.expr;
    end

    function key = getKey(obj)
      key = char(obj.expr);
    end
  end

  methods
    function obj = combineAsAND(obj, condition)
      if isempty(obj.expr)
        obj.expr = condition.getExpression();
      else
        obj.expr = simplify(and(obj.expr, condition.getExpression()));
      end
    end

    function obj = combineAsOR(obj, condition)
      if isempty(obj.expr)
        obj.expr = condition.getExpression();
      else
        obj.expr = simplify(or(obj.expr, condition.getExpression()));
      end
    end
  end

  methods 
    function result = isIncluded(obj, conditions)
      result = false;
      for i = 1:length(conditions)
        if isequal(obj.expr, conditions{i}.getExpression())
          result = true;
          break;
        end
      end
    end

    function result = isIncluded2(obj, conditions)
      result = false;
      for i = 1:length(conditions)
        if isequal(obj.expr, conditions{i}.getExpression()) || isequal(simplify(or(obj.expr, conditions{i}.getExpression())), symtrue)
          result = true;
          break;
        end
      end
    end
  end
end