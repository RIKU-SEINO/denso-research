classdef Pattern
  % Pattern クラス
  %
  % 期待効用方程式を解く際の条件パターン（=マッチングの組み合わせ）を表すクラス。
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

    function expr = condition(obj)
      expr = symtrue;
      for i = 1:length(obj.player_matchings)
        player_matching = obj.player_matchings{i};
        expr = expr & player_matching.optimality_condition();
      end
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
end