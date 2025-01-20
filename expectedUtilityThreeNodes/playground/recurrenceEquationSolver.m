clear;

addpath(genpath('./classes'));
addpath(genpath('./data'));

%%% Parameter Settings %%%
nodeNum = 3; % ノード数
w = 10; % viがpsjを運ぶ際に得る報酬
m = 5; % 乗客が出現してからタクシーが到着するまでの時間
r_0 = [10, 5, 3]; % 乗客がマッチした時に得る効用
alpha = [0.01; 0.02; 0.03]; % 乗客が単位時間で低減する効用

u = calculateTaxiUtilities(nodeNum, w); % タクシーの効用テンソル
r = calculatePassengerUtilities(nodeNum, r_0); % 乗客の効用行列

p_i = [0.8; 0.6; 0.1]; % psjが出現する確率
p_jk = [
  0,   0.2, 0.8;
  0.4, 0,   0.6;
  0.7, 0.3, 0
]; % 出現したpsjが目的地をkに選ぶ確率

% 期待効用行列 (64x6)
% row: 状況番号 (0~63) -> 1つのノードに, viとpsiが出現するか否かの組み合わせが4通りあるため, 4^nodeNum = 64通り
% column: プレイヤ番号 (1~6) v1: 1, ps1: 2, v2: 3, ps2: 4, v3: 5, ps3: 6
x = zeros(4^nodeNum, 2*nodeNum);

% 遷移確率ベクトル (64x64)
q = TransitionHelper.calculateTransitionProbabilityVector(p_i, p_jk);

%%% END OF Parameter Settings %%%

%%% Recurrence Equation Solver %%%
currentPlayerIndex = 1;





%%% Helper Functions
% タクシーの効用テンソル
% u(i,j,k): viがpsjをkに運ぶ際に得る報酬
function u = calculateTaxiUtilities(nodeNum, w)
  u = zeros(nodeNum, nodeNum, nodeNum);
  for i = 1:nodeNum
    for j = 1:nodeNum
      for k = 1:nodeNum
        c = abs(i - j) + abs(j - k);
        u(i, j, k) = w - c;
      end
    end
  end
end

% 乗客の効用行列
% r(i,j): viがpsjを運ぶ際に得る報酬
function r = calculatePassengerUtilities(nodeNum, r, alpha)
  for i = 1:nodeNum
    for j = 1:nodeNum
      r(i, j) = r(i) - abs(i - j)*alpha(i);
    end
  end
end

