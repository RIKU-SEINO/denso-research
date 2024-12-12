classdef PlayerHelper
  methods (Static)
    function playerName = convertToPlayerName(playerIndex)
      switch playerIndex
        case 1
          playerName = "v1";
        case 2
          playerName = "ps1";
        case 3
          playerName = "v2";
        case 4
          playerName = "ps2";
        case 5
          playerName = "v3";
        case 6
          playerName = "ps3";
        otherwise
          error("playerIndex must be 1, 2, 3, 4, 5, or 6");
      end
    end

    function playerIndex = convertToPlayerIndex(playerName)
      switch playerName
        case "v1"
          playerIndex = 1;
        case "ps1"
          playerIndex = 2;
        case "v2"
          playerIndex = 3;
        case "ps2"
          playerIndex = 4;
        case "v3"
          playerIndex = 5;
        case "ps3"
          playerIndex = 6;
        otherwise
          error("playerName must be 'v1', 'ps1', 'v2', 'ps2', 'v3', or 'ps3'");
      end
    end
  end
end