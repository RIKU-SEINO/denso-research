classdef PlayerMatching
  % PlayerMatching クラス
  %
  % プレイヤ集合において組まれたマッチングを表すクラス。
  %

  % properties
  properties
    % プレイヤのペア
    % cell<PlayerPair>: プレイヤのペアを格納するセル配列
    player_pairs
  end

  % constructor
  methods
    function obj = PlayerMatching(player_pairs)
      % PlayerMatching クラスのコンストラクタ
      %
      % Parameters:
      %   player_pairs (cell<PlayerPair>): プレイヤのペアを格納するセル配列
      %
      % Returns:
      %   obj (PlayerMatching): 生成された PlayerMatching インスタンス

      obj.player_pairs = player_pairs;

      obj = obj.sort();
    end
  end

  % override
  methods
    function result = eq(obj, other)
      % 2つの PlayerMatching オブジェクトが等しいか判定する
      %
      % Parameters:
      %   obj (PlayerMatching): 1つ目の PlayerMatching オブジェクト
      %   other (PlayerMatching): 2つ目の PlayerMatching オブジェクト
      %
      % Returns:
      %   result (logical): 等しい場合は true, そうでない場合は false

      result = length(obj.player_pairs) == length(other.player_pairs) && ...
               all(arrayfun(@(x, y) isequal(x, y), obj.player_pairs, other.player_pairs));
    end

    function obj = sort(obj)
      % プレイヤのペアをソートする
      % 
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   obj (PlayerMatching): ソートされた PlayerMatching インスタンス

      obj.player_pairs = PlayerPair.sort_player_pairs(obj.player_pairs);
    end

    function result = has(obj, player_pair)
      % 指定されたプレイヤペアが、このプレイヤマッチングに含まれているかを判定する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   player_pair (PlayerPair): 判定対象のプレイヤペア
      %
      % Returns:
      %   result (logical): 指定されたプレイヤペアが、このプレイヤマッチングに含まれている場合は true, そうでない場合は false

      result = Utils.ismember(player_pair, obj.player_pairs);
    end
    
  end

  % other methods
  methods
    function id = id(obj)
      % マッチングのIDを取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   id (char): マッチングのIDを表す文字列
      ids = PlayerPair.ids(obj.player_pairs);
      id = char(strjoin(string(ids), '_'));
    end

    function label = label(obj)
      % マッチングのラベルを取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   label (char): マッチングのラベルを表す文字列
      labels = PlayerPair.labels(obj.player_pairs);
      label = char(strjoin(string(labels), ','));
      label = strcat('{', label, '}');
    end

    function player_set = get_player_set_before_matching(obj)
      % マッチング前のプレイヤ集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_set (PlayerSet): マッチング前のプレイヤ集合

      player_set = PlayerSet({});
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        player_set = player_set.add_all(player_pair.players);
      end
    end

    function player_set = get_player_set_after_matching(obj)
      % マッチング後のプレイヤ集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_set (PlayerSet): マッチング後のプレイヤ集合

      player_set = obj.get_player_set_before_matching();
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        
        removed_player = player_pair.get_removed_player_after_matching();
        player_set = player_set.remove(removed_player);

        [replaced_player, replaced_player_new] = player_pair.get_replaced_player_after_matching();

        player_set = player_set.replace(replaced_player, replaced_player_new);
      end
    end

    function result = matched(obj, player)
      % 指定したプレイヤがマッチングでマッチされたかを取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   player (Player): プレイヤ
      %
      % Returns:
      %   result (logical): プレイヤがマッチングされた場合は true, そうでない場合は false

      result = false;
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        if player_pair.has(player) && player_pair.is_matched()
          result = true;
          return;
        end
      end
    end

    function players = get_unmatched_players(obj)
      % このマッチングでマッチしない全てのプレイヤを取得する。
      % ただし、そもそもプレイヤ集合に属していないプレイヤは除かれる。
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   players (cell<Player>): このマッチングでマッチしない全てのプレイヤのセル配列

      players = {};
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        if player_pair.is_unmatched()
          % 対象のプレイヤペアについてforを回しているので、そもそもプレイヤ集合に属していないプレイヤは除枯れる
          players_in_player_pair = player_pair.players;
          for j = 1:length(players_in_player_pair)
            players{end + 1} = players_in_player_pair{j};
          end
        end
      end
    end

    function player_after_matching = get_player_after_matching(obj, player)
      % 指定したプレイヤがマッチング後にどのプレイヤになるかを取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   player (Player): プレイヤ
      %
      % Returns:
      %   player_after_matching (Player): マッチング後のプレイヤ

      
      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        if player_pair.has(player)
          % == assumption ==
          % タクシーはマッチすると、置き換えられる
          if player_pair.is_matched() && player.is_taxi()
            [~, player_after_matching] = player_pair.get_replaced_player_after_matching();
            break;
          % == assumption ==
          % 乗客はマッチすると、削除される
          elseif player_pair.is_matched() && player.is_passenger()
            player_after_matching = [];
            break;
          % == assumption ==
          % マッチしないプレイヤはそのまま残る
          else
            player_after_matching = player;
            break;
          end
        end
      end
    end

    function utilities = get_utilities_with_incentive(obj, policy, mode)
      % マッチングを組んだ時の即時効用を全てのプレイヤについて取得する。
      % ただし、指定したマッチングobjが、方策policyに従ったものであれば、インセンティブを付与する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   policy (Policy): 方策
      %   mode (char): 'symbolic' または 'numeric' を指定する。
      %
      % Returns:
      %   utilities (cell<sym|double>): マッチングの即時効用を格納するセル配列

      all_possible_players = Player.get_all_possible_players();
      utilities = sym(zeros(length(all_possible_players), 1));

      player_set = obj.get_player_set_before_matching();

      for i = 1:length(obj.player_pairs)
        player_pair = obj.player_pairs{i};
        utilities = utilities + player_pair.get_utilities(mode);
        if policy.has(obj) % 方策に従ったマッチングであれば、インセンティブを付与する
          players_in_player_pair = player_pair.players;
          for j = 1:length(players_in_player_pair)
            player = players_in_player_pair{j};
            if ParamsHelper.should_create_incentive(player_set, player) % 
              utilities(player.index()) = utilities(player.index()) + ParamsHelper.get_incentive(player_set, player);
            end
          end
        end
      end
    end

    function utility = get_utility_of_player_with_incentive(obj, player, policy, mode)
      % 指定したプレイヤの即時効用を取得する。ただし、指定したマッチングobjが、方策policyに従ったものであれば、インセンティブを付与する。
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   player (Player): プレイヤ
      %   policy (Policy): 方策
      %   mode (char): 'symbolic' または 'numeric' を指定する。
      %
      % Returns:
      %   utility (sym|double): プレイヤのユーティリティ

      utilities = obj.get_utilities_with_incentive(policy, mode);
      utility = utilities(player.index());
    end

    function utility = get_utility_sum_with_incentive(obj, policy, mode)
      % マッチングを組んだ時の即時効用の合計を取得する(=R)
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   mode (char): 'symbolic' または 'numeric' を指定する。
      %
      % Returns:
      %   utility (sym|double): マッチングのユーティリティの合計

      utilities = obj.get_utilities_with_incentive(policy, mode);
      utility = sum(utilities);
    end

    function action_value = get_action_value_with_incentive(obj, policy)
      % マッチングを組んだ時の行動価値（＝即時報酬の和＋遷移後の状態価値）を取得する。
      % ただし、指定したマッチングobjが、方策policyに従ったものであれば、インセンティブを付与する。
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   policy (Policy): 方策
      %
      % Returns:
      %   action_value (sym): マッチングの行動価値
      [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, g, q] = ParamsHelper.get_symbolic_params();

      player_set = obj.get_player_set_after_matching();
      player_sets_after_transition = player_set.get_all_possible_player_sets_after_transition();

      action_value = obj.get_utility_sum_with_incentive(policy, 'symbolic');
      for i = 1:length(player_sets_after_transition)
        player_set_after_transition = player_sets_after_transition{i};
        state_value_after = VariablesHelper.get_state_value(player_set_after_transition);
        action_value = action_value + g * q(i) * state_value_after;
      end
    end

    function action_value_of_player = get_action_value_of_player_with_incentive(obj, player, policy)
      % マッチングを組んだ時の指定したプレイヤの行動価値（＝プレイヤの即時報酬＋遷移後のプレイヤの期待効用）を取得する。
      % ただし、指定したマッチングobjが、方策policyに従ったものであれば、インセンティブを付与する。
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   player (Player): プレイヤ
      %   policy (Policy): 方策
      %
      % Returns:
      %   action_value_of_player (sym): プレイヤの行動価値

      [~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, g, q] = ParamsHelper.get_symbolic_params();

      if obj.get_player_set_before_matching().has(player)
        action_value_of_player = obj.get_utility_of_player_with_incentive(player, policy, 'symbolic');
      else
        action_value_of_player = sym(0); % マッチ前のプレイヤ集合に含まれないプレイヤは、行動価値が0
        return;
      end

      player_set_after_matching = obj.get_player_set_after_matching();
      player_after_matching = obj.get_player_after_matching(player);

      if isempty(player_after_matching) % マッチした後、プレイヤが消失しているので、プレイヤの行動価値は即時報酬のみ
        return
      end

      player_sets_after_transition = player_set_after_matching.get_all_possible_player_sets_after_transition();
      player_after_transition = player_after_matching.one_step_elapsed();

      for i = 1:length(player_sets_after_transition)
        player_set_after_transition = player_sets_after_transition{i};
        expected_utility_of_player = VariablesHelper.get_expected_utility(player_set_after_transition, player_after_transition);
        action_value_of_player = action_value_of_player + g * q(i) * expected_utility_of_player;
      end
    end

    function player_matchings = get_all_possible_player_matchings(obj)
      % objで指定したプレイヤマッチングが組まれるようなプレイヤ集合において考えられる全てのプレイヤマッチングの集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列

      player_set = obj.get_player_set_before_matching();
      player_matchings = player_set.get_all_possible_player_matchings();
    end

    function player_matchings = get_all_possible_player_matchings_except_obj(obj)
      % マッチングobjが組まれるようなプレイヤ集合について、
      % マッチングobj以外のプレイヤマッチングの集合を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): マッチングobj以外のプレイヤマッチングの集合を格納するセル配列

      all_possible_player_matchings = obj.get_all_possible_player_matchings();
      player_matchings = Utils.obj_setdiff(all_possible_player_matchings, {obj});
    end

    function expr = optimality_condition(obj, current_policy, state_value_solutions)
      % 指定したプレイヤマッチングが方策current_policyに従った場合に最適である場合の条件式を取得する
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   current_policy (Policy): 現在の方策
      %   state_value_solutions (cell<StateValueSolution>): すべての方策ごとに計算された状態価値の計算結果。セル配列の順番は、Policy.get_all_possible_policies()の順番と一致する。
      %
      % Returns:
      %   expr (sym): プレイヤマッチングのシンボリック条件式

      other_player_matchings = obj.get_all_possible_player_matchings_except_obj();
      expr = symtrue;
      solution = state_value_solutions{current_policy.index()};
      for i = 1:length(other_player_matchings)
        other_player_matching = other_player_matchings{i};
        other_action_value = other_player_matching.get_action_value_with_incentive(current_policy);
        action_value = obj.get_action_value_with_incentive(current_policy);

        expr = expr & (other_action_value <= action_value);
      end

      expr = ParamsHelper.evaluate_all_params(expr);
      expr = subs(expr, solution.variables, solution.values);
    end

    function expr = stability_condition(obj, stability_type, current_policy, expected_utility_solutions)
      % 指定したマッチングobjが方策current_policyの下で安定であるための条件式を取得する。
      % 安定性の種類はstability_typeで指定する。
      %
      % Parameters:
      %   obj (PlayerMatching): PlayerMatching インスタンス
      %   stability_type (string): 安定性の種類。'BP' または 'EBP' のいずれか
      %   current_policy (Policy): 現在の方策
      %   expected_utility_solutions (cell<ExpectedUtilitySolution>): すべての方策ごとに計算された期待効用の計算結果。セル配列の順番は、Policy.get_all_possible_policies()の順番と一致する。
      %
      % Returns:
      %   expr (sym): 指定したマッチングobjが方策current_policyの下で安定であるための条件式

      expr = symtrue;
      player_set = obj.get_player_set_before_matching();
      all_possible_player_pairs = player_set.get_all_possible_player_pairs();
      for i = 1:length(all_possible_player_pairs)
        player_pair = all_possible_player_pairs{i};
        if obj.has(player_pair)
          continue;
        end

        if strcmp(stability_type, 'BP')
          non_bp_condition_expr = player_pair.non_bp_condition( ...
            player_set, ...
            current_policy, ...
            expected_utility_solutions ...
          );
          expr = and(expr, non_bp_condition_expr);
        elseif strcmp(stability_type, 'EBP')
          non_ebp_condition_expr = player_pair.non_ebp_condition( ...
            player_set, ...
            current_policy, ...
            expected_utility_solutions ...
          );
          expr = and(expr, non_ebp_condition_expr);
        else
          error('安定性タイプの指定が不正です。''BP''または''EBP''を指定してください。指定されたタイプ: %s', stability_type);
        end
      end
    end
  end

  methods (Static)
    function ids = ids(player_matchings)
      % プレイヤマッチングのIDを取得する
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列
      %
      % Returns:
      %   ids (cell): プレイヤマッチングのIDを格納するセル配列

      ids = cell(length(player_matchings), 1);
      for i = 1:length(player_matchings)
        ids{i} = player_matchings{i}.id();
      end
    end

    function labels = labels(player_matchings)
      % プレイヤマッチングのラベルを取得する
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列
      %
      % Returns:
      %   labels (cell): プレイヤマッチングのラベルを格納するセル配列

      labels = cell(length(player_matchings), 1);
      for i = 1:length(player_matchings)
        labels{i} = player_matchings{i}.label();
      end
    end

    function player_matchings = sort_player_matchings(player_matchings)
      % プレイヤマッチングをソートする。all_player_setsの順番に従ってソートする
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの集合を格納するセル配列
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): ソートされたプレイヤマッチングの集合を格納するセル配列

      player_sets = cell(length(player_matchings), 1);
      for i = 1:length(player_matchings)
        player_set = player_matchings{i}.get_player_set_before_matching();
        player_sets{i} = player_set;
      end
      
      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      [~, sorted_indices] = sort(cellfun(@(x) find(Utils.ismember(x, all_possible_player_sets)), player_sets));
      player_matchings = player_matchings(sorted_indices);
    end
  end
end