classdef PlayerPair
  % PlayerPair クラス
  %
  % マッチングが組まれた時のプレイヤーのペアを表すクラス。
  %

  % properties
  properties
    % プレイヤのペア
    % cell<Player>: 1つもしくは2つの Player オブジェクトを格納するセル配列
    players
  end

  % constructor
  methods
    function obj = PlayerPair(players)
      % PlayerPair クラスのコンストラクタ
      %
      % Parameters:
      %   players (cell<Player>): プレイヤのペアを格納するセル配列
      %
      % Returns:
      %   obj (PlayerPair): 生成された PlayerPair インスタンス

      obj.players = players;

      obj = obj.sort();
      obj.validate();
    end
  end

  % override
  methods
    function result = eq(obj, other)
      % 2つの PlayerPair オブジェクトが等しいか判定する
      %
      % Parameters:
      %   obj (PlayerPair): 1つ目の PlayerPair オブジェクト
      %   other (PlayerPair): 2つ目の PlayerPair オブジェクト
      %
      % Returns:
      %   result (logical): 等しい場合は true, そうでない場合は false

      result = length(obj.players) == length(other.players) && ...
               all(arrayfun(@(x, y) eq(x, y), obj.players, other.players));
    end

    function obj = sort(obj)
      % プレイヤのペアをソートする
      %
      % Returns:
      %   obj (PlayerPair): ソートされた PlayerPair インスタンス

      obj.players = Player.sort_players(obj.players);
    end
  end

  % other
  methods
    function id = id(obj)
      % プレイヤのペアの ID を取得する
      %
      % Returns:
      %   id (char): プレイヤのペアの ID

      ids = Player.ids(obj.players);
      ids = arrayfun(@(x) num2str(x), ids, 'UniformOutput', false);
      id = strjoin(ids, '-');
    end

    function label = label(obj)
      % プレイヤのペアのラベルを取得する
      %
      % Returns:
      %   label (char): プレイヤのペアのラベル

      labels = Player.labels(obj.players);
      label = char(strjoin(labels, ','));
      label = strcat('{', label, '}');
    end

    function result = has(obj, player)
      % プレイヤのペアに指定されたプレイヤが含まれているか判定する
      %
      % Parameters:
      %   obj (PlayerPair): プレイヤのペアの PlayerPair オブジェクト
      %   player (Player): 判定するプレイヤの Player オブジェクト
      %
      % Returns:
      %   result (logical): 指定されたプレイヤが含まれている場合は true, そうでない場合は false

      result = any(cellfun(@(x) isequal(x, player), obj.players));
    end

    function result = has_taxi(obj)
      % プレイヤのペアにタクシーが含まれているか判定する
      %
      % Returns:
      %   result (logical): タクシーが含まれている場合は true, そうでない場合は false

      result = any(cellfun(@(x) x.is_taxi(), obj.players));
    end

    function player = get_taxi(obj)
      % プレイヤのペアからタクシーを取得する
      %
      % Returns:
      %   player (Player): タクシーの Player オブジェクト

      player = [];
      for i = 1:length(obj.players)
        if obj.players{i}.is_taxi()
          player = obj.players{i};
          break
        end
      end
    end

    function result = has_passenger(obj)
      % プレイヤのペアに乗客が含まれているか判定する
      %
      % Returns:
      %   result (logical): 乗客が含まれている場合は true, そうでない場合は false

      result = any(cellfun(@(x) x.is_passenger(), obj.players));
    end

    function player = get_passenger(obj)
      % プレイヤのペアから乗客を取得する
      %
      % Returns:
      %   player (Player): 乗客の Player オブジェクト

      player = [];
      for i = 1:length(obj.players)
        if obj.players{i}.is_passenger()
          player = obj.players{i};
          break
        end
      end
    end

    function result = is_matched(obj)
      % プレイヤのペアがマッチングされているか判定する
      %
      % Returns:
      %   result (logical): マッチングされている場合は true, そうでない場合は false

      result = obj.has_taxi() && obj.has_passenger();
    end

    function result = is_unmatched(obj)
      % プレイヤのペアがマッチングされていないか判定する
      %
      % Returns:
      %   result (logical): マッチングされていない場合は true, そうでない場合は false

      result = ~obj.is_matched();
    end

    function result = is_unmatched_taxi(obj)
      % プレイヤのペアが未マッチのタクシーであるか判定する
      %
      % Returns:
      %   result (logical): 未マッチのタクシーを含む場合は true, そうでない場合は false

      result = obj.has_taxi() && ~obj.is_matched();
    end

    function result = is_unmatched_passenger(obj)
      % プレイヤのペアが未マッチの乗客であるか判定する
      %
      % Returns:
      %   result (logical): 未マッチの乗客を含む場合は true, そうでない場合は false

      result = obj.has_passenger() && ~obj.is_matched();
    end

    function player = get_removed_player_after_matching(obj)
      % プレイヤのペアからマッチング後に削除されたプレイヤを取得する
      %
      % Returns:
      %   player (Player): 削除されたプレイヤの Player オブジェクト

      % == Assummption ==
      % タクシーは乗客とマッチすると、削除されるのではなく、置き換えられる
      % 乗客はタクシーとマッチすると、削除される
      if obj.is_matched()
        player = obj.get_passenger();
      else
        player = [];
      end
    end

    function [player, new_player] = get_replaced_player_after_matching(obj)
      % プレイヤのペアからマッチング後に置き換えられたプレイヤを取得する
      %
      % Returns:
      %   player (Player): 置き換えられたプレイヤの Player オブジェクト
      %   new_player (Player): 新しいプレイヤの Player オブジェクト

      % == Assummption ==
      % 乗客はタクシーとマッチすると、置き換えられるのではなく、削除される
      % タクシーは乗客とマッチすると、置き換えられる
      if obj.is_matched()
        taxi = obj.get_taxi();
        passenger = obj.get_passenger();

        i = taxi.node;
        j = passenger.node;
        k = passenger.destination_node;

        player = taxi;
        new_player = Player(player.type, k, 0, abs(i - j) + abs(j - k));
      else
        player = [];
        new_player = [];
      end
    end

    function utilities = get_utilities(obj, mode)
      % プレイヤのペアが組まれた時の即時効用を取得する
      %
      % Parameters:
      %   obj (PlayerPair): プレイヤのペアの PlayerPair オブジェクト
      %   mode (char): 'symbolic' または 'numeric' を指定する。 'symbolic' の場合はシンボリックなユーティリティを返し、 'numeric' の場合は数値的なユーティリティを返す。
      % Returns:
      %   utilities (cell): プレイヤのペアのユーティリティを格納するセル配列

      all_possible_players = Player.get_all_possible_players();

      if strcmp(mode, 'symbolic')
        [~, ~, ~, u_v_positive, u_v_negative, ~, ~, u_ps_positive, u_ps_negative, ~, ~, ~, ~] = ParamsHelper.get_symbolic_params();
        utilities = sym(zeros(length(all_possible_players), 1));
      elseif strcmp(mode, 'numeric')
        [~, ~, ~, u_v_positive, u_v_negative, ~, ~, u_ps_positive, u_ps_negative, ~, ~, ~, ~, ~, ~] = ParamsHelper.get_valued_params();
        utilities = zeros(length(all_possible_players), 1);
      else
        error('modeは''symbolic''または''numeric''でなければなりません');
      end

      taxi = obj.get_taxi();
      passenger = obj.get_passenger();

      if obj.is_matched()
        i = taxi.node;
        j = passenger.node;
        k = passenger.destination_node;

        utilities(taxi.index()) = u_v_positive(i,j,k);
        utilities(passenger.index()) = u_ps_positive(i,j);
      elseif obj.is_unmatched_taxi()
        utilities(taxi.index()) = u_v_negative;
      elseif obj.is_unmatched_passenger()
        j = passenger.node;
        utilities(passenger.index()) = u_ps_negative(j);
      end
    end

    function expr = non_bp_condition( ...
      obj, player_set, current_policy, expected_utility_solutions ...
    )
      % プレイヤペアobjが、プレイヤ集合player_setにおいて、方策current_policyの下でBPとならない条件式を取得する
      %
      % Parameters:
      %   obj (PlayerPair): プレイヤペア
      %   player_set (cell<Player>): プレイヤ集合
      %   current_policy (Policy): 方策
      %   expected_utility_solutions (cell<ExpectedUtilitySolution>): すべての方策ごとに計算された期待効用の計算結果。セル配列の順番は、Policy.get_all_possible_policies()の順番と一致する。
      %
      % Returns:
      %   expr (sym): BPとならない条件式

      expr = symtrue;

      % 1. 検査対象のペアに含まれるプレイヤの数が1以下の場合は、検査対象のペアobjは必ずnon-BPである
      if length(obj.players) <= 1
        return;
      end
      
      % 2. 方策逸脱集合に含まれる全ての逸脱方策policy_deviatedについて、
      % ペアに含まれるいずれかのプレイヤの期待効用が厳密に改善されない場合は、検査対象のペアobjはBPではない。
      deviated_policies = current_policy.get_deviated_policies_set( ...
        obj, player_set ...
      );
      current_policy_index = current_policy.index();
      for i = 1:length(deviated_policies)
        deviated_policy = deviated_policies{i};
        deviated_policy_index = deviated_policy.index();

        expr_ = symfalse;
        for j = 1:length(obj.players)
          player = obj.players{j};
          expected_utility_under_current_policy = VariablesHelper.get_solution_expected_utility( ...
            player_set, ...
            player, ...
            expected_utility_solutions{current_policy_index} ...
          );
          expected_utility_under_deviated_policy = VariablesHelper.get_solution_expected_utility( ...
            player_set, ...
            player, ...
            expected_utility_solutions{deviated_policy_index} ...
          );
          expr_ = or(expr_, expected_utility_under_deviated_policy <= expected_utility_under_current_policy);
        end

        expr = and(expr, expr_);
      end
    end

    function expr = non_ebp_condition( ...
      obj, player_set, current_policy, expected_utility_solutions ...
    )
      % プレイヤペアobjが、プレイヤ集合player_setにおいて、方策current_policyの下でEBPとならない条件式を取得する
      %
      % Parameters:
      %   obj (PlayerPair): プレイヤペア
      %   player_set (cell<Player>): プレイヤ集合
      %   current_policy (Policy): 方策
      %   expected_utility_solutions (cell<ExpectedUtilitySolution>): すべての方策ごとに計算された期待効用の計算結果。セル配列の順番は、Policy.get_all_possible_policies()の順番と一致する。
      %
      % Returns:
      %   expr (sym): EBPとならない条件式

      expr = symtrue;

      % 1. 検査対象のペアに含まれるプレイヤの数が1以下の場合は、検査対象のペアobjは必ずnon-EBPである
      if length(obj.players) <= 1
        return;
      end
      
      % 2. 方策逸脱集合に含まれる全ての逸脱方策policy_deviatedについて、
      % ペア内での期待効用の合計が厳密に改善されない場合は、検査対象のペアobjはEBPではない。
      deviated_policies = current_policy.get_deviated_policies_set( ...
        obj, player_set ...
      );
      current_policy_index = current_policy.index();
      for i = 1:length(deviated_policies)
        deviated_policy = deviated_policies{i};
        deviated_policy_index = deviated_policy.index();

        sum_of_expected_utility_in_pair_under_current_policy = 0;
        sum_of_expected_utility_in_pair_under_deviated_policy = 0;
        for j = 1:length(obj.players)
          player = obj.players{j};
          sum_of_expected_utility_in_pair_under_current_policy = ...
            sum_of_expected_utility_in_pair_under_current_policy + ...
              VariablesHelper.get_solution_expected_utility( ...
                player_set, ...
                player, ...
                expected_utility_solutions{current_policy_index} ...
              );
          sum_of_expected_utility_in_pair_under_deviated_policy = ...
            sum_of_expected_utility_in_pair_under_deviated_policy + ...
              VariablesHelper.get_solution_expected_utility( ...
                player_set, ...
                player, ...
                expected_utility_solutions{deviated_policy_index} ...
              );
        end
        expr_ = sum_of_expected_utility_in_pair_under_deviated_policy <= sum_of_expected_utility_in_pair_under_current_policy;
        expr = and(expr, expr_);
      end
    end
  end

  % static methods
  methods (Static)
    function ids = ids(player_pairs)
      % プレイヤのペアの ID を取得する
      %
      % Parameters:
      %   player_pairs (cell<PlayerPair>): プレイヤのペアのセル配列
      %
      % Returns:
      %   ids (cell): プレイヤのペアの ID を格納するセル配列

      ids = cell(length(player_pairs), 1);
      for i = 1:length(player_pairs)
        ids{i} = player_pairs{i}.id();
      end
    end

    function player_pairs = sort_player_pairs(player_pairs)
      % プレイヤのペアをソートする
      %
      % Parameters:
      %   player_pairs (cell<PlayerPair>): プレイヤのペアのセル配列
      %
      % Returns:
      %   player_pairs (cell<PlayerPair>): ソートされたプレイヤのペアのセル配列

      ids = PlayerPair.ids(player_pairs);
      [~, idx] = sort(ids);
      player_pairs = player_pairs(idx);
    end

    function labels = labels(player_pairs)
      % プレイヤのペアのラベルを取得する
      %
      % Parameters:
      %   player_pairs (cell<PlayerPair>): プレイヤのペアのセル配列
      %
      % Returns:
      %   labels (cell): プレイヤのペアのラベルを格納するセル配列

      labels = cell(length(player_pairs), 1);
      for i = 1:length(player_pairs)
        labels{i} = player_pairs{i}.label();
      end
    end
  end

  % validation
  methods
    function validate(obj)
      % プレイヤのペアを検証する
      %
      % Parameters:
      %   obj (PlayerPair): プレイヤのペアの PlayerPair オブジェクト

      if ~iscell(obj.players)
        error('プレイヤのペアはセル配列でなければなりません');
      end

      if length(obj.players) < 1 || length(obj.players) > 2
        error('プレイヤのペアに含まれるプレイヤの数は1または2でなければなりません');
      end

      for i = 1:length(obj.players)
        obj.players{i}.validate();
      end
    end
  end
end