classdef Transition
  properties
    % 各要素にカテゴリラベルを持つ64x64セル配列。行が現在の状況番号、列が次の状況番号を表す
    % emerged: 出現したプレイヤーインデックス配列, disappeared: 消滅したプレイヤーインデックス配列
    transitionValuedCellArray
    % 各要素が遷移可能かどうかを示す64x64セル配列。行が現在の状況番号、列が次の状況番号を表す
    % 0: 遷移が不可能, 1: 遷移が可能
    transitionBinaryCellArray
  end

  methods
    function obj = Transition()
      obj.transitionValuedCellArray = cell(64, 64);
      obj.transitionBinaryCellArray = cell(64, 64);
      for i = 1:64
        for j = 1:64
          init_map = containers.Map();
          init_map('emerged') = [];
          init_map('disappeared') = [];
          obj.transitionValuedCellArray{i, j} = init_map;
          obj.transitionBinaryCellArray{i, j} = 0;
        end
      end
    end
  end

  % プロパティを更新する
  methods
    function obj = updateTransitionValuedMatrix(obj, origin, destination, emergedPlayerIndices, disappearedPlayerIndices)
      update_map = containers.Map();
      update_map('emerged') = emergedPlayerIndices;
      update_map('disappeared') = disappearedPlayerIndices;
      % cell配列には1-indexedでアクセスするため、+1することに注意
      obj.transitionValuedCellArray{origin+1, destination+1} = update_map;
    end

    function obj = updateTransitionBinaryMatrix(obj, origin, destination, isTransitionable)
      % cell配列には1-indexedでアクセスするため、+1することに注意
      obj.transitionBinaryCellArray{origin+1, destination+1} = isTransitionable;
    end
  end
end