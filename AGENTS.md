# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending
  in `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant.

- snake_case 命名风格（移植自 Cangjie camelCase，逐函数手动转换）。

- `pub(all) suberror PinyinError` 错误类型 + `raise`/`try...catch`。子包用 `@core.raise_invalid_input("msg")` 包装函数抛错（规避 [0073] 跨包 bug），catch 块用 `_` 匹配。

- `pub(all) enum` 供外部包构造；`pub enum` 仅允许 match。

- 字典数据用 `Map` 字面量 `{ k => v, ... }` 构建；大字典分段后 `.merge()` 合并。

- 黑盒测试（`_test.mbt`）与 README 可执行块中引用宿主包类型/方法/全局变量须加 `@包名.` 限定前缀（避免 [0025] test_unqualified_package）。即使测试文件放在子包目录中，仍需 `@包名.` 前缀。

- 枚举变体在类型可推断位置（如 `format=` 参数）应裸用，不加 `@包名.` 限定（避免 [0073] unnecessary_annotation）。

- 弃用 `to_repr(x)`，改用 `Repr(x)`（避免 [0020] deprecated）。

## Tooling

- `moon fmt` is used to format your code properly.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- 严格四后端验证（零警告零错误）：

  ```bash
  moon fmt    --check
  moon check  --target all --warn-list +73 --deny-warn
  moon build  --target all --warn-list +73 --deny-warn
  moon test   --target all --warn-list +73 --deny-warn
  moon info   --target all
  ```

- In the last step, run `moon info && moon fmt` to update the interface and
- format the code.

## Project: pinyin

拼音引擎：汉字→拼音 + 拼音→汉字 + 繁简转换 + 多音字消歧 + 拼音分词 + 模糊匹配 + 搜索索引 + 变调规则 + 编辑距离 + 规范化 + 流式处理 + N-gram 语言模型 + 拼音输入法。

- 模块名：`walkzzz/pinyin`，版本 0.8.0，MIT 许可证
- 仓库：https://github.com/toadium/pinyin.git
- moon 工具链：0.1.20261117

### 包结构（13 包扁平多根布局）

```
pinyin/                         # 根包 — 文档入口（不导入任何子包）
├── pinyin.mbt                  #   根包文档入口
├── core/                       # 核心类型 + 声调转换 + Trie + 声母韵母（零依赖）
│   ├── pinyin_format.mbt       #   PinyinFormat 枚举（4 变体）
│   ├── pinyin_error.mbt        #   PinyinError suberror + raise_invalid_input
│   ├── fuzzy_rule.mbt          #   FuzzyRule 枚举
│   ├── tone_conversion.mbt     #   声调转换函数
│   ├── pinyin_trie.mbt         #   PinyinTrie + ~420 音节 + strip_tone
│   ├── pinyin_initials_finals.mbt # get_initial/get_final/initials_list
│   ├── pinyin_core_wbtest.mbt  #   白盒测试（5）
│   ├── pinyin_trie_wbtest.mbt  #   白盒测试（9）
│   ├── pinyin_initials_finals_wbtest.mbt # 白盒测试（7）
│   └── tone_conversion_coverage_wbtest.mbt # 覆盖率补测（10）
├── data/                       # 字典数据包（零依赖）
│   ├── chinese_dict.mbt        #   繁→简映射（2533 条）
│   ├── pinyin_dict.mbt         #   单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt   #   词组拼音（843 条）
│   ├── tongyong_pinyin_dict.mbt #  通用拼音（82 条）
│   └── common_chars.mbt        #   常用字排序（GB2312 一级 3755 + 高频字序）
├── convert/                    # 核心转换引擎（依赖 core + data）
│   ├── pinyin_dicts.mbt        #   字典视图常量（与 data 包共享引用）
│   ├── chinese_helper.mbt      #   ChineseHelper（6 方法）
│   ├── pinyin_helper.mbt       #   PinyinHelper（8 方法）
│   ├── pinyin_stream_processor.mbt # PinyinStreamProcessor（4 方法）
│   ├── convert_wbtest.mbt      #   白盒测试（8）
│   ├── convert_test.mbt        #   黑盒测试（22）
│   ├── convert_dict_test.mbt   #   黑盒测试（5）
│   ├── stream_processor_test.mbt # 黑盒测试（7）
│   ├── pinyin_helper_coverage_wbtest.mbt # 覆盖率补测（9）
│   └── stream_processor_coverage_wbtest.mbt # 覆盖率补测（7）
├── reverse/                    # 拼音→汉字反向查找（依赖 core + data）
├── segment/                    # 拼音分词 Trie+DP（依赖 core）
├── fuzzy/                      # 模糊匹配 BFS（依赖 core + reverse，9 组规则）
├── disambiguate/               # 多音字消歧 Viterbi+bigram（依赖 core + convert）
├── search/                     # 搜索索引倒排（依赖 core + convert + segment + fuzzy）
├── tone/                       # 声调变调规则（依赖 core，5 类变调）
├── normalize/                  # 规范化 + 编辑距离（依赖 core + segment + fuzzy）
├── lm/                         # N-gram 语言模型（依赖 core + data + math）
│   ├── pinyin_lm.mbt           #   PinyinLM + LMStats + Laplace + Katz + Interpolation
│   ├── lm_test.mbt             #   黑盒测试（15）
│   └── lm_coverage_wbtest.mbt  #   覆盖率补测（12）
├── input/                      # 拼音输入法引擎（依赖 core + segment + reverse + lm + math + data + fuzzy + shuangpin）
│   ├── pinyin_input.mbt        #   PinyinInputEngine + InputCandidate + Beam Search + 词库/双拼/简拼/学习
│   └── input_test.mbt          #   黑盒测试（30）
├── shuangpin/                  # 双拼输入（小鹤/自然码，双拼↔全拼，零依赖）
│   ├── pinyin_shuangpin.mbt
│   └── shuangpin_test.mbt      #   黑盒测试（10）
├── examples/                   # 示例包（12 子包全覆盖，37 个示例测试）
├── demo/                       # 端到端可运行演示（moon run demo）
├── docs/                       # 开发文档（roadmap/architecture/api/testing）
└── scripts/                    # 字典生成 + 工程门禁
    ├── gen_pinyin_dict.py      #   字典生成
    ├── gen_common_chars.py     #   常用字排序表生成
    ├── check_coverage.mjs      #   覆盖率门禁（总 ≥92%，每包 ≥85%）
    ├── mutation_test.mjs       #   变异测试门禁（14 个变异点）
    └── check_docs.mjs          #   文档一致性门禁
