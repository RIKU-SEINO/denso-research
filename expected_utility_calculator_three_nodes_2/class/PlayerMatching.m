classdef PlayerMatching
  % プレイヤ集合において組まれたマッチングを返す

  properties
    player_pairs % PlayerPairのセル配列
  end

  % constructor
  methods
    function obj = PlayerMatching(player_pairs)
      obj.player_pairs = player_pairs;
    end
  end
end