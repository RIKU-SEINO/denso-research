# incentive_design

タクシーと乗客のマッチング問題における**インセンティブ設計**のための解析・最適化ツール群です。各方策（マッチングルール）に対して、ベルマン方程式・期待効用方程式をシンボリックに解き、最適性条件・安定性条件の導出、インセンティブの最適化、制約領域の可視化、およびシミュレーションを行います。

## 前提条件

- **MATLAB** R2022b 以降（Symbolic Math Toolbox, Optimization Toolbox が必要）
- **MPT3**（Multi-Parametric Toolbox 3）— 安定性条件の実行可能性判定に使用

## セットアップ

### 1. カレントディレクトリの移動

```matlab
>> cd /path/to/incentive_design
```

以降のすべてのスクリプトは、このフォルダをカレントディレクトリとして実行する前提です。

### 2. MPT3 のインストール

```matlab
>> install_mpt3
```

[tbxmanager](http://www.tbxmanager.com/) 経由で MPT3 と依存ライブラリ（cddmex, fourier, glpkmex, hysdel, lcp, sedumi, yalmip）を、スクリプトと同じディレクトリ直下の `tbxmanager/` に一括インストールします。フォルダ選択ダイアログは表示されません。既に `tbxmanager` フォルダがある場合は自動で削除してからクリーンインストールします。

インストール途中で、各ツールボックスのライセンス同意を求められるのでyを入力しEnterで進んでください

```
You need to agree to the following license to install "yalmip":

--------------------------------------------------------------------------------
YALMIP is free of charge to use and is openly distributed, but note that
1. Copyright owned by Johan Lofberg.
2. YALMIP must be referenced when used in a published work (give me some credit for saving your valuable time!)
3. YALMIP, or forks or versions of YALMIP, may not be re-distributed as a part of a commercial product unless agreed upon with the copyright owner (if you make money from YALMIP, let me in first!)
4. YALMIP is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE (if your satellite crash or you fail your Phd due to a bug in YALMIP, your loss!).
5. Forks or versions of YALMIP must include, and follow, this license in any distribution.
--------------------------------------------------------------------------------

? 
```

**`y` を入力して Enter** を押してください。この確認は複数回表示される場合があります（各ツールボックスごと）。すべて `y` で進めてください。

> Apple Silicon Mac では LCP の MEX ファイル（Intel 向け）が動作しませんが、MPT の大部分の機能は使用可能です。「無効な MEX ファイル」エラーが表示されても無視して構いません。

### 3. パラメータの設定

モデルパラメータは `class/ParamsHelper.m` の `get_valued_params()` で一元管理されています。デフォルト値は以下の通りです。

| パラメータ | 意味 | デフォルト値 |
|---|---|---|
| `w` | タクシーの運賃単価 | `2000` |
| `c` | タクシーの移動コスト単価 | `10` |
| `a` | タクシーの待機ペナルティ | `100` |
| `r` | 乗客の報酬ベクトル `[r_1; r_2; r_3]` | `[0; 1500; 1250]` |
| `b` | 乗客の距離コストベクトル `[b_1; b_2; b_3]` | `[0; 100; 50]` |
| `p` | 乗客の出現確率ベクトル `[p_1; p_2; p_3]` | `[0; 0.8; 0.2]` |
| `g` | 割引率 | `0.95` |

値を変更する場合は `get_valued_params()` を直接編集してください。安定性分析（`policy_stability_analyzer` 等）で計算量が爆発する場合は `g = 0` を推奨します。

## 実行ワークフロー

```
install_mpt3 → solver → incentive_optimizer → incentive_visualizer
                      ↘ policy_optimality_analyzer
                      ↘ policy_stability_analyzer
                      ↘ simulator
```

---

### solver.m — シンボリック求解

```matlab
>> solver
```

全方策についてベルマン方程式（状態価値関数）と期待効用方程式をシンボリックに解き、`result/symbolic_data.mat` に保存します。既に結果がある場合は再計算をスキップするか対話的に選択できます。

このスクリプトには EDIT HERE セクションはありません。`params_to_evaluate` と `is_exclude_mode` をスクリプト内で直接変更することで、一部のパラメータだけを数値化した状態でシンボリック計算を行えます。

---

### incentive_optimizer.m — インセンティブ最適化

```matlab
>> incentive_optimizer
```

各方策を安定化するインセンティブベクトルを、目的関数 Σ(u_i)²（L2 ノルム最小化）のもとで `fmincon` により求めます。結果は `result/optimizer/` 以下に保存されます。

**EDIT HERE セクション（スクリプト冒頭 5〜9 行目）:**

```matlab
target_data = 'result/symbolic_data.mat';
stability_type = 'BP';                      % 'BP' または 'EBP'
use_positive_incentive_condition = true;     % マッチしないプレイヤへのインセンティブを非負に制約するか
```

| 設定項目 | 説明 |
|---|---|
| `stability_type` | 安定性の種類。`'BP'`（ブロッキングペア安定）または `'EBP'`（交換ブロッキングペア安定）|
| `use_positive_incentive_condition` | `true` の場合、方策上でマッチしないプレイヤに付与するインセンティブを 0 以上に制約する |

各方策の最適化後、結果のインセンティブで全方策の期待効用を棒グラフ表示するか対話的に選択できます。Enter で次の方策に進みます。

---

### incentive_visualizer.m — 制約領域の可視化

```matlab
>> incentive_visualizer
```

最適化結果とシンボリック解を読み込み、インセンティブ空間上の安定性制約領域を 3 次元プロットします。結果は `result/visualizer/` 以下に `.fig` / `.eps` で保存されます。

**EDIT HERE セクション（スクリプト冒頭 7〜39 行目）:**

```matlab
stability_type = 'EBP';                     % 'BP' または 'EBP'
policy_index = 8;                           % 可視化する方策のインデックス
use_positive_incentive_condition = true;     % 非負インセンティブ制約の有無
mode = 'optimal_value_projection';          % 射影モード
target_plot_dimensions = [3, 5, 7];         % プロットするインセンティブ変数の次元（3つ選択）
plot_bound = 500;                           % 描画範囲の最大値（絶対値）
```

| 設定項目 | 説明 |
|---|---|
| `stability_type` | 安定性の種類 |
| `policy_index` | 可視化対象の方策番号 |
| `use_positive_incentive_condition` | 非負インセンティブ制約の有無 |
| `mode` | `'fixed_value_projection'`（EBP 固定）または `'optimal_value_projection'`（`stability_type` に連動）|
| `target_plot_dimensions` | 7 次元のインセンティブ変数から 3 つを選んでプロットする。インデックスで指定 |
| `plot_bound` | 各軸の描画範囲 `[-plot_bound, plot_bound]` |

---

### policy_optimality_analyzer.m — 最適性条件の導出

```matlab
>> policy_optimality_analyzer
```

各方策が最適（= 全方策の中で状態価値を最大化する）であるためのパラメータ条件を MPT3 で導出し、コンソールに表示します。方策ごとに Enter で次に進みます。

**EDIT HERE セクション（スクリプト冒頭 7〜9 行目）:**

```matlab
target_data = 'result/symbolic_data.mat';
params_to_evaluate = {'g', 'p_2', 'p_3'};  % 数値化するパラメータ
```

| 設定項目 | 説明 |
|---|---|
| `params_to_evaluate` | 数値的に評価するパラメータ名を文字列の cell 配列で指定。ここに含めなかったパラメータはシンボリックのまま条件式に残る |

---

### policy_stability_analyzer.m — 安定化可能条件の導出

```matlab
>> policy_stability_analyzer
```

各方策がインセンティブによって安定化可能であるためのパラメータ条件を導出し、コンソールに OR / AND 結合で表示します。方策ごとに Enter で次に進みます。

**EDIT HERE セクション（スクリプト冒頭 7〜13 行目）:**

```matlab
target_data = 'result/symbolic_data.mat';
stability_type = 'EBP';                     % 'BP' または 'EBP'
should_analyze_stabilizability = true;       % 安定化可能条件の導出を行うか
should_analyze_self_stability = false;       % 自律的安定条件の導出を行うか
params_to_evaluate = {'g', 'p_2', 'p_3'};   % 数値化するパラメータ
use_positive_incentive_condition = true;     % 非負インセンティブ制約の有無
```

| 設定項目 | 説明 |
|---|---|
| `stability_type` | 安定性の種類 |
| `should_analyze_stabilizability` | `true` でインセンティブ安定化可能条件を導出する |
| `should_analyze_self_stability` | `true` で自律的安定条件（インセンティブなし）を導出する |
| `params_to_evaluate` | 数値化するパラメータ名 |
| `use_positive_incentive_condition` | 非負インセンティブ制約の有無 |

---

### simulator.m — 時系列シミュレーション

```matlab
>> simulator
```

全方策について 50 ステップのマッチングシミュレーションを実行し、社会全体・タクシー・各乗客別の効用累積推移を比較プロットします。結果は `simulation_result/` 以下に `.png` で保存されます。

このスクリプトには EDIT HERE セクションはありません。パラメータは `ParamsHelper.get_valued_params()` のデフォルト値がそのまま使われます。初期状態はノード 1 にタクシー 1 台（`Player('v', 1, 0, 0)`）です。

---

## ディレクトリ構成

```
incentive_design/
├── solver.m                        # シンボリック求解
├── incentive_optimizer.m           # インセンティブ最適化
├── incentive_visualizer.m          # 制約領域の可視化
├── policy_optimality_analyzer.m    # 最適性条件の導出
├── policy_stability_analyzer.m     # 安定化可能条件の導出
├── simulator.m                     # 時系列シミュレーション
├── install_mpt3.m                  # MPT3 インストーラ
├── init_example.m                  # クラスの使用例
├── class/
│   ├── ParamsHelper.m              # パラメータ管理・インセンティブ制約
│   ├── Player.m                    # プレイヤ（タクシー/乗客）
│   ├── PlayerPair.m                # プレイヤペア（タクシー-乗客の組）
│   ├── PlayerSet.m                 # プレイヤ集合（状態）
│   ├── PlayerSetGraph.m            # プレイヤ集合間の遷移グラフ
│   ├── PlayerMatching.m            # マッチング（どのペアが成立するか）
│   ├── Policy.m                    # 方策（各状態でのマッチングルール）
│   ├── OptimizationProblem.m       # 最適化問題（linprog/fmincon）
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
│   ├── symbolic_data.mat           # solver の出力
│   ├── optimizer/                  # incentive_optimizer の出力
│   └── visualizer/                 # incentive_visualizer の出力
└── tbxmanager/                     # MPT3 および依存ライブラリ（.gitignore 対象）
```
