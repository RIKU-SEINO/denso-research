classdef Equation
  properties
    player % Player
    player_set % PlayerSet
    left_side
    right_vec
  end

  methods
    function obj = Equation(player, player_set, x)
      obj.player = player;
      obj.player_set = player_set;
      obj.left_side = x(player_set.index(), player.index());
      obj.right_vec = obj.calculate_right_vec(x);
    end
  end

  methods
    function right_vec = calculate_right_vec(obj, x)
      right_vec = sym(zeros(27, 1)); 

      if ~obj.player_set.is_present(obj.player)
        return;
      end

      [~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.getSymbolicParams();

      player_sets_after_one_step = obj.player_set.get_all_player_sets_after_one_step();
  
      idx = 1;
      for i = 1:length(right_vec)
        if q(i) == 0
          continue;
        end

        % Player.get_all_player_sets_after_one_stepの定義から、Player.get_all_passengersの返り値とPlayer.get_all_player_sets_after_one_stepの返り値の長さは等しい。その長さが27と等しい（general case）か、計算量削減のためなどにall_passengersを減らすことで27未満になっている（hard code）かで条件分岐を行う
        if length(player_sets_after_one_step) == 27
          player_set_after_one_step = player_sets_after_one_step{i};
        else
          player_set_after_one_step = player_sets_after_one_step{idx};
          idx = idx + 1;
        end

        player_matching_candidates = player_set_after_one_step.get_all_player_matchings();

        cond_value_pairs = {};

        for j = 1:length(player_matching_candidates)
          player_matching = player_matching_candidates{j};

          expected_utility_of_player = player_matching.calculate_expected_utility_of_player(obj.player.one_step_elapsed(), x);

          if isAlways(expected_utility_of_player < 0)
            error('expected utility should not always be negative');
          end

          expected_utility_sum = player_matching.calculate_expected_utility_sum(x);

          other_js = setdiff(1:length(player_matching_candidates), j);

          cond_expr = symtrue;

          for k = 1:length(other_js)
            other_player_matching = player_matching_candidates{other_js(k)};

            other_expected_utility_sum = other_player_matching.calculate_expected_utility_sum(x);

            new_cond_expr = expected_utility_sum > other_expected_utility_sum;

            cond_expr = simplify(and(cond_expr, new_cond_expr));
          end
          cond_value_pairs = [cond_value_pairs, {cond_expr, expected_utility_of_player}];
        end
        cond_value_pairs = [cond_value_pairs, {sym(0)}];
        pw = piecewise(cond_value_pairs{:});
        right_vec(i) = pw;
      end
    end

    function right_side = calculate_right_side(obj)
      [~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.getSymbolicParams();
      right_side = simplify(q' * obj.right_vec);
    end
  end
end