```

### 依赖拓扑

```
core（零依赖）    data（零依赖）
  ↑                  ↑
convert（core+data）
  ↑
┌───┴───┬──────────┬──────────┐
reverse segment  fuzzy    disambiguate
    ↑         ↑         ↑
  search    normalize    tone
    ↑
lm（core+data+math）
  ↑
input（core+segment+reverse+lm+math+data+fuzzy）
```

线性无环依赖，core/data 零依赖，各子包职责单一。参照 owl-mbt 项目理念。

### 多后端支持

- `supported_targets = "+wasm+wasm-gc+js+native"`
- 四后端各 326 测试全通过，共 1304 测试
- 严格模式 `--warn-list +73 --deny-warn` 零警告零错误
- 字典用 Map 字面量；`common_chars` 用字符串常量 + `String::find`，避免 wasm 全局初始化 local count 超限

### 工程质量门禁

```bash
moon fmt    --check
moon check  --target all --warn-list +73 --deny-warn
moon build  --target all --warn-list +73 --deny-warn
moon test   --target all --warn-list +73 --deny-warn
node scripts/check_docs.mjs
node scripts/check_coverage.mjs      # 核心 ≥92%，每包 ≥85%
node scripts/mutation_test.mjs       # 14/14 KILLED
```

- 覆盖率补测文件统一命名 `*_coverage_wbtest.mbt`。
- 变异点必须唯一匹配源码（`occurrences == 1`），否则脚本 SKIPPED 并阻断。
- 任何文档数字以实测为准：测试数 326/后端、覆盖 94.2%、工具链 0.1.20261117。

### MoonBit 语法要点

- **`pub(all) suberror`**：`pub(all) suberror PinyinError { InvalidInput(String) }` 自动提升 Error。子包用 `@core.raise_invalid_input("msg")` 包装函数抛错（规避 [0073] 跨包 bug），catch 块用 `_` 匹配
- **`pub(all) enum`**：外部包可构造（黑盒测试需 pub(all)）
- **Map 字面量**：`{ k1 => v1, k2 => v2 }` 构建 Map；大字典分段后 `.merge()` 合并
- **snake_case**：MoonBit 函数命名用 snake_case（移植自 Cangjie camelCase）
- **字典视图共享**：convert 包 `chinese_map` 等与 data 包 `chinese_dict` 等共享同一 Map 对象引用（非拷贝），`add_*_dict_resource` 追加对两者均可见

### 测试约定

- 白盒测试（`_wbtest.mbt`）：验证内部逻辑，可访问包私有成员，无需 `@包名.` 前缀
- 黑盒测试（`_test.mbt`）：通过公开 API 验证端到端行为，须 `@包名.` 限定访问宿主包
- 示例测试（`examples/`）：可运行的示例，兼做测试
- `inspect` / `debug_inspect` 用于快照断言，`assert_eq` / `assert_true` / `assert_false` 用于稳定结果断言
- 自定义字典测试用 `set` + `remove` 清理副作用，避免测试间污染

### 文档

- `README.md`：项目文档（用户读）
- `README.mbt.md`：mooncakes 发布文档，含可执行测试块
- `CHANGELOG.md`：版本变更日志
- `docs/`：开发文档（roadmap / architecture / api / testing）
- `AGENTS.md`：本文件，项目规范

### Warning 治理记录

#### v0.1.1

| Warning | 根因 | 治理 |
|---|---|---|
| `[0025] test_unqualified_package` | 黑盒测试/README 裸用宿主包符号 | 加 `@pinyin.` 限定前缀 |
| `[0020] deprecated to_repr` | example 用过时 `to_repr(x)` | 改为 `Repr(x)` |
| `[0073] unnecessary_annotation` | `format=@pinyin.PinyinFormat::Xxx` 限定冗余 | 枚举变体裸用（类型由参数推断） |

#### v0.4.0

| Warning | 根因 | 治理 |
|---|---|---|
| `[0073] unnecessary_annotation` | `raise @core.PinyinError::InvalidInput("msg")` 在子包中触发误报（MoonBit 编译器 bug） | 添加 `pub fn raise_invalid_input` 包装函数，子包用 `@core.raise_invalid_input("msg")`；catch 块改用 `_` 匹配 |
| `[0025] test_unqualified_package` | 黑盒测试迁移到子包目录后仍需 `@包名.` 前缀 | 各子包黑盒测试文件加对应 `@包名.` 前缀 |

#### v0.5.0

| Warning | 根因 | 治理 |
|---|---|---|
| `[0073] unnecessary_annotation` | `LMStats::{...}` / `PinyinInputEngine::{...}` 构造注释冗余 | 去除类型注解，裸用 `{...}` 构造 |
| `[0073] unnecessary_annotation` | `Int` 类型注解与 `Int32` 不一致 | `moon fmt` 自动将 `Int` 修正为 `Int32` |