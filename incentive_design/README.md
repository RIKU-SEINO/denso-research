# incentive_design

タクシーと乗客のマッチング問題における**インセンティブ設計**のための解析・最適化ツール群です。  
各方策（マッチングルール）に対して、ベルマン方程式・期待効用方程式をシンボリックに解き、最適性条件・安定性条件の導出、インセンティブの最適化、制約領域の可視化、およびシミュレーションを行います。

## 前提条件

- **MATLAB** R2022b 以降（Symbolic Math Toolbox, Optimization Toolbox が必要）
- **MPT3**（Multi-Parametric Toolbox 3）— 安定性条件の実行可能性判定に使用

## セットアップ

### 1. カレントディレクトリの移動

MATLAB コンソールで `incentive_design` フォルダに移動してください。以降のすべてのスクリプトは、このフォルダをカレントディレクトリとして実行する前提です。

```matlab
>> cd /path/to/incentive_design
```

### 2. MPT3 のインストール

```matlab
>> install_mpt3
```

`install_mpt3.m` は [tbxmanager](http://www.tbxmanager.com/) 経由で MPT3 と依存ライブラリ（cddmex, fourier, glpkmex, hysdel, lcp, sedumi, yalmip）を一括インストールします。

- インストール先に既存の `tbxmanager` フォルダがある場合は**自動で削除**してからクリーンインストールします。
- `startup.m` にパス復元処理を追記し、次回の MATLAB 起動時から自動でツールボックスが有効になります。
- Apple Silicon Mac では LCP の MEX ファイル（Intel 向け）が動作しませんが、MPT の大部分の機能は使用可能です。

### 3. パラメータの設定

モデルパラメータ（タクシー報酬 `w, c, a`、乗客報酬 `r, b`、出現確率 `p`、割引率 `g` など）は `class/ParamsHelper.m` の `get_valued_params()` で一元管理されています。値を変更したい場合はこのメソッドを編集してください。

## 実行ワークフロー

以下の順序で実行することを想定しています。各スクリプトは前段の出力ファイルに依存します。

```
install_mpt3.m → solver.m → optimizer.m → visualizer.m
                          ↘ policy_optimality_analyzer.m
                          ↘ policy_stability_analyzer.m
                          ↘ simulator.m
```

### ステップ 1: solver.m — シンボリック求解

```matlab
>> solver
```

全方策について、**ベルマン方程式**（状態価値関数）と**期待効用方程式**をシンボリックに解きます。

| 項目 | 内容 |
|---|---|
| **入力** | なし（`Policy.get_all_possible_policies()` から全方策を自動列挙） |
| **出力** | `result/symbolic_data.mat`（`state_value_solutions`, `expected_utility_solutions`） |
| **処理時間** | 数分〜十数分（方策数・パラメータ数に依存） |

既に `result/symbolic_data.mat` が存在する場合は再計算をスキップするか選択できます。

### ステップ 2: optimizer.m — インセンティブ最適化

```matlab
>> optimizer
```

各方策を安定化するインセンティブベクトルを、目的関数 `Σ(u_i)²`（L2 ノルム最小化）のもとで求めます。

| 項目 | 内容 |
|---|---|
| **入力** | `result/symbolic_data.mat` |
| **出力** | `result/optimizer/policy_<N>_<条件>_<安定性タイプ>.mat` |
| **ソルバー** | `fmincon`（非線形制約付き最適化） |

スクリプト冒頭の `%%%% EDIT HERE %%%%` セクションで以下を設定します。

| 設定項目 | 説明 | 例 |
|---|---|---|
| `stability_type` | 安定性の種類 | `'BP'` または `'EBP'` |
| `use_positive_incentive_condition` | マッチしないプレイヤへのインセンティブを非負に制約するか | `true` / `false` |

最適化成功後、その結果のインセンティブで各方策の期待効用を棒グラフ表示するか選択できます。

### ステップ 3: visualizer.m — 制約領域の可視化

```matlab
>> visualizer
```

最適化結果とシンボリック解を読み込み、インセンティブ空間上の**安定性制約領域**を 3 次元プロットします。

| 項目 | 内容 |
|---|---|
| **入力** | `result/symbolic_data.mat`, `result/optimizer/policy_<N>_*.mat` |
| **出力** | `result/visualizer/` 以下に `.fig` / `.eps` |

`%%%% EDIT HERE %%%%` セクションで以下を設定します。

| 設定項目 | 説明 | 例 |
|---|---|---|
| `stability_type` | 安定性の種類 | `'BP'` または `'EBP'` |
| `policy_index` | 可視化する方策のインデックス | `8` |
| `use_positive_incentive_condition` | 非負インセンティブ制約の有無 | `true` / `false` |
| `mode` | 射影モード | `'fixed_value_projection'` または `'optimal_value_projection'` |
| `target_plot_dimensions` | プロットするインセンティブ変数の次元 | `[3, 5, 7]` |
| `plot_bound` | 描画範囲の最大値（絶対値） | `500` |

### ステップ 4a: policy_optimality_analyzer.m — 最適性条件の導出

```matlab
>> policy_optimality_analyzer
```

各方策が**最適**（= その方策を選ぶことが全方策の中で状態価値を最大化する）であるためのパラメータ条件を、MPT3 を用いて導出します。

| 項目 | 内容 |
|---|---|
| **入力** | `result/symbolic_data.mat`（`state_value_solutions` を使用） |
| **出力** | コンソール出力（各方策が「無条件で実行可能」「実行不可能」「条件付きで実行可能」のいずれか） |
| **依存** | MPT3（不等式系の実行可能性判定に使用） |

`params_to_evaluate` で数値化するパラメータを指定します（例: `{'g', 'p_2', 'p_3'}`）。指定しなかったパラメータはシンボリックのまま条件式に残ります。方策ごとに `pause` で停止するので、Enter で次に進みます。

### ステップ 4b: policy_stability_analyzer.m — 安定化可能条件の導出

```matlab
>> policy_stability_analyzer
```

各方策が**インセンティブによって安定化可能**であるためのパラメータ条件を導出します。

| 項目 | 内容 |
|---|---|
| **入力** | `result/symbolic_data.mat`（`expected_utility_solutions` を使用） |
| **出力** | コンソール出力（各方策の安定化可能条件を OR / AND 結合で表示） |
| **依存** | MPT3 |

`%%%% EDIT HERE %%%%` セクションで以下を設定します。

| 設定項目 | 説明 | 例 |
|---|---|---|
| `stability_type` | 安定性の種類 | `'BP'` または `'EBP'` |
| `should_analyze_stabilizability` | 安定化可能条件の導出を行うか | `true` / `false` |
| `should_analyze_self_stability` | 自律的安定条件の導出を行うか | `true` / `false` |
| `params_to_evaluate` | 数値化するパラメータ | `{'g', 'p_2', 'p_3'}` |
| `use_positive_incentive_condition` | 非負インセンティブ制約の有無 | `true` / `false` |

### ステップ 5: simulator.m — 時系列シミュレーション

```matlab
>> simulator
```

全方策について 50 ステップのマッチングシミュレーションを行い、効用の累積推移を比較します。

| 項目 | 内容 |
|---|---|
| **入力** | なし（`ParamsHelper.get_valued_params()` の数値パラメータを使用） |
| **出力** | `simulation_result/` 以下に `social_utility_cumulative.png`, `taxi_utility_cumulative.png`, `passenger_<label>_utility_cumulative.png` |

シミュレーションの流れ:

1. 初期状態のプレイヤ集合を生成
2. 方策に従いマッチングを決定し、即時報酬を獲得
3. マッチング後の状態遷移（1 ステップ経過 → 乗客出現）を繰り返す
4. 社会全体・タクシー・各乗客別に効用の累積和を図示

## ディレクトリ構成

```
incentive_design/
├── solver.m                        # シンボリック求解
├── optimizer.m                     # インセンティブ最適化
├── visualizer.m                    # 制約領域の可視化
├── policy_optimality_analyzer.m    # 最適性条件の導出
├── policy_stability_analyzer.m     # 安定化可能条件の導出
├── simulator.m                     # 時系列シミュレーション
├── install_mpt3.m                  # MPT3 インストーラ
├── init_example.m                  # クラスの使用例
├── class/
│   ├── Player.m                    # プレイヤ（タクシー/乗客）
│   ├── PlayerPair.m                # プレイヤペア（タクシー-乗客の組）
│   ├── PlayerSet.m                 # プレイヤ集合（状態）
│   ├── PlayerSetGraph.m            # プレイヤ集合間の遷移グラフ
│   ├── PlayerMatching.m            # マッチング（どのペアが成立するか）
│   ├── Policy.m                    # 方策（各状態でのマッチングルール）
│   ├── OptimizationProblem.m       # 最適化問題（linprog/fmincon）
│   ├── ParamsHelper.m              # パラメータ管理・インセンティブ制約
│   ├── VariablesHelper.m           # 状態価値・期待効用の変数管理
│   ├── MathUtils.m                 # OR 条件の展開などの数学ユーティリティ
│   ├── EqualityInequalityHelper.m  # 等式/不等式制約の行列変換・MPT3 連携
│   ├── EquationStateValueFunction.m  # ベルマン方程式の構築・求解
│   ├── EquationExpectedUtility.m     # 期待効用方程式の構築・求解
│   ├── Utils.m                     # 汎用ユーティリティ
│   ├── ResultVisualizer.m          # 結果表示（棒グラフ等）
│   ├── solution/
│   │   ├── Solution.m              # 解の基底クラス
│   │   ├── StateValueSolution.m    # 状態価値関数の解
│   │   ├── ExpectedUtilitySolution.m # 期待効用の解
│   │   └── IncentiveSolution.m     # インセンティブの解
│   └── visualizer/
│       └── ConstraintVisualizer.m  # 制約領域の 3D 可視化
├── result/
│   ├── symbolic_data.mat           # solver.m の出力
│   ├── optimizer/                  # optimizer.m の出力
│   └── visualizer/                 # visualizer.m の出力
└── tbxmanager/                     # MPT3 および依存ライブラリ
```

## 動作確認方法

### 基本的なクラス動作の確認

```matlab
>> init_example
```

`Player`、`PlayerSet`、`PlayerPair`、`PlayerMatching`、`Policy` クラスの基本操作を確認できます。

### solver.m の動作確認

```matlab
>> solver
```

- 「計算を実行します。」と表示され、全方策について STEP1（ベルマン方程式）→ STEP2（期待効用方程式）が順に実行される
- `result/symbolic_data.mat` が生成される

正常完了の確認:

```matlab
>> data = load('result/symbolic_data.mat');
>> disp(length(data.state_value_solutions))      % 方策数が表示される
>> disp(length(data.expected_utility_solutions))  % 同上
```

### optimizer.m の動作確認

```matlab
>> optimizer
```

- 各方策について fmincon が実行され、最適化結果がコンソールに表示される
- `result/optimizer/` 以下に `policy_<N>_*.mat` ファイルが生成される

### visualizer.m の動作確認

```matlab
>> visualizer
```

- 3D の制約領域プロットが figure ウィンドウに表示される
- `result/visualizer/` 以下に `.fig` / `.eps` ファイルが生成される

### policy_optimality_analyzer.m の動作確認

```matlab
>> policy_optimality_analyzer
```

- 各方策ごとに「無条件で実行可能」/「実行不可能」/ 条件式 が表示される
- Enter で次の方策に進む

### policy_stability_analyzer.m の動作確認

```matlab
>> policy_stability_analyzer
```

- 各方策ごとに安定化可能条件が OR / AND 結合で表示される
- Enter で次の方策に進む

### simulator.m の動作確認

```matlab
>> simulator
```

- `simulation_result/` 以下に `.png` ファイルが生成される
- 社会全体・タクシー・各乗客別の効用累積推移グラフが figure ウィンドウに表示される
