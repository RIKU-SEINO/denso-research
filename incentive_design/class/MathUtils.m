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
          error('ORが残っています。このexprは展開できません。');
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

        if isequal(simplify(rest_expr), symtrue)
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
    
      and_children = MathUtils.get_children(expr, '&'); % ex. {A | B, A | C, B | D}
      grouped_expr = symtrue;
      rest_expr = symtrue;
      for i = 1:length(and_children)
        and_child = and_children{i}; % ex. A | B
        if contains(char(and_child), char(common_expr))
          or_children = MathUtils.get_children(and_child, '|'); % ex. {A, B}
          for j = 1:length(or_children)
            or_child = or_children{j}; % ex1. A, ex2. B
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
        if count_map(key) >= 2
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
      [~, sort_idx] = sort(counts, 'descend'); % カウント数が多い順にソート
  
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

      if contains(char(expr), '&') && contains(char(expr), '|')
        expr_after_applied_children = children(expr);
        operator_count_before = length(strfind(char(expr), operator));
        operator_count_after = length(strfind(join(string(expr_after_applied_children)), operator));
        if operator_count_after < operator_count_before
          children_obtained = expr_after_applied_children;
        else
          children_obtained = {expr};
        end
      elseif contains(char(expr), operator)
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
  end
end