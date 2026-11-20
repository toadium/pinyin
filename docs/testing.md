# 测试策略

## 测试组织

当前 native / wasm / wasm-gc / js 四个后端各 **326** 个测试，合计 **1304** 个测试全通过。

| 包 | 文件 | 类型 | 测试数 | 内容 |
|------|------|------|--------|------|
| `core` | `pinyin_core_wbtest.mbt` | 白盒 | 5 | PinyinFormat + PinyinError 内部逻辑 |
| `core` | `pinyin_trie_wbtest.mbt` | 白盒 | 9 | Trie + strip_tone 内部逻辑 |
| `core` | `pinyin_initials_finals_wbtest.mbt` | 白盒 | 7 | 声母/韵母提取边界 |
| `core` | `tone_conversion_coverage_wbtest.mbt` | 白盒 | 10 | 声调转换、标调位置、非法输入 |
| `convert` | `convert_wbtest.mbt` | 白盒 | 8 | 转换引擎内部逻辑 |
| `convert` | `convert_test.mbt` | 黑盒 | 22 | 正向用例、格式转换、自定义字典、共享引用 |
| `convert` | `convert_dict_test.mbt` | 黑盒 | 5 | 字典完整性验证（条目数、采样、边界） |
| `convert` | `stream_processor_test.mbt` | 黑盒 | 7 | 流式处理器（feed/flush/reset/增量输出） |
| `convert` | `pinyin_helper_coverage_wbtest.mbt` | 白盒 | 9 | 通用拼音、多音字、自定义词组、边界 |
| `convert` | `stream_processor_coverage_wbtest.mbt` | 白盒 | 7 | 自定义分隔符、首字母、词组增量、标点 |
| `reverse` | `reverse_test.mbt` | 黑盒 | 10 | 反向查找（无调/带调/数字调/合法性） |
| `reverse` | `reverse_coverage_wbtest.mbt` | 白盒 | 3 | 空串错误路径、三种调用一致、未知拼音 |
| `segment` | `segment_test.mbt` | 黑盒 | 12 | 分词（全切分/最优切分/歧义切分） |
| `segment` | `segment_coverage_wbtest.mbt` | 白盒 | 3 | 空串/无法切分/can_segment 边界 |
| `fuzzy` | `fuzzy_test.mbt` | 黑盒 | 20 | 模糊匹配（扩展/等价/反向查找，9 组规则） |
| `fuzzy` | `fuzzy_coverage_wbtest.mbt` | 白盒 | 5 | 空串错误路径、非法音节、自定义规则回滚 |
| `disambiguate` | `disambiguate_test.mbt` | 黑盒 | 7 | 多音字消歧（Viterbi+bigram） |
| `disambiguate` | `disambiguate_coverage_wbtest.mbt` | 白盒 | 5 | 空串、单字、多音单字、中英混合 |
| `disambiguate` | `common_phrases_test.mbt` | 黑盒 | 1 | 22 个常用多音词 |
| `disambiguate` | `accuracy_test.mbt` | 黑盒 | 1 | 66 条 gold 语料准确率（96.1% vs 68.0%） |
| `search` | `search_test.mbt` | 黑盒 | 9 | 搜索索引（首字母/连续/模糊） |
| `search` | `search_coverage_wbtest.mbt` | 白盒 | 8 | 空索引、非汉字、重复文档、无匹配 |
| `tone` | `tone_test.mbt` | 黑盒 | 14 | 声调变调（三声/一/不/七/八变调） |
| `tone` | `tone_sandhi_coverage_wbtest.mbt` | 白盒 | 6 | 各变调分支、同音字守卫、三声链 |
| `normalize` | `normalizer_test.mbt` | 黑盒 | 12 | 规范化（大小写/ü/v/声调格式） |
| `normalize` | `edit_distance_test.mbt` | 黑盒 | 8 | 编辑距离（Levenshtein/模糊距离） |
| `normalize` | `normalizer_coverage_wbtest.mbt` | 白盒 | 7 | 轻声数字 5、空串、大写混数字 |
| `lm` | `lm_test.mbt` | 黑盒 | 15 | N-gram 语言模型概率、句子、困惑度、统计 |
| `lm` | `lm_coverage_wbtest.mbt` | 白盒 | 12 | trigram/interpolation、回退、空输入、负 λ |
| `input` | `input_test.mbt` | 黑盒 | 30 | 输入法（Beam、词组、简拼、双拼、学习、常用字） |
| `shuangpin` | `shuangpin_test.mbt` | 黑盒 | 10 | 小鹤/自然码双向转换、逆向分支、ü 归一化 |
| `examples` | `*.mbt` | 黑盒 | 37 | 12 个子包示例 |
| **总计** | | | **326 / 后端** | **1304（四后端）** |

## 四后端验证

