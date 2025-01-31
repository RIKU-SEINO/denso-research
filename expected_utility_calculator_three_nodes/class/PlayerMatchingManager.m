classdef PlayerMatchingManager
  properties
      matchingMap % situationオブジェクトをキーにしたマップ
  end
  
  methods
      % コンストラクタ: マップの初期化
      function obj = PlayerMatchingManager()
          obj.matchingMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
      end
      
      % マッチングを設定するメソッド
      function obj = setMatching(obj, situation, optimalMatching)
          situationKey = obj.getSituationKey(situation);
          
          % 最適マッチングが決まった場合
          if ~isempty(optimalMatching)
              obj.matchingMap(situationKey) = struct('value1', optimalMatching, 'value2', NaN); 
          else
              % 最適マッチングが決まらなかった場合
              obj.matchingMap(situationKey) = struct('value1', [], 'value2', 1);
          end
      end
      
      % マッチング結果を取得するメソッド
      function matching = getMatching(obj, situation)
          situationKey = obj.getSituationKey(situation);
          if isKey(obj.matchingMap, situationKey)
              matching = obj.matchingMap(situationKey);
          else
              matching = struct('value1', [], 'value2', 1);
          end
      end
      
      % situation オブジェクトからキーを生成
      function situationKey = getSituationKey(obj, situation)
          situationKey = sprintf('situation_%d', situation.situationNumber); % situation.situationNumber をキーとして使用
      end
  end
end
