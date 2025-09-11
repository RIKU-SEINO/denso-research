classdef ParamsHelper
  methods (Static)
    function result = should_create_incentive(player_set, player)
      % プレイヤ集合において、考えられる全てのプレイヤマッチングが複数あり、かつそのプレイヤ集合においてプレイヤが含まれている場合に、インセンティブを作成するか判定する
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤ集合
      %   player (Player): プレイヤ
      %
      % Returns:
      %   result (logical): インセンティブを作成する場合は true, そうでない場合は false

      result = player_set.has_multiple_possible_player_matchings() & player_set.has(player);
    end

    function u = init_incentive()
      % インセンティブの初期化
      % 期待効用と同じように、あるプレイヤ集合において、あるプレイヤに付与するインセンティブをシンボリックに生成する。これは変数ではなくパラメータであるため、ParamsHelperに定義している。
      %
      % Parameters: None
      %
      % Returns:
      %   u (symbolic): インセンティブのシンボリック変数の配列
      persistent u_cache;

      if isempty(u_cache)
        all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
        all_possible_players = Player.get_all_possible_players();
        u_cache = sym(zeros(length(all_possible_player_sets), length(all_possible_players)));
        for i = 1:length(all_possible_player_sets)
          player_set = all_possible_player_sets{i};
          for j = 1:length(all_possible_players)
            player = all_possible_players{j};
            varname = strcat('u_', player_set.label(), '_', player.label());
            varname = matlab.lang.makeValidName(varname);
            if ParamsHelper.should_create_incentive(player_set, player)
              syms(varname, 'real');
              u_cache(i, j) = eval(varname);
              fprintf('Created incentive parameter: %s\n', varname);
            else
              u_cache(i, j) = sym(0);
              fprintf('Skipped creating incentive parameter: %s\n', varname);
            end
          end
        end
      end

      u = u_cache;
    end

    function incentives = get_all_incentives_as_vector()
      % すべてのインセンティブを1*nのベクトルとして取得。
      % ただし、インセンティブが0として生成されているものは含めない
      %
      % Parameters:
      %   None
      %
      % Returns:
      %   incentives (sym[]): インセンティブのシンボリック変数の配列

      u = ParamsHelper.init_incentive();

      incentives = u(:).';
      is_not_zero = arrayfun(@(x) ~isempty(symvar(x)), incentives);
      incentives = incentives(is_not_zero);
    end

    function num = get_num_of_incentives()
      % インセンティブの数を取得
      %
      % Parameters:
      %   None
      %
      % Returns:
      %   num (int): インセンティブの数

      num = length(ParamsHelper.get_all_incentives_as_vector());
    end

    function incentive = get_incentive(player_set, player)
      % プレイヤ集合において、方策に従った時にプレイヤに付与するインセンティブを取得する
      %
      % Parameters:
      %   player_set (PlayerSet): プレイヤ集合
      %   player (Player): プレイヤ

      if ~ParamsHelper.should_create_incentive(player_set, player)
        error('考慮されていないインセンティブを取得しようとしました: %s, %s', player_set.label(), player.label());
      end

      u = ParamsHelper.init_incentive();
      incentive = u(player_set.index(), player.index());
    end

    function [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q] = get_symbolic_params()
      persistent cached_params;
      if ~isempty(cached_params)
        [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q] = cached_params{:};
        return;
      end

      % タクシーの即時報酬に関するパラメータ
      syms w c a;
      u_v = ParamsHelper.utility_taxi(w, c, a);
      u_v_positive = u_v{1};
      u_v_negative = u_v{2};

      % 乗客の即時報酬に関するパラメータ
      % == Assumption ==
      % ノード1には乗客は出現しない
      syms r_2 r_3 b_2 b_3;
      r = [0; r_2; r_3];
      b = [0; b_2; b_3];
      u_ps = ParamsHelper.utility_passenger(r, b);
      u_ps_positive = u_ps{1};
      u_ps_negative = u_ps{2};

      % 乗客の出現に関するパラメータ
      syms p_2 p_3;
      p = [0; p_2; p_3];
      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];

      % 割引率
      syms g;

      % 一般の場合はtrans_prob_vecを使う
      % q = ParamsHelper.trans_prob_vec(p, p_);
      % == Assumption ==
      % ps_{2,1}またはps_{3,1}のみ出現することを前提としているので、trans_prob_vec_only_ps21_ps31を使う
      q = ParamsHelper.trans_prob_vec_only_ps21_ps31(p, p_);

      cached_params = {w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q};
    end

    function assume_symbolic_params(varargin)
      % 引数で与えたシンボリック変数についてのみassumeを適用する関数
      %
      % この関数は、シンボリック計算におけるパラメータの制約（assume）を、指定した変数のみに対して適用します。
      % get_symbolic_params 関数で生成されたシンボリック変数を部分的に渡すことで、必要な変数だけに制約を掛けることができます。
      %
      % 使用例：
      %   - すべてのパラメータにassumeを適用する場合：
      %     [w, c, a, u_v_positive, ~, r, b, u_ps_positive, ~, p, ~, g, ~] = ParamsHelper.get_symbolic_params();
      %     ParamsHelper.assume_symbolic_params(w, c, a, u_v_positive, r, b, u_ps_positive, p, g);
      %
      %   - 指定したパラメータ（例: w と g のみ）にassumeを適用する場合：
      %     ... (上記と同じ)
      %     ParamsHelper.assume_symbolic_params(w, g);
      %
      %   - 特定の配列パラメータ（例: r のみ）にassumeを適用する場合：
      %     ParamsHelper.assume_symbolic_params(r);
      %
      % Parameters:
      %   varargin: 可変引数。ParamsHelper.get_symbolic_params() で生成されたシンボリック変数を渡します。
      %             スカラー変数（w, c, a, g, r_2, r_3, b_2, b_3, p_2, p_3）を渡すことができます。
      %             渡された変数のみに対して対応する制約条件が assume されます。
      %
      %             制約条件の詳細：
      %             - w, c, a: > 0
      %             - g: 0 < g < 1
      %             - r_2, r_3, b_2, b_3: > 0
      %             - p_2, p_3: 0 < p < 1
      %
      % Returns: None

      for i = 1:length(varargin)
        var = varargin{i};
        var_name = char(var);

        switch var_name
          case 'w'
            assume(var > 0);
          case 'c'
            assume(var > 0);
          case 'a'
            assume(var > 0);
          case 'g'
            assume(0 < var & var < 1);
          case {'p_2', 'p_3'}
            assume(0 <= var & var <= 1);
          case {'r_2', 'r_3'}
            assume(var > 0);
          case {'b_2', 'b_3'}
            assume(var > 0);
          otherwise
            warning('Unknown parameter name: %s. No assumptions applied.', var_name);
        end
      end
    end

    function [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q, V_init, x_init] = get_valued_params()
      persistent cached_params_valued;
      if ~isempty(cached_params_valued)
        [w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q, V_init, x_init] = cached_params_valued{:};
        return;
      end

      % タクシーの即時報酬に関するパラメータ
      w = 2000;
      c = 10;
      a = 100;
      u_v = ParamsHelper.utility_taxi(w, c, a);
      u_v_positive = double(u_v{1});
      u_v_negative = double(u_v{2});

      % 乗客の即時報酬に関するパラメータ
      r = [0; 1500; 1250];
      b = [0; 100; 50];
      u_ps = ParamsHelper.utility_passenger(r, b);
      u_ps_positive = double(u_ps{1});
      u_ps_negative = double(u_ps{2});

      % 乗客の出現に関するパラメータ
      p = [0; 0.8; 0.2];
      p_ = [0, 0, 0;
            1, 0, 0;
            1, 0, 0];
      
      % 割引率
      g = 0.95;

      % 一般の場合はtrans_prob_vecを使う
      % q = ParamsHelper.trans_prob_vec(p, p_);
      % == Assumption == 
      % ps_{2,1}またはps_{3,1}のみ出現することを前提としているので、trans_prob_vec_only_ps21_ps31を使う
      q = double(ParamsHelper.trans_prob_vec_only_ps21_ps31(p, p_));

      V_init = 1000*ones(1, length(VariablesHelper.init_state_values()));
      x_init = 1000*ones(1, size(VariablesHelper.init_expected_utilities(), 1) * size(VariablesHelper.init_expected_utilities(), 2));

      cached_params_valued = {w, c, a, u_v_positive, u_v_negative, r, b, u_ps_positive, u_ps_negative, p, p_, g, q, V_init, x_init};
    end

    function u_v = utility_taxi(w, c, a)
      u_v_positive = sym(zeros(3, 3, 3));
      for i = 1:3
        for j = 1:3
          for k = 1:3
            u_v_positive(i, j, k) = -c*(abs(i-j)+abs(j-k)) + w*abs(j-k);
          end
        end
      end
      u_v_negative = -a;
      u_v = {u_v_positive, u_v_negative};
    end

    function u_ps = utility_passenger(r, b)
      u_ps_positive = sym(zeros(3, 3));
      for i = 1:3
        for j = 1:3
          u_ps_positive(i, j) = r(j) - b(j)*abs(i-j);
        end
      end
      u_ps_negative = -b;
      u_ps = {u_ps_positive, u_ps_negative};
    end

    function q = trans_prob_vec(p, p_)
      q = sym(zeros(27, 1));

      q(1) = (1 - p(1)) * (1 - p(2)) * (1 - p(3));

      q(2) = p(1)*p_(1, 2) * (1 - p(2)) * (1 - p(3));
      q(3) = p(1)*p_(1, 3) * (1 - p(2)) * (1 - p(3));

      q(4) = (1 - p(1)) * p(2)*p_(2, 1) * (1 - p(3));
      q(5) = (1 - p(1)) * p(2)*p_(2, 3) * (1 - p(3));

      q(6) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * (1 - p(3));
      q(7) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * (1 - p(3));
      q(8) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * (1 - p(3));
      q(9) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * (1 - p(3));

      q(10) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 1);
      q(11) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 2);

      q(12) = p(1)*p_(1, 2) * (1 - p(2)) * p(3)*p_(3, 1);
      q(13) = p(1)*p_(1, 3) * (1 - p(2)) * p(3)*p_(3, 1);
      q(14) = p(1)*p_(1, 2) * (1 - p(2)) * p(3)*p_(3, 2);
      q(15) = p(1)*p_(1, 3) * (1 - p(2)) * p(3)*p_(3, 2);

      q(16) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      q(17) = (1 - p(1)) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      q(18) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      q(19) = (1 - p(1)) * p(2)*p_(2, 3) * p(3)*p_(3, 2);

      q(20) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      q(21) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
      q(22) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      q(23) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * p(3)*p_(3, 1);
      q(24) = p(1)*p_(1, 2) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      q(25) = p(1)*p_(1, 3) * p(2)*p_(2, 1) * p(3)*p_(3, 2);
      q(26) = p(1)*p_(1, 2) * p(2)*p_(2, 3) * p(3)*p_(3, 2);
      q(27) = p(1)*p_(1, 3) * p(2)*p_(2, 3) * p(3)*p_(3, 2);
    end

    function q = trans_prob_vec_only_ps21_ps31(p, p_)
      q = sym(zeros(4, 1));

      q(1) = (1 - p(1)) * (1 - p(2)) * (1 - p(3));

      q(2) = (1 - p(1)) * p(2)*p_(2, 1) * (1 - p(3));

      q(3) = (1 - p(1)) * (1 - p(2)) * p(3)*p_(3, 1);

      q(4) = (1 - p(1)) * p(2)*p_(2, 1) * p(3)*p_(3, 1);
    end

    function params = all_symbolic_params_with_numerical_symbolic_params()
      % すべてのパラメータをシンボリックに取得。ただし、paramsにsym(0)やsym(1)が含まれている場合も含める
      % 
      % Parameters:
      %   None
      %
      % Returns:

      [w, c, a, ~, ~, r, b, ~, ~, p, p_, g, ~] = ParamsHelper.get_symbolic_params();
      params = [
        w, c, a, reshape(r.', 1, []), reshape(b.', 1, []), reshape(p.', 1, []), reshape(p_.', 1, []), g
      ];
    end

    function params = all_symbolic_params()
      % すべてのパラメータをシンボリックに取得。ただし、paramsにsym(0)やsym(1)が含まれている場合も含めない
      % 
      % Parameters:
      %   None
      %
      % Returns:
      %   params (sym[]): シンボリックなパラメータの配列

      params = ParamsHelper.all_symbolic_params_with_numerical_symbolic_params();
      is_not_numeric = arrayfun(@(x) ~isempty(symvar(x)), params);
      params = params(is_not_numeric);
    end

    function params = all_valued_params()
      % すべてのパラメータを数値として取得
      % 
      % Parameters:
      %   None
      %
      % Returns:
      %   params (double[]): 数値に変換したパラメータの配列

      [w, c, a, ~, ~, r, b, ~, ~, p, p_, g, ~] = ParamsHelper.get_valued_params();
      params = [
        w, c, a, reshape(r.', 1, []), reshape(b.', 1, []), reshape(p.', 1, []), reshape(p_.', 1, []), g
      ];

      is_not_numeric = arrayfun(@(x) ~isempty(symvar(x)), ParamsHelper.all_symbolic_params_with_numerical_symbolic_params());
      params = params(is_not_numeric);
    end

    function expr = evaluate_all_params(expr)
      % シンボリックな式のパラメータだけを数値的に評価する
      % 
      % Parameters:
      %   expr (sym): シンボリックな式
      % Returns:
      %   expr (sym): パラメータを数値的に評価した式。変数はsymbolicのまま
      all_symbolic_params = ParamsHelper.all_symbolic_params();
      all_valued_params = ParamsHelper.all_valued_params();

      expr = subs(expr, all_symbolic_params, all_valued_params);
    end

    function expr = evaluate_params(expr, params, is_exclude_mode)
      % シンボリックな式について、指定したパラメータを評価するか、指定したパラメータ以外を評価するかを選択し、それに応じて式を評価する。
      % ただし、インセンティブは常に評価しない仕様になっている。
      % 次に例を示す。ただし、all_symbolic_params=["x", "y"], all_valued_params=[1,2]のケースを考える。
      % ex1. expr=x+y, params=["x"], is_exclude_mode=false: expr=1+y
      % ex2. expr=x+y, params=["x"], is_exclude_mode=true: expr=x+2
      % 
      % Parameters:
      %   expr (sym): シンボリックな式
      %   params (sym): 評価対象のパラメータ
      %   is_exclude_mode (logical): trueなら指定パラメータを除外して評価、falseなら指定パラメータのみ評価
      % Returns:
      %   expr (sym): パラメータを数値的に評価した式。変数や未評価のパラメータはsymbolicのまま
      all_symbolic_params = ParamsHelper.all_symbolic_params();
      all_valued_params = ParamsHelper.all_valued_params();

      % 文字列指定がある場合はシンボルに変換
      if ischar(params) || isstring(params)
        params = cellstr(params);  % string配列をcell配列に
      end
      if iscell(params)
        % 名前からシンボリック変数を抽出
        param_syms = sym.empty(1, 0);
        for i = 1:length(params)
          match_idx = find(arrayfun(@(s) strcmp(char(s), params{i}), all_symbolic_params));
          if ~isempty(match_idx)
            param_syms(end+1) = all_symbolic_params(match_idx);
          end
        end
        params = param_syms;
      end

      if is_exclude_mode
        % 指定されたparamsに一致しないパラメータを探す
        is_target = ~ismember(all_symbolic_params, params);
      else
        % 指定されたparamsに一致するパラメータを探す
        is_target = ismember(all_symbolic_params, params);
      end

      % 対応するsymbolic-paramとその数値を抽出
      target_symbolic_params = all_symbolic_params(is_target);
      target_valued_params   = all_valued_params(is_target);

      % 指定パラメータのみを数値に置き換え
      expr = subs(expr, target_symbolic_params, target_valued_params);
    end

    function expr = incentive_condition()
      % インセンティブに関する制約式を生成する。これは、指定する方策ごとに制約式が異なることに注意。
      % 制約1. 各ステップのインセンティブの収支制約
      %    ・全てのプレイヤ集合について、そのプレイヤ集合に含まれる全てのプレイヤに配分するインセンティブの合計が0になることを制約とする。
      % 制約2. インセンティブ付与時の即時報酬が
      %
      % Parameters:
      %   None
      %
      % Returns:
      %   expr (sym): インセンティブに関する制約式

      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      all_possible_players = Player.get_all_possible_players();

      expr = symtrue;
      for i = 1:length(all_possible_player_sets)
        player_set = all_possible_player_sets{i};
        sum_of_incentives = sym(0);
        for j = 1:length(all_possible_players)
          player = all_possible_players{j};
          if ParamsHelper.should_create_incentive(player_set, player)
            incentive = ParamsHelper.get_incentive(player_set, player);
            sum_of_incentives = sum_of_incentives + incentive;
          end
        end
        expr = expr & (sum_of_incentives == 0);
      end
    end
  end
end