```bash
moon test --target wasm      --warn-list +73 --deny-warn   # 326/326 ✓
moon test --target wasm-gc   --warn-list +73 --deny-warn   # 326/326 ✓
moon test --target js        --warn-list +73 --deny-warn   # 326/326 ✓
moon test --target native    --warn-list +73 --deny-warn   # 326/326 ✓
```

四后端共 1304 测试全通过，严格模式零警告零错误。

## 覆盖率门禁

```bash
node scripts/check_coverage.mjs            # 运行 moon coverage analyze
node scripts/check_coverage.mjs --min 92   # 指定总门槛
```

- 统计范围：12 个核心包，排除 `data/`（纯数据）与 `examples/`（示例）。
- 门槛：总体 ≥ 92%，每个核心包 ≥ 85%。
- 当前实测：**1281/1360 = 94.2%**（core 96.6%、convert 90.3%、reverse 95.1%、
  fuzzy 96.4%、disambiguate 96.0%、search 95.2%、normalize 95.7%、
  lm 93.3%、input 92.3%）。

## 变异测试门禁

```bash
node scripts/mutation_test.mjs             # 全部变异点
node scripts/mutation_test.mjs --filter M01,M10
```

- 14 个单点变异，覆盖 core / convert / reverse / segment / fuzzy / tone /
  normalize / lm / input / search / disambiguate / data。
- 每个变异点要求相关包测试失败（KILLED）；当前 **14/14 KILLED**。
- 脚本自动恢复源文件，变异点必须唯一匹配（否则 SKIPPED 并阻断）。

## 文档一致性门禁

```bash
node scripts/check_docs.mjs
```

校验版本号、测试数、工具链版本、包数、覆盖率和变异门禁引用、文档相对链接。

## CI 流程

```bash
moon fmt    --check                                       # 格式检查
moon check  --target all --warn-list +73 --deny-warn      # 四后端编译检查
moon build  --target all --warn-list +73 --deny-warn      # 四后端构建
moon test   --target all --warn-list +73 --deny-warn      # 四后端测试
node scripts/check_docs.mjs                               # 文档一致性
node scripts/check_coverage.mjs                           # 覆盖率
node scripts/mutation_test.mjs                            # 变异（手动 job）
```

## 测试约定

- 白盒测试（`_wbtest.mbt`）：验证内部逻辑，可访问包私有成员，无需 `@包名.` 前缀
- 黑盒测试（`_test.mbt`）：通过公开 API 验证端到端行为，需 `@包名.` 限定访问宿主包
- 示例测试（`examples/`）：可运行的示例，兼做测试
- `inspect` / `debug_inspect` 用于快照断言，`assert_eq` / `assert_true` / `assert_false` 用于稳定结果断言
- 自定义字典/模糊规则测试用 `set` + `remove` / `push` + `pop` 清理副作用，避免测试间污染
- 覆盖率补测文件统一命名 `*_coverage_wbtest.mbt`，按包隔离

## Warning 治理记录

### v0.1.1

| Warning | 数量 | 根因 | 治理 |
|---|---|---|---|
| `[0025] test_unqualified_package` | 46 | 黑盒测试/README 裸用宿主包类型与全局变量 | 加 `@pinyin.` 限定前缀 |
| `[0020] deprecated to_repr` | 4 | example 用过时 `to_repr(x)` | 改为 `Repr(x)` |
| `[0073] unnecessary_annotation` | 7 | `format=@pinyin.PinyinFormat::Xxx` 限定冗余 | 枚举变体裸用（类型由参数推断） |

### v0.4.0

| Warning | 根因 | 治理 |
|---|---|---|
| `[0073] unnecessary_annotation` | `raise @core.PinyinError::InvalidInput("msg")` 在子包中触发误报（MoonBit 编译器 bug：[0073] 检查未考虑去掉前缀后标识符不可见） | 添加 `pub fn raise_invalid_input` 包装函数，子包用 `@core.raise_invalid_input("msg")` 代替直接 raise；catch 块改用 `_` 匹配 |
| `[0025] test_unqualified_package` | 黑盒测试迁移到子包目录后仍需 `@包名.` 前缀 | 各子包黑盒测试文件加对应 `@包名.` 前缀 |

### v0.5.0

| Warning | 根因 | 治理 |
|---|---|---|
| `[0073] unnecessary_annotation` | `LMStats::{...}` / `PinyinInputEngine::{...}` 构造注释冗余 | 去除类型注解，裸用 `{...}` 构造 |
| `[0073] unnecessary_annotation` | `Int` 类型注解与 `Int32` 不一致 | `moon fmt` 自动将 `Int` 修正为 `Int32` |

### v0.7.0

| 项 | 根因 | 治理 |
|---|---|---|
| wasm `local count too large` | `common_chars` 使用 3755 条 Map 字面量，加入 data 包全局初始化后越过 wasm 上限 | 改为字符串常量 + `String::find` 查找，运行时零大表初始化 |
| 新增代码零警告 | 严格模式 `--warn-list +73 --deny-warn` | 四后端 check/build/test 全绿 |