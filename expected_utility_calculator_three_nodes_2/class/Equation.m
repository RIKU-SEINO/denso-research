classdef Equation
  properties
    player % Player
    player_set % PlayerSet
  end

  methods
    function obj = Equation(player, player_set)
      obj.player = player;
      obj.player_set = player_set;
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
      player_one_step_elapsed = obj.player.one_step_elapsed();
  
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
        player_matching_set = PlayerMatchingSet(player_matching_candidates);
        pw = player_matching_set.calculate_piecewise(player_one_step_elapsed, x);
        right_vec(i) = pw;
      end
    end

    function right_side = calculate_right_side(obj, x)
      [~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.getSymbolicParams();
      right_side = simplify(q' * obj.calculate_right_vec(x));
    end

    function right_vec = calculate_right_vec_specify_condition(obj, x, conditions)
      right_vec = obj.calculate_right_vec(x);
      for i = 1:length(right_vec)
        if isequal(right_vec(i), sym(0))
          continue;
        end

        value = [];
        for j = 1:length(conditions)
          condition = conditions(j);
          value = Equation.get_piecewise_value(right_vec(i), condition);
          if ~isempty(value)
            break;
          end
        end
        if isempty(value)
          conditions
          right_vec(i)
          error('条件に合致する値が見つかりませんでした');
        end
        right_vec(i) = value;
      end
    end

    function right_side = calculate_right_side_specify_condition(obj, x, conditions)
      [~, ~, ~, ~, ~, ~, ~, ~, q] = ParamsHelper.getSymbolicParams();
      right_side = simplify(q' * obj.calculate_right_vec_specify_condition(x, conditions));
    end
  end

  methods (Static)
    function value = get_piecewise_value(f, target_condition)
      value = [];
      % `piecewise` のピースを取得
      pieces = children(f);
      
      num_pieces = size(pieces, 1);
      if num_pieces == 1
        value = f;
        return;
      end
      
      % 対応するピースを探す
      for i = 1:num_pieces
          condition = pieces{i, 2}; % 条件部分
          if isAlways(simplify(condition) == simplify(target_condition))
              value = pieces{i, 1}; % そのピースの値
              return;
          end
      end
    end

    function [eqs, all_vars] = build_equations(objs, x, conditions)
      eqs = [];
      all_vars = [];
      for i = 1:length(objs)
        equation = objs{i};
        right_side = equation.calculate_right_side_specify_condition(x, conditions);
        player = equation.player;
        player_set = equation.player_set;
        x_sym = symvar(x(player_set.index(), player.index()));
        all_vars = union(all_vars, x_sym);
        eq = x_sym == right_side;
        eqs = [eqs, eq];
      end

      for i = 1:length(eqs)
        eqs(i) = collect(eqs(i), all_vars);
      end
    end

    function sol = solve_equations(eqs, all_vars)
      sol = solve(eqs, all_vars);
      % 各フィールドのうち、paramtersとconfitions以外をfactorする
      all_vars = fieldnames(sol);
      exclude_vars = {'parameters', 'conditions'};
      vars = setdiff(all_vars, exclude_vars);
      for i = 1:length(vars)
        try
          sol.(vars{i}) = prod(factor(sol.(vars{i})));
        catch
          % 空の場合はfactorしない
        end
      end
    end

    function constraints = validate_sol(sol, conditions)
      [w, c, r_0, a, ~, ~, ~, ~, ~] = ParamsHelper.getSymbolicParams();
      params = [w, c, r_0(1), r_0(2), r_0(3), a(1), a(2), a(3)];
      params = params(~isAlways(params == 0));
      constraints = {};
      all_vars = fieldnames(sol);
      exclude_vars = {'parameters', 'conditions'};
      vars = setdiff(all_vars, exclude_vars);
      values = cellfun(@(f) sol.(f), vars, 'UniformOutput', false);
  
      for i = 1:length(conditions)
        condition = conditions(i);

        % sol の変数を conditions に代入
        evaluated_condition = subs(condition, vars, values);
        if isempty(evaluated_condition)
          continue;
        end
        if ~ismember('&', char(evaluated_condition))
          diff_expr = lhs(evaluated_condition) - rhs(evaluated_condition);
          diff_expr = Equation.collect_by_vars(diff_expr, params);
          if ~isAlways(evaluated_condition)
            constraints{end+1, 1} = diff_expr <= 0;
          end
          continue;
        end

        evaluated_condition_elems = children(evaluated_condition);
        for j = 1:length(evaluated_condition_elems)
          evaluated_condition_elem = evaluated_condition_elems{j};
          if ~isAlways(evaluated_condition_elem)
            diff_expr = lhs(evaluated_condition_elem) - rhs(evaluated_condition_elem);
            diff_expr = Equation.collect_by_vars(diff_expr, params);
            constraints{end+1, 1} = diff_expr <= 0;
          end
        end
      end
    end

    function collected_expr = collect_by_vars(expr, vars)
      collected_expr = sym(0);
      not_collected_by_var = expr;
      for i = 1:length(vars)
        var = vars(i);
        [terms, coeffs_var] = coeffs(not_collected_by_var, var);
        if length(terms) > 2
          error('多項式の次数が2以上です');
        end
        factored_terms = arrayfun(@(t) prod(factor(t)), terms, 'UniformOutput', false);
        collected_by_var = coeffs_var .* isAlways(coeffs_var == var) * factored_terms';
        not_collected_by_var = coeffs_var .* ~isAlways(coeffs_var == var) * factored_terms';
        collected_expr = collected_expr + collected_by_var;
      end

      collected_expr = collected_expr + not_collected_by_var;
    end

    function result = is_valid_sol(sol)
      all_vars = fieldnames(sol);
      exclude_vars = {'parameters', 'conditions'};
      vars = setdiff(all_vars, exclude_vars);
      values = cellfun(@(f) sol.(f), vars, 'UniformOutput', false);
      result = true;
      for i = 1:length(values)
        if isempty(values{i})
          result = false;
          break;
        end
      end
    end
  end
end