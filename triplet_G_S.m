function [M_opt, u_max] = triplet_G_S(U,U_v,U_ps)
[i,j,k] = size(U);
M_opt = zeros(size(U));
M_opt(2:i,1,1) = 1;
M_opt(1,2:j,1) = 1;
M_opt(1,1,2:k) = 1;
U_v_tmp = U_v;
% repeat as long as unfeasible
while max(U_v_tmp,[],"all") > 0
    %まだキープされていないタクシーのうち，最も効用が大きいものを提案する
    [max_tmp, I] = max(U_v_tmp,[],"all");
    [ii,jj,kk] = ind2sub(size(U_v(ii,:,:)),I); %提案先のindexを取得
    if M_opt(ii,1,1) ~= 0
        continue
    end

    U_v(ii,jj,kk) = -1e10; %今後提案しないように
    
    % 空でない乗客に提案
    if jj ~= 1
        
        % 提案受け入れ
        if U_ps(ii,jj,kk) > sum(U_ps(:,jj,:).*M_opt(:,jj,:),"all")
            
            % 現在の乗客・貨物のマッチングを解消
            
            % 解消された乗客・貨物は空のタクシーとマッチング
            
        % 提案拒否
        else
        end

    % 空の乗客に提案
    else
        if M_opt(1,1,kk) == 1
            M_opt(1,1,kk) = 0;
            M_opt(ii,1,1) = 0;
            M_opt(ii,1,kk) = 1;
        end
    end
        
end

end

% algolithm
% 0. 乗客，貨物は空のタクシーをキープ
% 1. 誰にもキープされていないタクシーが，今まで断られていない中で一番マッチしたい乗客，まだマッチの決まっていない貨物に提案する
% 2. 提案を受けた乗客は，今キープしている人よりも良い相手なら，今までキープしていた人とは別れ，提案してきたタクシーをキープする
%       空の乗客は断らない
% 3. 乗客がキープ相手を変えたら，いっしょにキープしていた貨物は空のタクシーをキープし，新たな貨物が提案したタクシーをキープする
% 4. 1-3をくり返し，全てのタクシーが誰かしらにキープされたらその時点のマッチングをとってくる．