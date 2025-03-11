classdef PlayerMatchingSet
  properties
    player_matchings % PlayerMatchingのセル配列
  end

  % constructor
  methods
    function obj = PlayerMatchingSet(player_matchings)
      obj.player_matchings = player_matchings;
      obj = obj.sort();
    end
  end

  % override
  methods
    function obj = sort(obj)
      obj.player_matchings = PlayerMatching.sort_player_matchings(obj.player_matchings);
    end
  end

   % other
  methods
    function id = id(obj)
      ids = PlayerMatching.ids(obj.player_matchings);
      id = char(strjoin(string(ids), ', '));
      id = strcat('<', id, '>');
    end

    function [expected_utility_of_player_candidates, condition_candidates] = calculate_expected_utility_candidates_of_player(obj, player, x)
      expected_utility_of_player_candidates = {};
      condition_candidates = {};

      for i = 1:length(obj.player_matchings)
        player_matching = obj.player_matchings{i};
        expected_utility_of_player = player_matching.calculate_expected_utility_of_player(player, x);
        if isAlways(expected_utility_of_player < 0)
          expected_utility_of_player
          error('expected utility should not always be negative');
        end
        expected_utility_sum = player_matching.calculate_expected_utility_sum(x);
        other_is = setdiff(1:length(obj.player_matchings), i);

        condition = symtrue;
        for j = 1:length(other_is)
          other_i = other_is(j);
          other_player_matching = obj.player_matchings{other_i};
          other_expected_utility_sum = other_player_matching.calculate_expected_utility_sum(x);
          new_condition = expected_utility_sum >= other_expected_utility_sum;
          condition = simplify(and(condition, new_condition));
        end
        expected_utility_of_player_candidates{end+1, 1} = expected_utility_of_player;
        condition_candidates{end+1, 1} = condition;
      end
    end

    function piecewise_expression = calculate_piecewise(obj, player, x)
      [expected_utility_of_player_candidates, condition_candidates] = obj.calculate_expected_utility_candidates_of_player(player, x);
      arg = {};
      for i = 1:length(expected_utility_of_player_candidates)
        arg = [arg, {condition_candidates{i}, expected_utility_of_player_candidates{i}}];
      end
      
      piecewise_expression = piecewise(arg{:});
    end
  end


end