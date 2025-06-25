addpath('./class')
clc; clear; close all;

% プレイヤを作成
v10 = Player('v', 1, 0, 0);
ps21 = Player('ps', 2,1,0);
ps31 = Player('ps', 3,1,0);

% プレイヤ集合を作成
player_set = PlayerSet({v10; ps21; ps31});

% プレイヤ集合に対して、考えられる全てのプレイヤマッチングを取得
player_matchings = player_set.get_all_possible_player_matchings();

player_matching_1 = player_matchings{1}; % 全員取り残される
player_matching_2 = player_matchings{2}; % v10とps21がマッチングする
player_matching_3 = player_matchings{3}; % v10とps31がマッチングする

% 考えられる全ての方策を取得
policies = Policy.get_all_possible_policies();
% 一例として8つ目の方策を取得
policy = policies{8}; 