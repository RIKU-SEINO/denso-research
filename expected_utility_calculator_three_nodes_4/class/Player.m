classdef Player
  % Player クラス
  %
  % プレイヤー (タクシーまたは乗客) を表すクラス。
  %

  % properties
  properties
    % プレイヤーのタイプ
    % char: 'v' または 'ps'
    type
    
    % プレイヤーの現在ノード
    % int: 1, 2, 3 のいずれか
    node

    % プレイヤーの目的地ノード
    % int: v の場合は 0 (目的地なし)
    % ps の場合は {1,2,3}\{node} のいずれか
    destination_node

    % プレイヤーが空車状態となるまでのステップ数
    % int: v の場合は 0, 1, 2, 3, 4 のいずれか
    %       (0なら即時マッチング可能, 4なら4ステップ後に空車)
    % ps の場合は常に 0
    steps_to_vacant
  end

  % constructor
  methods
    function obj = Player(type, node, destination_node, steps_to_vacant)
      % Player クラスのコンストラクタ
      %
      % Parameters:
      %   type (char): 'v' または 'ps'
      %   node (int): 現在のノード (1, 2, 3)
      %   destination_node (int): 目的地ノード (v は 0, ps は {1,2,3}\{node})
      %   steps_to_vacant (int): 空車状態までのステップ数 (v: 0-4, ps: 0)
      %
      % Returns:
      %   obj (Player): 生成された Player インスタンス
      
      obj.type = type;
      obj.node = node;
      obj.destination_node = destination_node;
      obj.steps_to_vacant = steps_to_vacant;

      % validate
      obj.validate();
    end
  end

  % override
  methods 
    function result = eq(obj, other)
      % 2つの Player オブジェクトが等しいか判定する
      %
      % Parameters:
      %   obj (Player): 1つ目の Player オブジェクト
      %   other (Player): 2つ目の Player オブジェクト
      %
      % Returns:
      %   result (logical): 等しければ true, そうでなければ false
      
      result = strcmp(obj.type, other.type) && ...
               obj.node == other.node && ...
               obj.destination_node == other.destination_node && ...
               obj.steps_to_vacant == other.steps_to_vacant;
    end
  end

  % other methods
  methods
    function id = id(obj)
      % プレイヤーの ID を返す
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   id (int): プレイヤーの ID
      %    ・千の位: プレイヤーのタイプ (タクシー: 1, 乗客: 2)
      %    ・百の位: プレイヤーの現在ノード (1, 2, 3)
      %    ・十の位: プレイヤーの目的地ノード (タクシー: 0, 乗客: {1,2,3}\{node})
      %    ・一の位: プレイヤーの空車状態までのステップ数 (タクシー: 0-4, 乗客: 0)
      if obj.type == "v"
        type_alias = 1;
      elseif obj.type == "ps"
        type_alias = 2;
      end
      id = type_alias * 1000 + obj.node * 100 + obj.destination_node * 10 + obj.steps_to_vacant;
    end

    function label = label(obj)
      % プレイヤーのラベルを返す
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   label (char): プレイヤーのラベル表記
      %     ・タクシー の場合は 'v_i(m)' のように表現 (ノードiでmステップ後に空車状態となるタクシー）
      %     ・乗客 の場合は 'ps_{j,k}' のように表現（ノードjに出現し、ノードkを目的地とする乗客を表す）
      
      if obj.type == "v"
        label = sprintf('v%d(%d)', obj.node, obj.steps_to_vacant);
      else
        label = sprintf('ps%d[%d]', obj.node, obj.destination_node);
      end
    end

    function label_tex = label_tex(obj)
      % プレイヤーのラベルをtex形式で返す
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   label_tex (char): プレイヤーのラベル表記

      if obj.type == "v"
        label_tex = sprintf('v_{%d}(%d)', obj.node, obj.steps_to_vacant);
      else
        label_tex = sprintf('ps_{%d,%d}', obj.node, obj.destination_node);
      end
    end

    function index = index(obj)
      % all_possible_playersの中でのindexを返す
      % 
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   index (int): all_possible_players の中でのインデックス

      all_possible_players = Player.get_all_possible_players();
      index = -1;
      for i = 1:length(all_possible_players)
        if obj == all_possible_players{i}
          index = i;
          break
        end
      end
      if index == -1
        error("Player not found in all_possible_players");
      end
    end

    function result = is_taxi(obj)
      % プレイヤーがタクシーかどうかを判定する
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   result (logical): タクシーであれば true, そうでなければ false
      
      result = strcmp(obj.type, 'v');
    end

    function result = is_vacant_taxi(obj)
      % プレイヤーが空車タクシーかどうかを判定する
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   result (logical): 空車タクシーであれば true, そうでなければ false
      
      result = strcmp(obj.type, 'v') && obj.steps_to_vacant == 0;
    end

    function result = is_passenger(obj)
      % プレイヤーが乗客かどうかを判定する
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   result (logical): 乗客であれば true, そうでなければ false
      
      result = strcmp(obj.type, 'ps');
    end

    function obj = one_step_elapsed(obj)
      % プレイヤーの空車状態までのステップ数を1減少させる
      %
      % Parameters:
      %   obj (Player): Player オブジェクト
      %
      % Returns:
      %   result (Player): ステップ数が1減少した Player オブジェクト
      
      if obj.is_taxi()
        obj.steps_to_vacant = max([obj.steps_to_vacant-1, 0]);
      end
    end
  end

  methods (Static)
    function all_taxis = get_all_taxis()
      % 全てのタクシーの集合を返す
      %
      %  Parameters: None
      %
      %  Returns:
      %    all_taxis （cell<Player>）: 出現しうる全てのタクシー
      
      all_taxis = {};
      for node = 1:3
        for steps_to_vacant = 0:3
          all_taxis{end+1, 1} = Player('v', node, 0, steps_to_vacant);
        end

        if node ~= 2
          all_taxis{end+1, 1} = Player('v', node, 0, 4);
        end
      end
    end

    function all_possible_taxis = get_all_possible_taxis()
      % 出現しうる全てのタクシーの集合を返す
      % 
      % Parameters: None
      %  
      % Returns:
      %   all_possible_taxis （cell<Player>）: 出現しうる全てのタクシー

      % == general case ==
      % all_possible_taxis = Player.get_all_taxis();

      % == assumption == 
      % ノード1でしかタクシーが空車とならず、かつps_{2,1}またはps_{3,1}のみ出現する場合
      all_possible_taxis = {
        Player('v', 1, 0, 0); ...
        Player('v', 1, 0, 1); ...
        Player('v', 1, 0, 2); ...
        Player('v', 1, 0, 3); ...
        Player('v', 1, 0, 4); ...
      };
    end

    function all_passengers = get_all_passengers()
      % 出現しうる全ての乗客の集合を返す
      %
      % Parameters: None
      %
      % Returns:
      %   all_passengers （cell<Player>）: 出現しうる全ての乗客
      
      all_passengers = {};
      for node = 1:3
        for destination_node = 1:3
          if node ~= destination_node
            all_passengers{end+1, 1} = Player('ps', node, destination_node, 0);
          end
        end
      end
    end

    function all_possible_passengers = get_all_possible_passengers()
      % 出現しうる全ての乗客の集合を返す
      %
      % Parameters: None
      %
      % Returns:
      %   all_possible_passengers （cell<Player>）: 出現しうる全ての乗客

      % == general case ==
      % all_possible_passengers = Player.get_all_passengers();

      % == assumption ==
      % ノード1でしかタクシーが空車とならず、ps_{2,1}またはps_{3,1}のみ出現する場合
      all_possible_passengers = {
        Player('ps', 2, 1, 0); ...
        Player('ps', 3, 1, 0); ...
      };
    end

    function all_possible_players = get_all_possible_players()
      % 出現しうる全てのプレイヤーの集合を返す
      %
      % Parameters: None
      %
      % Returns:
      %   all_possible_players （cell<Player>）: 出現しうる全てのプレイヤー
      
      all_possible_taxis = Player.get_all_possible_taxis();
      all_possible_passengers = Player.get_all_possible_passengers();
      all_possible_players = [all_possible_taxis; all_possible_passengers];
    end

    function ids = ids(players)
      % プレイヤーの ID を返す
      %
      % Parameters:
      %   players （cell<Player>）: プレイヤーの集合
      %
      % Returns:
      %   ids （cell<int>）: プレイヤーの ID
      
      ids = zeros(length(players), 1);
      for i = 1:length(players)
        ids(i) = players{i}.id();
      end
    end

    function labels = labels(players)
      % プレイヤーのラベルを返す
      %
      % Parameters:
      %   players （cell<Player>）: プレイヤーの集合
      %
      % Returns:
      %   labels （cell<char>）: プレイヤーのラベル表記
      
      labels = cell(length(players), 1);
      for i = 1:length(players)
        labels{i} = players{i}.label();
      end
    end

    function labels_tex = labels_tex(players)
      % プレイヤーのラベルをtex形式で返す
      %
      % Parameters:
      %   players （cell<Player>）: プレイヤーの集合
      %
      % Returns:
      %   labels_tex （cell<char>）: プレイヤーのラベル表記

      labels_tex = cell(length(players), 1);
      for i = 1:length(players)
        labels_tex{i} = players{i}.label_tex();
      end
    end

    function sorted_players = sort_players(players)
      % プレイヤーの集合をプレイヤのIDの昇順でソートする
      %
      % Parameters:
      %   players （cell<Player>）: プレイヤーの集合
      %
      % Returns:
      %   sorted_players （cell<Player>）: ソートされたプレイヤーの集合
      
      player_ids = Player.ids(players);
      [~, sorted_indices] = sort(player_ids);
      sorted_players = players(sorted_indices);
    end
  end

   % validation
   methods
    function validate(obj)
      if obj.type ~= "v" && obj.type ~= "ps"
        error("type は 'v' または 'ps' でなければなりません");
      end

      if obj.node ~= 1 && obj.node ~= 2 && obj.node ~= 3
        error("node は 1, 2, 3 のいずれかでなければなりません");
      end

      if obj.steps_to_vacant < 0
        error("steps_to_vacant は 0 以上でなければなりません");
      end

      if obj.steps_to_vacant ~= floor(obj.steps_to_vacant)
        error("steps_to_vacant は整数でなければなりません");
      end

      if obj.type == "ps" && obj.steps_to_vacant ~= 0
        error("乗客の場合、steps_to_vacant は 0 でなければなりません");
      end

      if obj.type == "v" && obj.node ~= 2 && obj.steps_to_vacant > 4
        error("現在ノードが2でないタクシーの場合、steps_to_vacant は 0, 1, 2, 3, 4 のいずれかでなければなりません");
      end

      if obj.type == "v" && obj.node == 2 && obj.steps_to_vacant > 3
        error("現在ノードが2のタクシーの場合、steps_to_vacant は 0, 1, 2, 3 のいずれかでなければなりません");
      end

      if obj.node == obj.destination_node
        error("destination_node は node と異なる値でなければなりません");
      end

      if obj.type == "v" && obj.destination_node ~= 0
        error("タクシーの場合、destination_node は 0 でなければなりません");
      end

      if obj.type == "ps" && (obj.destination_node < 1 || obj.destination_node > 3)
        error("乗客の場合、destination_node は 1, 2, 3 のいずれかでなければなりません");
      end
    end
  end
end
