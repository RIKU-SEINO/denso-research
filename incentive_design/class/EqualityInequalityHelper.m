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

    function conditions = get_inequality_feasibility_condition_FourierMotzkin(A, b)
      % Fourier-Motzkin消去法を用いて、不等式 Ax <= b が解を持つための条件式を導出する
      %
      % Parameters:
      %   A (sym[]): 線形不等式制約の係数行列 (数値であることを想定)
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

      [m, n] = size(A);
      current_A = double(A);
      current_b = sym(b);
      tolerance = 1e-10;
    
      % --- LOG START ---
      fprintf('=== Fourier-Motzkin Start: %d variables, %d initial constraints ===\n', n, m);
    
      for k = n:-1:1
        m_current = size(current_A, 1);
        if m_current == 0, break; end
        
        col_k = current_A(:, k);
        U_idx = find(col_k > tolerance);
        L_idx = find(col_k < -tolerance);
        N_idx = find(abs(col_k) <= tolerance);
    
        % --- LOG POINT 1: 変数消去の開始 ---
        fprintf('\n[Var %d] Eliminating... (Current constraints: %d)\n', k, m_current);
        fprintf('  -> Found Upper: %d, Lower: %d, Neutral: %d\n', length(U_idx), length(L_idx), length(N_idx));
    
        if isempty(U_idx) || isempty(L_idx)
          fprintf('  -> No pairs to combine. Variable removed directly.\n');
          current_A = current_A(N_idx, :);
          current_b = current_b(N_idx, :);
          continue;
        end
        
        num_new_rows = length(U_idx) * length(L_idx);
        fprintf('  -> Generating %d new constraints from pairs...\n', num_new_rows);
        
        A_new = zeros(num_new_rows, size(current_A, 2));
        b_new = sym(zeros(num_new_rows, 1));
        
        new_row_idx = 1;
        
        % 進捗表示のためのカウンタ
        total_pairs = length(U_idx) * length(L_idx);
        processed_count = 0;
    
        for i = 1:length(U_idx)
          u_idx = U_idx(i);
          u_row_A = current_A(u_idx, :);
          u_val_A = u_row_A(k);
          u_val_b = current_b(u_idx);
          
          for j = 1:length(L_idx)
            l_idx = L_idx(j);
            l_row_A = current_A(l_idx, :);
            l_val_A = l_row_A(k);
            l_val_b = current_b(l_idx);
            
            new_row_A = u_val_A * l_row_A - l_val_A * u_row_A;
            A_new(new_row_idx, :) = new_row_A;
            
            % ここがシンボリック計算の重い部分
            new_val_b = u_val_A * l_val_b - l_val_A * u_val_b;
            b_new(new_row_idx) = new_val_b;
            
            new_row_idx = new_row_idx + 1;
            processed_count = processed_count + 1;
          end
    
          % --- LOG POINT 2: 生成の進捗 (iループの周回ごとに表示) ---
          % あまり細かく出しすぎるとログで遅くなるので、適度な間隔で
          if mod(i, 10) == 0 || i == length(U_idx)
              fprintf('    Progress: %d / %d pairs generated (%.1f%%)\n', ...
                  processed_count, total_pairs, (processed_count/total_pairs)*100);
              drawnow; % MATLABのコマンドウィンドウを強制更新
          end
        end
        
        current_A = [current_A(N_idx, :); A_new];
        current_b = [current_b(N_idx); b_new];
      end
    
      % --- LOG POINT 3: 最終処理 ---
      fprintf('\n=== Elimination Complete ===\n');
      fprintf('Final raw constraints: %d\n', length(current_b));
      fprintf('Constructing AND condition...\n');
    
      conditions = sym.empty(0, 1);
      for i = 1:size(current_b, 1)
        conditions(end+1) = sym(current_b(i) >= 0);
      end
    end

    function conditions = get_inequality_feasibility_condition_MPT3(A, b)
      % MPT3を用いて、不等式 Ax <= b が解を持つための条件式を導出する
      %
      % Parameters:
      %   A (sym[]): 線形不等式制約の係数行列 (シンボリック変数を含んでよいが、数値に変換される)
      %   b (sym[]): 線形不等式制約の定数項 (シンボリック変数を含んでよい)
      %
      % --- MPT3を用いた手法の概要 ---
      % このアルゴリズムは、Farkas の補題を用いて不等式系の実行可能性条件を導出する。
      % 1. Aの各行を有理化し、最小公倍数で整数化してA_numを得る (スケーリング係数を記録)
      % 2. 双対問題として y >= 0, A_num' * y = 0 を満たすyの集合を多面体として構築
      % 3. 多面体の極線(Rays)を計算する
      % 4. 各極線に対して、スケーリングを補正した上で y' * b >= 0 の条件式を生成
      % 5. これらの条件式が全て満たされるとき、元の不等式系は実行可能である
      % =========================================================================

      [m, n] = size(A);
      conditions = sym.empty(0, 1);
      
      A_sym = sym(A);
      A_num = zeros(m, n);
      scaling_factors = zeros(m, 1);
      
      for i = 1:m
        row = A_sym(i, :);
        [~, denoms] = numden(row);
        
        % この行だけの最小公倍数を計算
        row_lcm = 1;
        denoms_unique = unique(denoms);
        for k = 1:length(denoms_unique)
          row_lcm = lcm(sym(row_lcm), denoms_unique(k));
        end
        
        scaling_factors(i) = double(row_lcm);
        
        A_num(i, :) = double(row * row_lcm);
      end
      
      % MPT3設定
      mpt_options = mptopt;
      mpt_options.modules.geometry.convexhull = 'cdd';

      P = Polyhedron('A', -eye(m), 'b', zeros(m, 1), ...
                     'Ae', A_num', 'be', zeros(n, 1));
      
      % 極線(Rays)の計算
      P.computeVRep();
      rays_raw = P.R; % これはスケーリングされたAに対する極線
      
      for k = 1:size(rays_raw, 1)
        y_raw = rays_raw(k, :);
        
        % --- 重要: スケーリングの補正 ---
        % Aのi行目を L_i 倍していた場合、対応する双対変数 y_i も
        % 整合性を取るために L_i 倍する必要があります。
        % (論理: (L*A)' * y_raw = A' * (L * y_raw) = 0 なので、真のyは L * y_raw)
        
        y_corrected = y_raw .* scaling_factors';
        
        % 数値誤差の除去
        y_corrected(abs(y_corrected) < 1e-8) = 0;
        
        % 正規化 & 有理化
        nz_vals = y_corrected(y_corrected > 0);
        if ~isempty(nz_vals)
          scale = min(nz_vals);
          y_final = y_corrected / scale;
        else
          y_final = y_corrected;
        end
        
        % シンボリックに戻す
        y_sym = sym(y_final, 'r'); 
        
        % 条件式生成
        lhs_expr = y_sym * b; 
        cond = simplify(lhs_expr) >= 0;
        conditions(end+1) = cond;
      end
    end

    function [A_new, b_new] = get_reduced_matrix(A_eq, b_eq, A_ineq, b_ineq)
      % 等式制約を用いて変数を削減し、縮小された不等式制約行列を取得する
      %
      % 処理の概要:
      %   1. 線形等式制約 Ax = b を解き、一般解を求める
      %      x = x_p + N * x_free
      %      ここで、x_p は特解、N は零空間の基底行列（あるいは自由変数への変換行列）
      %      本実装では、変数を従属変数 x_dep と自由変数 x_free に分離し、
      %      x = T * x_free + C の形式で表現する。
      %
      %   2. 得られた表現を不等式制約 A_ineq * x <= b_ineq に代入する
      %      A_ineq * (T * x_free + C) <= b_ineq
      %      (A_ineq * T) * x_free <= b_ineq - A_ineq * C
      %
      %   3. 新しい係数行列 A_new = A_ineq * T と b_new = b_ineq - A_ineq * C を返す
      %
      % Parameters:
      %   A_eq (double[] | sym[]): 等式制約の係数行列
      %   b_eq (sym[]): 等式制約の定数項
      %   A_ineq (double[] | sym[]): 不等式制約の係数行列
      %   b_ineq (sym[]): 不等式制約の定数項
      %
      % Returns:
      %   A_new: 縮小された不等式制約の係数行列
      %   b_new: 縮小された不等式制約の定数項

      % STEP 1: 線形システムを解析し、行階段形(RREF)と変数の分類を行う
      [R, pivot_cols, free_cols, n_vars, is_sym] = EqualityInequalityHelper.analyze_linear_system(A_eq, b_eq);

      % STEP 2: 解の存在を確認する（矛盾式 0 = non_zero がないか）
      if ~EqualityInequalityHelper.is_consistent(R, n_vars)
        warning('等式制約を満たす解が存在しません');
        % 解なしを示すため、自明な矛盾不等式 (0 <= -1) を返す
        A_new = zeros(1, length(free_cols));
        b_new = -1; 
        return;
      end

      % STEP 3: 変数置換のための行列 T とベクトル C を構築する
      % 全変数 x を自由変数 x_free で表現する: x = T * x_free + C
      [T, C] = EqualityInequalityHelper.construct_substitution_matrix(R, pivot_cols, free_cols, n_vars, is_sym);

      % STEP 4: 不等式制約へ代入し、縮小された行列を計算する
      % A_ineq * x <= b_ineq
      % => A_ineq * (T * x_free + C) <= b_ineq
      % => (A_ineq * T) * x_free <= b_ineq - A_ineq * C
      A_new = A_ineq * T;
      b_new = b_ineq - A_ineq * C;
    end

    function [R, pivot_cols, free_cols, n_vars, is_sym] = analyze_linear_system(A, b)
      % 線形方程式系 Ax = b の拡大係数行列を解析し、変数の分類と標準形を計算する
      %
      % 処理の詳細:
      %   1. 拡大係数行列 M = [A, b] を構築する
      %   2. ガウス・ジョルダン消去法を用いて、M を行簡約階段形 (RREF: Reduced Row Echelon Form) に変換する
      %      これにより、変数の依存関係が明確になる。
      %   3. 各行の主成分（ピボット）の位置を特定し、変数を以下の2種類に分類する:
      %      - 従属変数 (Pivot variables): 他の変数で一意に決定される変数
      %      - 自由変数 (Free variables): 任意の値をとることができる変数（パラメータとなる）
      %
      % 具体例:
      %   以下のような連立方程式を考える:
      %     x_1 + 2*x_2 + 3*x_3 = 4
      %     2*x_1 + 4*x_2 + 6*x_3 = 8
      %
      %   1. 拡大係数行列 M = [A, b]:
      %      [ 1  2  3  |  4 ]
      %      [ 2  4  6  |  8 ]
      %
      %   2. RREF変換後 (2行目は1行目の2倍なので消える):
      %      [ 1  2  3  |  4 ]  <-- 1列目にピボット(1)がある
      %      [ 0  0  0  |  0 ]
      %
      %   3. 変数の分類:
      %      - ピボットがある列: 1列目 -> x_1 は「従属変数」
      %      - ピボットがない列: 2, 3列目 -> x_2, x_3 は「自由変数」
      %
      %   この結果から、解は次のように表現できる:
      %     x_1 = 4 - 2*x_2 - 3*x_3  (自由変数を用いて従属変数を表す)
      %
      %   この例における返り値:
      %     R          = [1, 2, 3, 4; 0, 0, 0, 0]  (RREF変換後の拡大係数行列)
      %     pivot_cols = [1]                       (従属変数の列インデックス)
      %     free_cols  = [2, 3]                    (自由変数の列インデックス)
      %     n_vars     = 3                         (変数の総数)
      %     is_sym     = false                     (数値入力の場合)
      %
      % Parameters:
      %   A (double[] | sym[]): 係数行列 (m x n)
      %   b (double[] | sym[]): 定数項ベクトル (m x 1)
      %
      % Returns:
      %   R: 行簡約階段形 (RREF) に変換された拡大係数行列
      %   pivot_cols: ピボット（主成分）が存在する列のインデックス配列（従属変数に対応）
      %   free_cols: ピボットが存在しない列のインデックス配列（自由変数に対応）
      %   n_vars: 変数の総数 (n)
      %   is_sym: 入力がシンボリック形式だったかどうかのフラグ
      
      [~, n_vars] = size(A);
      is_sym = isa(A, 'sym') || isa(b, 'sym');
      
      % 拡大係数行列 [A | b]
      M = [A, b];
      
      if is_sym
        % シンボリック行列の場合のRREF計算
        % rrefは行列の行基本変形を行い、左下の成分を0にする
        R = rref(M);
        
        % ピボット列（各行の最初の非ゼロ要素がある列）を特定
        % これらは従属変数に対応する
        pivot_cols = [];
        [n_rows, ~] = size(R);
        for i = 1:n_rows
          for j = 1:n_vars
             if ~isequal(R(i, j), sym(0))
               pivot_cols = [pivot_cols, j];
               break; % 次の行へ
             end
          end
        end
      else
        % 数値行列の場合はMATLABの組み込み関数がピボット列も返してくれる
        [R, pivot_cols] = rref(M);
      end
      
      % 自由変数の列インデックス（ピボットでない列）
      free_cols = setdiff(1:n_vars, pivot_cols);
    end

    function consistent = is_consistent(R, n_vars)      % 拡大係数行列のRREFを検査し、連立方程式に解が存在するか（矛盾がないか）を判定する
      %
      % 処理の詳細:
      %   行列 R の各行について、「係数部分がすべてゼロ」かつ「定数項が非ゼロ」であるかを確認する。
      %   そのような行が存在する場合、それは 0 = c (c≠0) という矛盾した式を意味するため、解なしとなる。
      %
      % Parameters:
      %   R (double[] | sym[]): RREF変換後の拡大係数行列
      %   n_vars (int): 変数の数（係数部分の列数）
      %
      % Returns:
      %   consistent (bool): 解が存在する場合（矛盾がない場合）は true、解なしの場合は false
      %
      % 具体例1（解あり）:
      %   R = [1, 0, 2; 0, 1, 3]  (n_vars=2)
      %   式: x_1 = 2, x_2 = 3
      %   -> 係数がゼロで定数が非ゼロの行はない。
      %   -> 返り値: consistent = true
      %
      % 具体例2（解なし・矛盾）:
      %   R = [1, 2, 4; 0, 0, 5]  (n_vars=2)
      %   式: x_1 + 2*x_2 = 4
      %       0*x_1 + 0*x_2 = 5  (つまり 0 = 5) -> 矛盾！
      %   -> 返り値: consistent = false
      
      A_part = R(:, 1:n_vars);
      b_part = R(:, end);
      
      % 係数部分がすべてゼロの行を探す
      if isa(R, 'sym')
         is_zero_row = arrayfun(@(i) all(A_part(i, :) == 0), (1:size(A_part, 1))');
         is_b_nonzero = arrayfun(@(i) b_part(i) ~= 0, (1:size(b_part, 1))');
      else
         is_zero_row = all(A_part == 0, 2);
         is_b_nonzero = b_part ~= 0;
      end
      
      % 「係数が全てゼロ」かつ「定数項が非ゼロ」の行があれば矛盾 (0 = c, c!=0)
      consistent = ~any(is_zero_row & is_b_nonzero);
    end

    function [T, C] = construct_substitution_matrix(R, pivot_cols, free_cols, n_vars, is_sym)
      % 全変数 x を自由変数 x_free で表すための行列 T とベクトル C を構築する
      % 目的: x = T * x_free + C という形式を作る
      %
      % 数学的背景:
      %   RREFから得られる方程式系は以下の形式になる（変数を並べ替えたと仮定）:
      %     [ I  |  F ] * [ x_pivot ] = [ d ]
      %                   [ x_free  ]
      %
      %   これを展開すると:
      %     x_pivot + F * x_free = d
      %     x_pivot = -F * x_free + d
      %
      %   x_free はそのまま恒等式:
      %     x_free = I * x_free
      
      n_free = length(free_cols);
      
      if is_sym
        T = sym(zeros(n_vars, n_free));
        C = sym(zeros(n_vars, 1));
      else
        T = zeros(n_vars, n_free);
        C = zeros(n_vars, 1);
      end
      
      % 1. 自由変数自体の関係式 (x_free_k = x_free_k)
      % Tの対応する行に単位行列の成分を入れる
      for k = 1:n_free
        row_idx = free_cols(k); % 元の変数ベクトル x におけるインデックス
        T(row_idx, k) = 1;
      end
      
      % 2. 従属変数(ピボット変数)を自由変数で表現する関係式
      % x_pivot_i = b_rref_i - sum( R(i, free_j) * x_free_j )
      for k = 1:length(pivot_cols)
        p_idx = pivot_cols(k); % 変数 x のインデックス
        r_idx = k;             % RREFにおける行インデックス（ピボット変数は行ごとに順に現れる）
        
        % 定数項の設定 C(p_idx) = b_rref(r_idx)
        C(p_idx) = R(r_idx, end);
        
        % 自由変数の係数を設定 T(p_idx, :)
        % 移項するため符号が反転する: x_pivot + coeff * x_free = rhs  =>  x_pivot = -coeff * x_free + rhs
        for m = 1:n_free
          f_idx = free_cols(m);  % 自由変数の元の列インデックス
          coeff = R(r_idx, f_idx);
          T(p_idx, m) = -coeff;
        end
      end
    end

    function ineq_normalized = normalize_inequality(ineq, target_var, num_digits)
      % 不等式を指定した変数を基準に正規化して表示する
      %
      % Parameters:
      %   ineq (sym): 不等式
      %   target_var (char): 正規化する変数
      %   num_digits (int): 小数点以下の桁数
      %
      % Returns:
      %   ineq_normalized (sym): 正規化された不等式

      % symtrueもしくはsymfalseの場合はそのまま返す
      if isAlways(ineq) || isAlways(~ineq)
        ineq_normalized = ineq;
        return;
      end

      % 1. 右辺 - 左辺 >= 0 の多項式を取得
      poly = rhs(ineq) - lhs(ineq);

      % 2. target_varの係数を取得
      k = double(diff(poly, sym(target_var)));

      % 3. 多項式をtarget_varの係数で割る
      poly = poly / k;

      % 4. 多項式を正規化
      ineq_normalized = poly >= 0;

      % 5. 多項式を小数点以下の桁数で表示
      ineq_normalized = vpa(ineq_normalized, num_digits);
    end
  end
end
