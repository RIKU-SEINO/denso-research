classdef EqualityInequalityHelper
  methods (Static)
    function [A, b] = get_equality_matrix(variables, equation)
      % 等式を線形等式制約 Ax = b の形式に変換する
      constraints = MathUtils.get_children(equation, '&');
      [A, b] = equationsToMatrix(constraints, variables);
    end

    function [A, b] = get_inequality_matrix(variables, equation)
      % 不等式を線形不等式制約 Ax <= b の形式に変換する
      constraints = MathUtils.get_children(equation, '&');
      
      % NOTE: equationsToMatrixは '==' を想定しているため、
      % '<=' を 'lhs-rhs <= 0' ではなく 'lhs-rhs == -slack' のように
      % 変換する必要があるかもしれないが、ここでは元々の実装を尊重する。
      % 各constraintを、lhs-rhs == 0 の形式に変換する
      constraints = cellfun( ...
        @(c) lhs(c) - rhs(c) == 0, ...
        constraints, ...
        'UniformOutput', ...
        false ...
      );
      [A, b] = equationsToMatrix(constraints, variables);
    end

    function condition = get_inequality_feasibility_condition(A, b)
      % Fourier-Motzkin消去法を用いて、不等式 Ax <= b が解を持つための条件式を導出する
      %
      % Parameters:
      %   A (double[] | sym[]): 線形不等式制約の係数行列 (数値である必要がある)
      %   b (sym[]):    線形不等式制約の定数項 (シンボリック変数を含んでよい)
      
      % --- Fourier-Motzkin消去法の概要 ---
      % このアルゴリズムは、変数を一つずつ地道に消去していくことで、
      % 最終的にシンボリックパラメータ(b)のみに関する条件式を導き出す。
      % 1. 消去する変数を一つ選ぶ (例: x_n)
      % 2. 全ての不等式を x_n について整理し、「上限」「下限」「無関係」の3群に分ける
      % 3. 全ての「下限 <= 上限」の組み合わせから、x_n を含まない新しい不等式を生成する
      % 4. 全ての変数がなくなるまで、このプロセスを繰り返す
      % 5. 最後に残った定数(パラメータ)のみの不等式が、求める条件式となる
      % =========================================================================

      % STEP 1: 入力引数の型とサイズをチェック
      [m, n] = size(A);
      if size(b, 1) ~= m || size(b, 2) ~= 1
        error('入力引数の行列A, ベクトルbのサイズが一致しません');
      end
      
      % 計算のため、すべてシンボリック変数として扱う
      % 不等式 Ax <= b を Ax - b <= 0 の形式で考える
      % M * [x; 1] <= 0, ただし M = [A, -b]
      M = [sym(A), -sym(b)];

      % STEP 2: 変数を一つずつ消去するループ (x_n, x_{n-1}, ..., x_1)
      for k = n:-1:1
        % 現在の不等式の数を取得
        m_current = size(M, 1);
        if m_current == 0, break; end
        
        % 消去対象の変数x_kの係数に基づき、不等式を行インデックスで3群に分ける
        U_idx = find(arrayfun(@(i) MathUtils.is_always(M(i, k) > 0), 1:size(M, 1)));
        L_idx = find(arrayfun(@(i) MathUtils.is_always(M(i, k) < 0), 1:size(M, 1)));
        N_idx = find(arrayfun(@(i) MathUtils.is_always(M(i, k) == 0), 1:size(M, 1)));

        % 上限または下限のどちらか一方しか無い場合、x_kは常に存在可能。
        % x_kを含む不等式は不要となり、x_kを含まない不等式(N群)だけが残る。
        if isempty(U_idx) || isempty(L_idx)
          M = M(N_idx, :);
          continue;
        end
        
        % STEP 3: すべての下限と上限のペアから新しい不等式を生成
        num_new_rows = length(U_idx) * length(L_idx);
        M_new = sym(zeros(num_new_rows, size(M, 2)));
        
        new_row_idx = 1;
        for i = 1:length(U_idx)
          for j = 1:length(L_idx)
            fprintf('i: %d, j: %d\n', i, j);
            u_row = M(U_idx(i), :); % 上限を与える行
            l_row = M(L_idx(j), :); % 下限を与える行
            
            % u_row(k) * l_row - l_row(k) * u_row で x_k の係数がゼロになる
            % 例: x_k <= U と L <= x_k  --->  L <= U
            new_row = u_row(k) * l_row - l_row(k) * u_row;
            % fprintf('Generated new inequality from upper %d and lower %d: %s\n', i, j, char(new_row));
            M_new(new_row_idx, :) = new_row;
            new_row_idx = new_row_idx + 1;
          end
        end
        
        % 次のステップの行列は、今回生成した新しい不等式と、
        % 元々x_kと無関係だった不等式(N群)を合わせたものになる
        M = [M(N_idx, :); M_new];
      end

      % STEP 4: 最終的な条件式の構築
      % 全変数を消去した結果、Mの最初のn列はすべてゼロになっている。
      % 不等式は 0 <= -M(:, n+1) の形になる。
      condition = symtrue;
      if ~isempty(M)
        final_constants = -M(:, n + 1);
        for i = 1:size(final_constants, 1)
          condition = condition & (final_constants(i) >= 0);
        end
      end
      
      condition = simplify(condition);
    end

    function [A_mixed, b_mixed] = get_mixed_matrix(A_eq, b_eq, A_ineq, b_ineq)
      % 等式と不等式の混合制約の行列を取得
      %
      % Parameters:
      %   A_eq (double[] | sym[]): 等式制約の係数行列
      %   b_eq (sym[]): 等式制約の定数項
      %   A_ineq (double[] | sym[]): 不等式制約の係数行列
      %   b_ineq (sym[]): 不等式制約の定数項
      
      % 入力がシンボリックまたは数値行列であることを確認
      if ~(isa(A_eq, 'sym') || isnumeric(A_eq))
        error('A_eqはシンボリックまたは数値行列である必要があります。実際の型: %s', class(A_eq));
      end
      if ~(isa(b_eq, 'sym') || isnumeric(b_eq))
        error('b_eqはシンボリックまたは数値行列である必要があります。実際の型: %s', class(b_eq));
      end
      if ~(isa(A_ineq, 'sym') || isnumeric(A_ineq))
        error('A_ineqはシンボリックまたは数値行列である必要があります。実際の型: %s', class(A_ineq));
      end
      if ~(isa(b_ineq, 'sym') || isnumeric(b_ineq))
        error('b_ineqはシンボリックまたは数値行列である必要があります。実際の型: %s', class(b_ineq));
      end
      
      A_mixed = [A_eq; -A_eq; A_ineq];
      b_mixed = [b_eq; -b_eq; b_ineq];
    end

    function condition = get_mixed_feasibility_condition(A_eq, b_eq, A_ineq, b_ineq)
      % 等式と不等式の混合制約の可解条件を、純粋な不等式問題に変換して求める
      %
      % Parameters:
      %   (各引数は数値行列またはシンボリック)

      [A_mixed, b_mixed] = EqualityInequalityHelper.get_mixed_matrix( ...
        A_eq, b_eq, A_ineq, b_ineq ...
      );

      % 純粋な不等式系のソルバーを呼び出す
      condition = EqualityInequalityHelper.get_inequality_feasibility_condition(A_mixed, b_mixed);
    end
  end
end