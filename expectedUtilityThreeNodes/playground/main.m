clear;

addpath(genpath('./classes'));
addpath(genpath('./data'));

% 乗客の出現確率ベクトル
p_i = [0.1; 0.2; 0.3];

% 遷移確率行列
p_jk = [
  0,   0.2, 0.8;
  0.4, 0,   0.6;
  0.7, 0.3, 0
];

% 遷移確率ベクトルを計算
transitionProbabilityVector = TransitionHelper.calculateTransitionProbabilityVector(p_i, p_jk);

for situationNumber = 0:63
  situation = Situation(situationNumber, "situationNumber");

  SituationHelper.displayAndSaveExpectedUtilityRecurrenceEquations(situation);
end

% expectedUtilityThreeNodes/playground/data/RecurrenceEquations_0.txtを読み込む

% 1. テキストファイルを読み込む
filename = './data/RecurrenceEquations_1.txt'; % ファイル名
fileContent = fileread(filename); % ファイル内容を読み込み
lines = splitlines(fileContent); % 各行ごとに分割

% 空行を除去
lines = lines(~cellfun('isempty', lines));

% 初期化
lhs_vars = {};
rhs_vars = {};

% 各行についてforループを回す
for i = 1:length(lines)
    line = strtrim(lines{i});
    
    % もしその行で---が含まれていれば、その行をスキップ
    if contains(line, '---')
        continue;
    end
    
    % もしその行で「漸化式左辺」という文字列が含まれていれば、その後の文字を変数として生成し、初期値を0とする
    if contains(line, '漸化式左辺')
        current_lhs = extractAfter(line, ': ');
        lhs_vars{end+1} = current_lhs;
    end
end

sorted_lhs_vars = custom_sort(lhs_vars);


function sorted_vars = custom_sort(vars)
  % Initialize a cell array to store extracted values and original variables
  extracted_vars = cell(size(vars, 2), 4);
  
  % Extract values and store them
  for i = 1:size(vars, 2)
    var = vars{i};
    pattern = 'x_(ps|v)(\d)_(\d+)';
    tokens = regexp(var, pattern, 'tokens');
    
    prefix = tokens{1}{1};
    firstNumber = str2double(tokens{1}{2});
    secondNumber = str2double(tokens{1}{3});
    
    extracted_vars{i, 1} = prefix;
    extracted_vars{i, 2} = firstNumber;
    extracted_vars{i, 3} = secondNumber;
    extracted_vars{i, 4} = var;
  end
  
  % Sort the extracted_vars cell array
  sorted_extracted_vars = sortrows(extracted_vars, [1, 2, 3], {'descend', 'ascend', 'ascend'});
  
  % Extract the sorted variables
  sorted_vars = sorted_extracted_vars(:, 4);
end