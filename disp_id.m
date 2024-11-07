% ps.t_m - ps.t0 を計算して5以上の条件を満たす論理配列を作成
conditionMet = arrayfun(@(ps) (ps.t_m - ps.t0) >= 15, PS_archive);

% 条件を満たすpsのidを抽出
matchingIDs = arrayfun(@(ps) ps.id, PS_archive(conditionMet));

% 条件を満たすIDを表示
disp('IDs where ps.t_m - ps.t0 >= 5:');
disp(matchingIDs);
