classdef SituationHelper
  % 状況番号を、その状況において存在するプレイヤーの組み合わせに変換する
  methods (Static)
    function presencePair = convertToPresencePair(newSituationNumber)
      presencePair = zeros(6, 1);
      situationNumberBinary = dec2bin(newSituationNumber, 6);
      
      for i = 1:6
        presencePair(i) = str2double(situationNumberBinary(7-i));
      end
    end

    % その状況において存在するプレイヤーの組み合わせを状況番号に変換する
    function situationNumber = convertToSituationNumber(newPresencePair)
      situationNumber = bin2dec(num2str(flip(newPresencePair.')));
    end
  end
end
