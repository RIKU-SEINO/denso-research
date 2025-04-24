classdef PlayerSet
  % PlayerSet クラス
  %
  % プレイヤーの集合を表すクラス。
  %

  % properties
  properties
    % プレイヤーの集合
    % cell<Player>: プレイヤーの集合を表す Player オブジェクトの配列
    players
  end

  % constructor
  methods
    function obj = PlayerSet(players)
      % PlayerSet クラスのコンストラクタ
      %
      % Parameters:
      %   players (cell<Player>): プレイヤーの集合を表す Player オブジェクトの配列
      %
      % Returns:
      %   obj (PlayerSet): 生成された PlayerSet インスタンス

      obj.players = players;
      
      obj = obj.sort();
      obj.validate();
    end
  end

  % override
  methods
    function result = eq(obj, other)
      % 2つの PlayerSet オブジェクトが等しいか判定する
      %
      % Parameters:
      %   obj (PlayerSet): 1つ目の PlayerSet オブジェクト
      %   other (PlayerSet): 2つ目の PlayerSet オブジェクト
      %
      % Returns:
      %   result (logical): 等しい場合は true, そうでない場合は false

      result = isequal(obj.players, other.players);
    end

    function obj = sort(obj)
      % プレイヤーの集合をソートする
      %
      % Parameters:
      %   obj (PlayerSet): ソート対象の PlayerSet オブジェクト
      %
      % Returns:
      %   obj (PlayerSet): ソートされた PlayerSet インスタンス

      obj.players = Player.sort_players(obj.players);
    end

    function result = has(obj, player)
      % 指定したプレイヤがプレイヤ集合に含まれているか判定する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %   player (Player): 判定対象の Player オブジェクト
      %
      % Returns:
      %   result (logical): プレイヤが含まれている場合は true, そうでない場合は false

      result = any(cellfun(@(p) isequal(p, player), obj.players));
    end
  end

  % other
  methods
    function id = id(obj)
      % プレイヤーの集合の ID を取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   id (char): プレイヤーの集合の ID

      ids = Player.ids(obj.players);
      ids = arrayfun(@(x) num2str(x), ids, 'UniformOutput', false);
      id = char(strjoin(ids, '_'));
    end

    function label = label(obj)
      % プレイヤーの集合のラベルを取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   label (char): プレイヤーの集合のラベル

      labels = Player.labels(obj.players);
      label = char(strjoin(labels, ','));
      label = strcat('{', label, '}');
    end

    function index = index(obj)
      % プレイヤーの集合のインデックスを取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   index (int): プレイヤーの集合のインデックス

      index = find(cellfun(@(x) isequal(x, obj), PlayerSet.get_all_possible_player_sets()));
    end

    function result = is_node_occupied_by_passenger(obj, node)
      % 指定したノードが乗客で占有されているか判定する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %   node (int): ノード番号 (1, 2, 3)
      %   type (char): プレイヤーのタイプ ('v' または 'ps')
      %
      % Returns:
      %   result (logical): ノードが占有されている場合は true, そうでない場合は false

      result = false;
      for i = 1:length(obj.players)
        player = obj.players{i};
        if player.node == node && player.is_passenger()
          result = true;
          break
        end
      end
    end

    function player = get_vacant_taxi(obj)
      % プレイヤ集合から空車のタクシーを取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   player (Player): 空車のタクシーの Player オブジェクト

      player = [];
      for i = 1:length(obj.players)
        if obj.players{i}.is_vacant_taxi()
          % == assumption ==
          % タクシーの稼働台数は1台であることを前提にしているので、空車状態となっているタクシーは最大で1台である
          player = obj.players{i};
          break
        end
      end
    end

    function players = get_passengers(obj)
      % プレイヤ集合から乗客を取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   players (cell<Player>): 乗客の Player オブジェクトの配列

      players = {};
      for i = 1:length(obj.players)
        if obj.players{i}.is_passenger()
          players{end + 1, 1} = obj.players{i};
        end
      end
    end

    function obj = add(obj, player)
      % 指定したプレイヤをプレイヤ集合に追加する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   obj (PlayerSet): プレイヤーが追加された PlayerSet インスタンス

      if isempty(player)
        return;
      end

      if obj.is_node_occupied_by_passenger(player.node)
        return;
      end

      obj.players{end + 1, 1} = player;
      obj.players = Player.sort_players(obj.players);
    end

    function obj = add_all(obj, players)
      % 指定したプレイヤの集合をプレイヤ集合に追加する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %   players (cell<Player>): 追加するプレイヤの集合
      %
      % Returns:
      %   obj (PlayerSet): プレイヤーが追加された PlayerSet インスタンス

      for i = 1:length(players)
        obj = obj.add(players{i});
      end
    end

    function obj = remove(obj, player)
      % 指定したプレイヤをプレイヤ集合から削除する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   obj (PlayerSet): プレイヤーが削除された PlayerSet インスタンス
      if isempty(player)
        return;
      end

      for i = 1:length(obj.players)
        if isequal(obj.players{i}, player)
          obj.players(i) = [];
          break;
        end
      end
    end

    function obj = replace(obj, player, new_player)
      % 指定したプレイヤを新しいプレイヤで置き換える
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %   player (Player): 置き換え対象の Player オブジェクト
      %   new_player (Player): 新しい Player オブジェクト
      %
      % Returns:
      %   obj (PlayerSet): プレイヤーが置き換えられた PlayerSet インスタンス

      obj = obj.add(new_player);
      obj = obj.remove(player);      
    end

    function obj = one_step_elapsed(obj)
      % プレイヤーの集合の状態を1ステップ進める
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   obj (PlayerSet): 1ステップ進められた PlayerSet インスタンス

      for i = 1:length(obj.players)
        if obj.players{i}.is_taxi()
          obj.players{i} = obj.players{i}.one_step_elapsed();
        end
      end
    end

    function player_sets = passenger_emerged(obj)
      % プレイヤ集合から乗客が出現した後のプレイヤ集合の候補を取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   player_sets (cell<PlayerSet>): 乗客が出現した後のプレイヤーの集合

      all_possible_passenger_sets = PlayerSet.get_all_possible_passenger_sets();
      player_sets = cell(length(all_possible_passenger_sets), 1);
      for i = 1:length(all_possible_passenger_sets)
        player_set_temp = obj.add_all(all_possible_passenger_sets{i}.players);
        player_sets{i} = player_set_temp;
      end
    end

    function player_sets = get_all_possible_player_sets_after_transition(obj)
      % 指定したプレイヤ集合から次の二つが行われた後のプレイヤ集合の候補を取得する
      %   == assumption ==
      %   1. タクシーが1ステップ進む
      %   2. 乗客が出現する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   player_sets (cell<PlayerSet>): 乗客が出現した後のプレイヤーの集合

      % 1. タクシーが1ステップ進む
      player_set = obj.one_step_elapsed();

      % 2. 乗客が出現する
      player_sets = player_set.passenger_emerged();
    end

    function player_matchings = get_all_possible_player_matchings(obj)
      % 指定したプレイヤ集合において、考えられる全てのマッチングを取得する
      %   == assumption ==
      %   ・タクシーに割り当てられる乗客の数は最大で1人であることを前提
      %   ・空車状態でないタクシーはマッチング対象外であることを前提
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %
      % Returns:
      %   player_matchings (cell<PlayerMatching>): プレイヤのマッチングの集合

      % 1. 全員が取り残されるマッチング
      player_pairs = cell(length(obj.players), 1);
      for i = 1:length(obj.players)
        player_pairs{i} = PlayerPair({obj.players{i}});
      end
      player_matchings = {
        PlayerMatching(player_pairs)
      }; % 全員が取り残されるマッチング

      
      % 2. タクシーと乗客のペアが存在する場合
      vacant_taxi = obj.get_vacant_taxi();
      passengers = obj.get_passengers();

      if isempty(vacant_taxi) || isempty(passengers)
        return;
      end

      for i = 1:length(passengers)
        passenger = passengers{i};
        player_pairs = {
          PlayerPair({vacant_taxi; passenger})
        }; % マッチされたペア

        remained_passengers = Utils.obj_setdiff(passengers, {passenger});
        for j = 1:length(remained_passengers)
          player_pairs{end+1, 1} = PlayerPair({remained_passengers{j}}); % マッチされていないペア
        end

        player_matchings{end+1, 1} = PlayerMatching(player_pairs); % マッチされたペアを含むマッチング
      end
    end

    function state_value = get_state_value_from_solution(obj, solution)
      % プレイヤ集合の状態価値を取得する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト
      %   solution (cell): 状態価値関数の解
      %
      % Returns:
      %   state_value (double): プレイヤ集合の状態価値

      variable_state_value = VariablesHelper.get_state_value(obj);
      state_value = solution.(char(variable_state_value));
    end
  end

  % static methods
  methods (Static)
    function labels = labels(player_sets)
      % プレイヤ集合のラベル一覧を取得する
      %
      % Parameters:
      %   player_sets (cell<PlayerSet>): プレイヤ集合の配列
      %
      % Returns:
      %   labels (cell<char>): プレイヤ集合のラベルの配列

      labels = cell(length(player_sets), 1);
      for i = 1:length(player_sets)
        labels{i} = player_sets{i}.label();
      end
    end
    
    function all_taxi_sets = get_all_taxis_sets()
      % 全てのタクシーの集合を取得する
      %
      % Parameters: None
      %
      % Returns:
      %   all_taxi_sets (cell<PlayerSet>): 出現しうる全てのタクシーの集合

      % == assumption ==
      % タクシーの稼働台数は1台であることを前提とする
      all_taxis = Player.get_all_taxis();
      all_taxi_sets = cell(length(all_taxis), 1); %稼働台数が1台なので、all_taxisの数と同じ
      for i = 1:length(all_taxis)
        all_taxi_sets{i} = PlayerSet({all_taxis{i}});
      end
    end

    function all_possible_taxi_sets = get_all_possible_taxis_sets()
      % 出現しうる全てのタクシーの集合を取得する
      %
      % Parameters: None
      %
      % Returns:
      %   all_possible_taxi_sets (cell<PlayerSet>): 出現しうる全てのタクシーの集合

      % == assumption ==
      % タクシーの稼働台数は1台であることを前提とする
      all_possible_taxis = Player.get_all_possible_taxis();
      all_possible_taxi_sets = cell(length(all_possible_taxis), 1); %稼働台数が1台なので、all_possible_taxisの数と同じ
      for i = 1:length(all_possible_taxis)
        all_possible_taxi_sets{i} = PlayerSet({all_possible_taxis{i}});
      end
    end

    function all_passenger_sets = get_all_passenger_sets()
      % 全ての乗客の集合を取得する
      %
      % Parameters: None
      %
      % Returns:
      %   all_passenger_sets (cell<PlayerSet>): 出現しうる全ての乗客の集合

      all_passenger_sets = {
        PlayerSet({}); % 何も出現しない
        PlayerSet({Player('ps', 1, 2, 0)}); % ps1のみ出現(ps1: 1->2)
        PlayerSet({Player('ps', 1, 3, 0)}); % ps1のみ出現(ps1: 1->3)
        PlayerSet({Player('ps', 2, 1, 0)}); % ps2のみ出現(ps2: 2->1)
        PlayerSet({Player('ps', 2, 3, 0)}); % ps2のみ出現(ps2: 2->3)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 2, 1, 0)}); % ps1とps2が出現(ps1: 1->2, ps2: 2->1)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 2, 1, 0)}); % ps1とps2が出現(ps1: 1->3, ps2: 2->1)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 2, 3, 0)}); % ps1とps2が出現(ps1: 1->2, ps2: 2->3)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 2, 3, 0)}); % ps1とps2が出現(ps1: 1->3, ps2: 2->3)
        PlayerSet({Player('ps', 3, 1, 0)}); % ps3のみ出現(ps3: 3->1)
        PlayerSet({Player('ps', 3, 2, 0)}); % ps3のみ出現(ps3: 3->2)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 3, 1, 0)}); % ps1とps3が出現(ps1: 1->2, ps3: 3->1)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 3, 1, 0)}); % ps1とps3が出現(ps1: 1->3, ps3: 3->1)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 3, 2, 0)}); % ps1とps3が出現(ps1: 1->2, ps3: 3->2)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 3, 2, 0)}); % ps1とps3が出現(ps1: 1->3, ps3: 3->2)
        PlayerSet({Player('ps', 2, 1, 0); Player('ps', 3, 1, 0)}); % ps2とps3が出現(ps2: 2->1, ps3: 3->1)
        PlayerSet({Player('ps', 2, 3, 0); Player('ps', 3, 1, 0)}); % ps2とps3が出現(ps2: 2->3, ps3: 3->1)
        PlayerSet({Player('ps', 2, 1, 0); Player('ps', 3, 2, 0)}); % ps2とps3が出現(ps2: 2->1, ps3: 3->2)
        PlayerSet({Player('ps', 2, 3, 0); Player('ps', 3, 2, 0)}); % ps2とps3が出現(ps2: 2->3, ps3: 3->2)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 2, 1, 0); Player('ps', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->1, ps3: 3->1)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 2, 1, 0); Player('ps', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->1, ps3: 3->1)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 2, 3, 0); Player('ps', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->3, ps3: 3->1)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 2, 3, 0); Player('ps', 3, 1, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->3, ps3: 3->1)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 2, 1, 0); Player('ps', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->1, ps3: 3->2)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 2, 1, 0); Player('ps', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->1, ps3: 3->2)
        PlayerSet({Player('ps', 1, 2, 0); Player('ps', 2, 3, 0); Player('ps', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->2, ps2: 2->3, ps3: 3->2)
        PlayerSet({Player('ps', 1, 3, 0); Player('ps', 2, 3, 0); Player('ps', 3, 2, 0)}); % ps1, ps2, ps3が出現(ps1: 1->3, ps2: 2->3, ps3: 3->2)
      };
    end

    function all_possible_passenger_sets = get_all_possible_passenger_sets()
      % 出現しうる全ての乗客の集合を取得する
      %
      % Parameters: None
      %
      % Returns:
      %   all_possible_passenger_sets (cell<PlayerSet>): 出現しうる全ての乗客の集合

      % == assumption ==
      % ps_{2,1}またはps_{3,1}のみ出現することを前提とする
      all_possible_passenger_sets = {
        PlayerSet({}); % 何も出現しない
        PlayerSet({Player('ps', 2, 1, 0)}); % ps2のみ出現(ps2: 2->1)
        PlayerSet({Player('ps', 3, 1, 0)}); % ps3のみ出現(ps3: 3->1)
        PlayerSet({Player('ps', 2, 1, 0); Player('ps', 3, 1, 0)}); % ps2とps3が出現(ps2: 2->1, ps3: 3->1)
      };
    end

    function all_player_sets = get_all_player_sets()
      % 全てのプレイヤの集合を取得する
      %
      % Parameters: None
      %
      % Returns:
      %   all_player_sets (cell<PlayerSet>): 出現しうる全てのプレイヤの集合

      persistent cached_all_player_sets;
      if ~isempty(cached_all_player_sets)
        all_player_sets = cached_all_player_sets;
        return;
      end

      all_taxi_sets = PlayerSet.get_all_taxis_sets();
      all_passenger_sets = PlayerSet.get_all_passenger_sets();

      cached_all_player_sets = {};
      for i = 1:length(all_taxi_sets)
        for j = 1:length(all_passenger_sets)
          taxi_player_set = all_taxi_sets{i};
          passenger_player_set = all_passenger_sets{j};
          player_set = taxi_player_set.add_all(passenger_player_set.players);
          cached_all_player_sets{end + 1, 1} = player_set;
        end
      end

      all_player_sets = cached_all_player_sets;
    end

    function all_possible_player_sets = get_all_possible_player_sets()
      % 出現しうる全てのプレイヤの集合を取得する
      %
      % Parameters: None
      %
      % Returns:
      %   all_possible_player_sets (cell<PlayerSet>): 出現しうる全てのプレイヤの集合

      persistent cached_possible_player_sets;
      if ~isempty(cached_possible_player_sets)
        all_possible_player_sets = cached_possible_player_sets;
        return;
      end

      all_possible_taxi_sets = PlayerSet.get_all_possible_taxis_sets();
      all_possible_passenger_sets = PlayerSet.get_all_possible_passenger_sets();

      cached_possible_player_sets = {};
      for i = 1:length(all_possible_taxi_sets)
        for j = 1:length(all_possible_passenger_sets)
          taxi_player_set = all_possible_taxi_sets{i};
          passenger_player_set = all_possible_passenger_sets{j};
          player_set = taxi_player_set.add_all(passenger_player_set.players);
          cached_possible_player_sets{end + 1, 1} = player_set;
        end
      end

      all_possible_player_sets = cached_possible_player_sets;
    end
  end

  % validation
  methods
    function validate(obj)
      % プレイヤーの集合の状態を検証する
      %
      % Parameters:
      %   obj (PlayerSet): 対象の PlayerSet オブジェクト

      % Returns: None

      if ~iscell(obj.players)
        error('playersはcell配列でなければなりません');
      end

      % プレイヤ集合に含まれるプレイヤの数が0以上であることを確認
      if length(obj.players) < 1
        % playersは空であることは許し、それ以上のvalidationは行わない
        return;
      end

      % propertiesがn*1のcell配列であることを確認
      if size(obj.players, 2) ~= 1
        error('playersのsizeはn*1でなければなりません');
      end

      % プレイヤ集合に重複がないことを確認
      ids = Player.ids(obj.players);
      if length(ids) ~= length(unique(ids))
        error('playersに重複が含まれています');
      end

      % プレイヤ集合に含まれる要素がすべてPlayerオブジェクトであることを確認
      for i = 1:length(obj.players)
        if ~isa(obj.players{i}, 'Player')
          error('playersの要素はすべてPlayerオブジェクトでなければなりません');
        end
      end

      % プレイヤ集合に含まれるプレイヤそれぞれに対して検証を行う
      for i = 1:length(obj.players)
        obj.players{i}.validate();
      end
    end
  end
end