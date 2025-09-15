classdef MathUtils
  methods (Static)
    function exprs = expand_or_optimized(expr)
      % 論理式exprをORで展開し、全パターンの論理式を取得する
      % ただし、そのままORで展開するとかなりの数になるので、
      % MathUtils.factorによりORの数を減らしてから展開している
      % 
      % Parameters:
      %   expr - 論理式（sym）
      %
      % Returns:
      %   exprs - 論理式の集合（cell配列）
      %   ex. expr = (A | B) & (A | C) & (D | E) & (D | F) のとき、
      %       MathUtils.factor(expr) = (A | (B & C)) & (D | (E & F))なので、
      %       MathUtils.expand_or(expr) = {
      %         A & D,
      %         A & (E & F),
      %         (B & C) & D,
      %         (B & C) & (E & F)
      %       }

      factored_expr = MathUtils.factor(expr);
      exprs = MathUtils.expand_or(factored_expr);
    end

    function exprs = expand_or(expr)
      % 論理式exprをORで展開し、全パターンの論理式を取得する
      % ただし、そのままORで展開するとかなりの数になるので、
      % MathUtils.factorによりORの数を減らした上でexpand_orを使うと良い。
      % そのため、expand_orを直接参照することは計算速度が著しく遅くなるので非推奨であり、
      % expand_or_optimizedを使うことを推奨する。
      % 
      % Parameters:
      %   expr - 論理式（sym）
      %
      % Returns:
      %   exprs - 論理式の集合（cell配列）
      %   ex. expr = (A | B) & (A | C) & (D | E) & (D | F) のとき、
      %       MathUtils.expand_or(expr) = {
      %         A & A & D & D,
      %         A & A & D & F,
      %         A & A & E & D,
      %         A & A & E & F,
      %         A & C & D & D,
      %         A & C & D & F,
      %         A & C & E & D,
      %         A & C & E & F,
      %         B & A & D & D,
      %         B & A & D & F,
      %         B & A & E & D,
      %         B & A & E & F,
      %         B & C & D & D,
      %         B & C & D & F,
      %         B & C & E & D,
      %         B & C & E & F,
      %       }

      if ~contains(char(expr), '|')
        exprs = {expr};
        return;
      end

      % AND 子式を取得
      and_children = MathUtils.get_children(expr, '&');
      num_and = length(and_children);

      % 各 AND 子式に含まれる OR 子式の候補を集める
      choices = cell(1, num_and);
      for i = 1:num_and
        or_expr = and_children{i};
        choices{i} = MathUtils.get_children(or_expr, '|');
      end

      all_combinations = MathUtils.cartesian_product(choices);

      % 各組み合わせを AND で結合した式に変換
      exprs = cell(1, size(all_combinations, 1));
      for i = 1:size(all_combinations, 1)
        combined = all_combinations(i, :);
        tmp_expr = combined{1};
        for j = 2:length(combined)
          tmp_expr = tmp_expr & combined{j};
        end
        if contains(char(tmp_expr), '|')
          error('[MathUtils.expand_or] Error: OR operator remains in expression');
        end
        exprs{i} = tmp_expr;
      end
    end

    function factored_expr = factor(expr)
      % 論理式exprを共通式でくくった部分とそれ以外の部分に分解する
      %
      % Parameters:
      %   expr - 論理式（sym）
      %
      % Returns:
      %   factored_expr - 共通式でくくった部分（sym）
      %   ex. expr = (A | B) & (A | C) & (D | E) & (D | F) のとき、
      %       factored_expr = (A | (B & C)) & (D | (E & F))

      rest_expr = expr;
      factored_expr = symtrue;
      
      while true
        common_exprs = MathUtils.get_common_exprs(rest_expr);

        if isempty(common_exprs)
          factored_expr = factored_expr & rest_expr;
          break;
        end

        most_common_expr = common_exprs{1};
        [factored_expr_tmp, rest_expr] = MathUtils.factor_common_expr(rest_expr, most_common_expr);
        factored_expr = factored_expr & factored_expr_tmp;

        if isequal(rest_expr, symtrue)
          break;
        end
      end
    end

    function [factored_expr, rest_expr] = factor_common_expr(expr, common_expr)
      % (A | B) & (A | C) & (B | D) のようなORがANDで結合された論理式exprについて、
      % 共通式common_exprでくくった部分とそれ以外の部分に分解する
      % 
      % Parameters:
      %   expr - 論理式（sym）
      %   common_expr - 共通式（sym）
      %
      % Returns:
      %   factored_expr - 共通式でくくった部分（sym）
      %   rest_expr - 共通式でくくった部分を取り除いた論理式（sym）
      %   ex. expr = (A | B) & (A | C) & (B | D) , common_expr = A のとき、
      %       factored_expr = A | (B & C), rest_expr = (B | D) となる
    
      and_children = MathUtils.get_children(expr, '&');

      grouped_expr = symtrue;
      rest_expr = symtrue;
      
      for i = 1:length(and_children)
        and_child = and_children{i};
        if contains(char(and_child), char(common_expr))
          or_children = MathUtils.get_children(and_child, '|');
          for j = 1:length(or_children)
            or_child = or_children{j};
            if ~strcmp(char(or_child), char(common_expr))
              grouped_expr = grouped_expr & or_child;
            end
          end
        else
          rest_expr = rest_expr & and_child;
        end
      end

      factored_expr = common_expr | grouped_expr;
    end

    function common_exprs = get_common_exprs(expr)
      % 2回以上出現している式の集合を、出現回数が多い順に取得する
      %
      % Parameters:
      %   expr - 論理式（sym）
      %   ex. (A | B) & (A | C) & (A | D) & (B | X) のとき、
      %       A, B が2回以上出現している式となる。
      %       出現回数が多い順に並べると、{A, B}となる。
      %
      % Returns:
      %   common_exprs - 2回以上出現している式の集合（cell配列）
      %   ex. {A, B}

      count_map = MathUtils.count_or_conditions(expr);

      common_exprs = {};
      keys = count_map.keys();
      for i = 1:length(keys)
        key = keys{i};
        count = count_map(key);
        if count >= 2
          common_exprs{end+1} = str2sym(key);
        end
      end
    end

    function count_map = count_or_conditions(expr)
      % (A | B) & (A | C) & (B | D) のようなORがANDで結合された論理式を分解し、
      % A, B, C, D の出現回数をカウントする
      %
      % Parameters:
      %   expr - 論理式（sym）
      %   ex. (x < 1 | y > 2) & (x < 1 | z == 0) & (y > 2 | w <= 5)
      %       -> x < 1: 2回, y > 2: 2回, z == 0: 1回, w <= 5: 1回
      %
      % Returns:
      %   count_map - containers.Map（キー: 式の文字列、値: 出現回数）
      %   ex. count_map('x < 1') = 2
      %       count_map('y > 2') = 2
      %       count_map('z == 0') = 1
      %       count_map('w <= 5') = 1
      
      all_ineqs_str_tmp = {};

      % ANDで分解
      and_children = MathUtils.get_children(expr, '&');
      
      for i = 1:length(and_children)
        % ORで分解
        or_children = MathUtils.get_children(and_children{i}, '|');

        for j = 1:length(or_children)
          child = or_children{j};
          all_ineqs_str_tmp{end+1} = char(child);
        end
      end
      
      % ユニークな文字列にまとめ
      [uniq_strs, ~, idx] = unique(all_ineqs_str_tmp);
  
      % カウント
      counts = histcounts(idx, 1:(length(uniq_strs)+1));
      [~, sort_idx] = sort(counts, 'descend');
  
      % Map に保存
      count_map = containers.Map();
      for i = 1:length(sort_idx)
        count_map(uniq_strs{sort_idx(i)}) = counts(sort_idx(i));
      end
    end
    
    function children_obtained = get_children(expr, operator)
      % 論理式exprのoperatorで結合された子式を取得する
      %
      % Parameters:
      %   expr - 論理式（sym）
      %   operator - 結合演算子（'&' または '|'）
      %
      % Returns:
      %   children_obtained - 子式（cell配列）
      %   ex. expr = A & B, operator = '&' のとき、
      %       children_obtained = {A, B}
      %   ex. expr = A | B, operator = '|' のとき、
      %       children_obtained = {A, B}
      %   ex. expr = A, operator = '&' のとき、
      %       children_obtained = {A}

      expr_str = char(expr);
      
      if contains(expr_str, '&') && contains(expr_str, '|')
        expr_after_applied_children = children(expr);
        operator_count_before = length(strfind(expr_str, operator));
        operator_count_after = length(strfind(join(string(expr_after_applied_children)), operator));
        if operator_count_after < operator_count_before
          children_obtained = expr_after_applied_children;
        else
          children_obtained = {expr};
        end
      elseif contains(expr_str, operator)
        children_obtained = children(expr);
      else
        children_obtained = {expr};
      end
    end

    function result = cartesian_product(choices)
      % choices は cell array で、各要素は {expr1, expr2, ...}
      n = numel(choices);
      [grid{1:n}] = ndgrid(choices{:});
      % 各セルの内容を列に並べる
      result = cell(numel(grid{1}), n);
      for i = 1:n
        result(:, i) = reshape(grid{i}, [], 1);
      end
    end

    function result = is_always(expr)
      % isAlwaysのラッパーとして、厳密な証明と数値検証の両方を組み合わせる
      %
      % Parameters:
      %   expr - 論理式（sym）
      %
      % Returns:
      %   result - 常に成立する場合は true, 常に成立しない場合は false, それ以外は error
      
      try
        result = isAlways(expr, 'Unknown', 'error');
      catch
        num_samples = 2e2;
        vars = symvar(expr);
        vals_mat = zeros(num_samples, length(vars));
        for i = 1:length(vars)
          range = MathUtils.get_range(vars(i));
          min_val = range(1);
          max_val = range(2);
          vals_mat(:, i) = min_val + (max_val - min_val) * rand(num_samples, 1);
        end

        evaluated_conditions = zeros(num_samples, 1);
        for i = 1:num_samples
          evaluated_conditions(i) = subs(expr, vars, vals_mat(i, :));
        end
        if all(evaluated_conditions)
          result = true;
        elseif all(~evaluated_conditions)
          result = false;
        else
          error('条件式の真偽値が一意に定まりません');
        end
      end
    end

    function range = get_range(targetVar)
      % 変数に設定された仮定から数値範囲[min, max]を取得
      %
      % Parameters:
      %   targetVar - 変数（sym）
      %
      % Returns:
      %   range - 数値範囲[min, max]
      %   ex. targetVar = x のとき、
      %       range = [-inf, inf]
      %   ex. targetVar = x, 仮定が x < 1 のとき、
      %       range = [-inf, 1]
      %   ex. targetVar = x, 仮定が x < 1 かつ x > 0 のとき、
      %       range = [0, 1]

      range = [-inf, inf]; % デフォルトは無制限
      
      % 指定された変数に関する仮定を取得
      ParamsHelper.assume_symbolic_params(targetVar);
      assumps = assumptions(targetVar);
      
      if isempty(assumps)
        return; % 仮定がなければデフォルトを返す
      end
      
      for i = 1:length(assumps)
        cond = assumps(i);
        parts = children(cond);
        % 不等式の左辺と右辺を取得
        lhs = parts{1};
        rhs = parts{2};
        operation = extractBetween(char(cond), ' ', ' ');
        
        % targetVarが左辺に含まれているかチェック
        if contains(char(lhs), char(targetVar))
          % targetVarが左辺にある場合、右辺がmax値
          if strcmp(operation, '<')
            range(2) = min(range(2), double(rhs) - 1e-10);
          elseif strcmp(operation, '<=')
            range(2) = min(range(2), double(rhs));
          end
        else
          % targetVarが右辺にある場合、左辺がmin値 
          if strcmp(operation, '<')
            range(1) = max(range(1), double(lhs) + 1e-10);
          elseif strcmp(operation, '<=')
            range(1) = max(range(1), double(lhs));
          end
        end
      end
    end
  end
end