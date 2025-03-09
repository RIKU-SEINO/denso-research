classdef Equation
  properties
    player % Player
    player_set % PlayerSet
    left_side
    right_side
  end

  methods
    function obj = Equation(player, player_set, new_x)
      persistent cached_data; % キャッシュを保持する変数 (persistent)

      if nargin == 3
        cached_data = new_x;
      end
      if isempty(cached_data)
        data = load('data/data.mat', 'x');
        cached_data = data.x;
      end
      
      x = cached_data;

      obj.player = player;
      obj.player_set = player_set;
      obj.left_side = x(player_set.index(), player.index());
      obj.right_side = obj.calculate_right_side(x);
    end

    function right_vec = calculate_right_vec(obj, x)
      right_vec = sym(zeros(27, 1));

      if ~obj.player_set.is_present(obj.player)
        return;
      end

      [~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.getSymbolicParams();

      player_sets_after_one_step = obj.player_set.get_all_player_sets_after_one_step();
  
      for i = 1:length(player_sets_after_one_step)
        if q(i) == 0 % 本来はq(i) == 0の場合もright_vec(i)を計算する必要があるが、計算量削減のために省略
          continue;
        end
        player_set_after_one_step = player_sets_after_one_step{i};

        player_matching_candidates = player_set_after_one_step.get_all_player_matchings();

        cond_value_pairs = {};

        for j = 1:length(player_matching_candidates)
          player_matching = player_matching_candidates{j};

          expected_utility_of_player = player_matching.calculate_expected_utility_of_player(obj.player.one_step_elapsed(), x);

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

    function right_side = calculate_right_side(obj, x)
      [~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.getSymbolicParams();
      right_vec = obj.calculate_right_vec(x);
      right_side = simplify(q' * right_vec);
    end
  end
end