classdef Player
  properties
    % プレイヤーのインデックス
    playerIndex
    % プレイヤ名
    playerName
  end

  methods
    function obj = Player(attr, type)
      if type == "playerIndex"
        obj.playerIndex = attr;
        obj.playerName = PlayerHelper.convertToPlayerName(attr);
      elseif type == "playerName"
        obj.playerName = attr;
        obj.playerIndex = PlayerHelper.convertToPlayerIndex(attr);
      else
        error("type must be 'playerIndex' or 'playerName'");
      end
    end
  end
end