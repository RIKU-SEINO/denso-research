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

    function expr = optimality_condition(obj)
      expr = symtrue;
      for i = 1:length(obj.player_matchings)
        player_matching = obj.player_matchings{i};
        expr = expr & player_matching.optimality_condition();
      end
    end

    function expr = optimality_condition_evaluated(obj)
      [w, c, r, a, p, p_, g, ~, ~, ~] = ParamsHelper.get_symbolic_params();
      [w_v, c_v, r_v, a_v, p_v, p__v, g_v, ~, ~, ~, ~, ~] = ParamsHelper.get_valued_params();
      all_symbolic_params = [
        w, c, reshape(r.', 1, []), reshape(a.', 1, []), reshape(p.', 1, []), reshape(p_.', 1, []), g
      ];
      all_valued_params = [
        w_v, c_v, reshape(r_v.', 1, []), reshape(a_v.', 1, []), reshape(p_v.', 1, []), reshape(p__v.', 1, []), g_v
      ];
      expr = obj.optimality_condition();
      expr = subs(expr, all_symbolic_params, all_valued_params);
    end

    function player_matching = get_player_matching_by_player_set(obj, player_set)
      % Policyにおいて、指定されたplayer_setに対応するPlayerMatchingを取得する
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
  end

  methods (Static)
    function policies = get_all_possible_policies()
      % すべてのプレイヤ集合のマッチング組み合わせを取得する。
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
    end

    function policy = get_policy_from_optimal_solution(solution)
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