classdef Pattern
  % Pattern クラス
  %
  % 期待効用方程式を解く際の条件パターン（=マッチングの組み合わせ）を表すクラス。
  % MDPの文脈では、方策πに相当する。
  %
  %   具体例:
  %       例えば、プレイヤ集合 P = {P1, P2, P3, P4} があり、各プレイヤ集合ごとに以下のマッチング候補がある場合:
  %           P1 のマッチング候補: {M_{P1,1}, M_{P1,2}}
  %           P2 のマッチング候補: {M_{P2,1}, M_{P2,2}, M_{P2,3}}
  %           P3 のマッチング候補: {M_{P3,1}, M_{P3,2}}
  %           P4 のマッチング候補: {M_{P4,1}}
  %      この時の パターン として、次の12通りが考えられる。
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
    function obj = Pattern(player_matchings)
      % Pattern クラスのコンストラクタ
      %
      % Parameters:
      %   player_matchings (cell<PlayerMatching>): プレイヤマッチングの配列
      %
      % Returns:
      %   obj (Pattern): 生成された Pattern インスタンス

      obj.player_matchings = player_matchings;

      obj = obj.sort();
    end
  end

  % override
  methods
    function obj = sort(obj)
      % PatternのPlayerMatchingをソートする
      %
      % Parameters:
      %   obj (Pattern): Pattern インスタンス
      %
      % Returns:
      %   obj (Pattern): ソートされた Pattern インスタンス

      obj.player_matchings = PlayerMatching.sort_player_matchings(obj.player_matchings);
    end
  end

  % other
  methods
    function id = id(obj)
      % PatternのIDを取得する
      %
      % Returns:
      %   id (string): PatternのID

      ids = PlayerMatching.ids(obj.player_matchings);
      id = char(strjoin(string(ids), '_&&_'));
    end

    function label = label(obj)
      % Patternのラベルを取得する
      %
      % Returns:
      %   label (string): Patternのラベル

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
      [w_v, c_v, r_v, a_v, p_v, p__v, g_v, ~, ~, ~, ~] = ParamsHelper.get_valued_params();
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
      % Patternにおいて、指定されたplayer_setに対応するPlayerMatchingを取得する
      %
      % Parameters:
      %   obj (Pattern): Pattern インスタンス
      %   player_set (PlayerSet): プレイヤ集合
      %
      % Returns:
      %   player_matching (PlayerMatching): 指定されたプレイヤ集合に対応するPlayerMatching

      idx = player_set.index();
      player_matching = obj.player_matchings{idx};
    end
  end

  methods (Static)
    function patterns = get_all_possible_patterns()
      % すべてのプレイヤ集合のマッチング組み合わせを取得する。
      %
      % Returns:
      %   patterns (cell<Pattern>): すべてのPatternのcell配列

      %   具体例:
      %       例えば、プレイヤ集合 P = {P1, P2, P3, P4} があり、各プレイヤ集合ごとに以下のマッチング候補がある場合:
      %           P1 のマッチング候補: {M_{P1,1}, M_{P1,2}}
      %           P2 のマッチング候補: {M_{P2,1}, M_{P2,2}, M_{P2,3}}
      %           P3 のマッチング候補: {M_{P3,1}, M_{P3,2}}
      %           P4 のマッチング候補: {M_{P4,1}}
      %       これらの組み合わせの総数 2 * 3 * 2 * 1 = 12 通りのPatternが生成される。

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

      patterns = cell(size(combination_indices, 1), 1);
      for k = 1:size(combination_indices, 1)
        player_matchings = cell(num_sets, 1);
        for j = 1:num_sets
          player_matching = matching_options{j}{combination_indices(k, j)};
          player_matchings{j} = player_matching;
        end
        patterns{k} = Pattern(player_matchings);
      end
    end

    function pattern = get_pattern_from_optimal_solution(solution)
      % 各プレイヤ集合における最適期待効用solutionに基づいて、そのsolutionが満たすPatternを取得する
      %
      % Parameters:
      %   solution (struct): 期待効用方程式の解
      %
      % Returns:
      %   pattern (Pattern): Pattern インスタンス

      pattern = [];
      all_possible_patterns = Pattern.get_all_possible_patterns();
      for i = 1:length(all_possible_patterns)
        optimality_condition_evaluated = all_possible_patterns{i}.optimality_condition_evaluated();
        optimality_condition_evaluated = subs(optimality_condition_evaluated, fieldnames(solution), struct2cell(solution));
        if isAlways(optimality_condition_evaluated)
          pattern = all_possible_patterns{i};
          break;
        end
      end
    end
  end
end