classdef Policy
  % Policy クラス
  %
  % 期待効用方程式を解く際の方策（=マッチングの組み合わせ）を表すクラス。
  %
  %   具体例:
  %       例えば、プレイヤ集合 P = {P1, P2, P3, P4} があり、各プレイヤ集合ごとに以下のマッチング候補がある場合:
  %           P1 のマッチング候補: {M_{P1,1}, M_{P1,2}}
  %           P2 のマッチング候補: {M_{P2,1}, M_{P2,2}, M_{P2,3}}
  %           P3 のマッチング候補: {M_{P3,1}, M_{P3,2}}
  %           P4 のマッチング候補: {M_{P4,1}}
  %      この時の 方策 として、次の12通りが考えられる。
  %           {M_{P1,1}, M_{P2,1}, M_{P3,1}, M_{P4,1}}
  %           {M_{P1,2}, M_{P2,1}, M_{P3,1}, M_{P4,1}}
  %           ... 
  %           {M_{P1,2}, M_{P2,3}, M_{P3,2}, M_{P4,1}}

  properties
    % 到達可能なプレイヤ集合ごとで最適として選択されたマッチングの組み合わせ
    % 順番は到達可能なプレイヤ集合（=all_possible_player_sets）に従う
    % cell<PlayerMatching>: プレイヤマッチングのcell配列
    player_matchings
  end

  % constructor
  methods
    function obj = Policy(player_matchings)
      % Policy クラスのコンストラクタ
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの配列
      %
      % Returns:
      %   obj (Policy): 生成された Policy インスタンス

      obj.player_matchings = player_matchings;

      obj = obj.sort();
    end
  end

  % override
  methods
    function obj = sort(obj)
      % PolicyのPlayerMatchingをソートする
      %
      % Parameters:
      %   obj (Policy): Policy インスタンス
      %
      % Returns:
      %   obj (Policy): ソートされた Policy インスタンス

      obj.player_matchings = PlayerMatching.sort_player_matchings(obj.player_matchings);
    end

    function result = has(obj, player_matching)
      % 指定されたプレイヤマッチングが、この方策に含まれているかを判定する
      %
      % Parameters:
      %   obj (Policy): Policy インスタンス
      %   player_matching (PlayerMatching): 判定対象のプレイヤマッチング
      %
      % Returns:
      %   result (logical): 指定されたプレイヤマッチングが、この方策に含まれている場合は true, そうでない場合は false

      result = Utils.ismember(player_matching, obj.player_matchings);
    end
  end

  % other
  methods
    function id = id(obj)
      % PolicyのIDを取得する
      %
      % Returns:
      %   id (string): PolicyのID

      ids = PlayerMatching.ids(obj.player_matchings);
      id = char(strjoin(string(ids), '_&&_'));
    end

    function label = label(obj)
      % Policyのラベルを取得する
      %
      % Returns:
      %   label (string): Policyのラベル

      labels = PlayerMatching.labels(obj.player_matchings);
      label = char(strjoin(string(labels), ', '));
    end

    function index = index(obj)
      % Policyのインデックスを取得する
      %
      % Returns:
      %   index (int): Policyのインデックス

      index = -1;
      all_possible_policies = Policy.get_all_possible_policies();
      for i = 1:length(all_possible_policies)
        policy = all_possible_policies{i};
        if strcmp(policy.id(), obj.id())
            index = i;
            break;
        end
      end

      if index < 0
        error("Policy not found in all_possible_policies")
      end
    end

    function expr = optimality_condition(obj)
      expr = symtrue;
      for i = 1:length(obj.player_matchings)
        player_matching = obj.player_matchings{i};
        expr = expr & player_matching.optimality_condition();
      end
    end

    function expr = optimality_condition_evaluated(obj)
      expr = obj.optimality_condition();
      expr = ParamsHelper.evaluate_all_params(expr);
    end

    function player_matching = get_player_matching_by_player_set(obj, player_set)
      % Policyにおいて、指定されたplayer_setに対応するPlayerMatchingを取得する
      % M^\pi(s)に相当する
      %
      % Parameters:
      %   obj (Policy): Policy インスタンス
      %   player_set (PlayerSet): プレイヤ集合
      %
      % Returns:
      %   player_matching (PlayerMatching): 指定されたプレイヤ集合に対応するPlayerMatching

      idx = player_set.index();
      player_matching = obj.player_matchings{idx};
    end

    function expr = bp_stability_condition(obj, expected_utility_solutions)
      % 指定した方策objがBP安定であるための条件式を取得する
      %
      % Parameters:
      %   obj (Policy): Policy インスタンス
      %   expected_utility_solutions (cell<struct>): すべての方策ごとに計算された期待効用の計算結果のセル配列。セル配列の順番は、Policy.get_all_possible_policies()の順番と一致する。
      %
      % Returns:
      %   expr (sym): 指定した方策objがBP安定であるための条件式

      expr = symtrue;
      for i = 1:length(obj.player_matchings)
        player_matching = obj.player_matchings{i};
        bp_stability_condition_expr = player_matching.bp_stability_condition(obj, expected_utility_solutions);
        expr = and(expr, bp_stability_condition_expr);
      end
    end
  end

  methods (Static)
    function policies = get_all_possible_policies()
      % すべての方策を取得する
      %
      % Returns:
      %   policies (cell<Policy>): すべてのPolicyのcell配列

      %   具体例:
      %       例えば、プレイヤ集合 P = {P1, P2, P3, P4} があり、各プレイヤ集合ごとに以下のマッチング候補がある場合:
      %           P1 のマッチング候補: {M_{P1,1}, M_{P1,2}}
      %           P2 のマッチング候補: {M_{P2,1}, M_{P2,2}, M_{P2,3}}
      %           P3 のマッチング候補: {M_{P3,1}, M_{P3,2}}
      %           P4 のマッチング候補: {M_{P4,1}}
      %       これらの組み合わせの総数 2 * 3 * 2 * 1 = 12 通りのPolicyが生成される。

      persistent cached_all_possible_policies;
      if ~isempty(cached_all_possible_policies)
        policies = cached_all_possible_policies;
        return;
      end

      all_possible_player_sets = PlayerSet.get_all_possible_player_sets();
      num_sets = length(all_possible_player_sets);
      matching_options = cell(1, num_sets);

      % 各プレイヤ集合のマッチング候補を取得
      for i = 1:num_sets
        matching_options{i} = all_possible_player_sets{i}.get_all_possible_player_matchings();
      end

      % すべてのマッチングの組み合わせを処理
      indices = arrayfun(@(i) 1:length(matching_options{i}), 1:num_sets, 'UniformOutput', false);
      [grid{1:num_sets}] = ndgrid(indices{:});
      combination_indices = cell2mat(cellfun(@(x) x(:), grid, 'UniformOutput', false));

      policies = cell(size(combination_indices, 1), 1);
      for k = 1:size(combination_indices, 1)
        player_matchings = cell(num_sets, 1);
        for j = 1:num_sets
          player_matching = matching_options{j}{combination_indices(k, j)};
          player_matchings{j} = player_matching;
        end
        policies{k} = Policy(player_matchings);
      end

      cached_all_possible_policies = policies;
    end

    function policy = get_policy_from_optimal_state_value_solution(solution)
      % 各プレイヤ集合における最適期待効用solutionに基づいて、そのsolutionが満たすPolicyを取得する
      %
      % Parameters:
      %   solution (struct): 期待効用方程式の解
      %
      % Returns:
      %   policy (Policy): Policy インスタンス

      policy = [];
      all_possible_policies = Policy.get_all_possible_policies();
      for i = 1:length(all_possible_policies)
        optimality_condition_evaluated = all_possible_policies{i}.optimality_condition_evaluated();
        optimality_condition_evaluated = subs(optimality_condition_evaluated, fieldnames(solution), struct2cell(solution));
        if isAlways(optimality_condition_evaluated)
          policy = all_possible_policies{i};
          break;
        end
      end
    end
  end
end