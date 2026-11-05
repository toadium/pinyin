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

- `pub(all) suberror PinyinError` 错误类型 + `raise`/`try...catch`。

- `pub(all) enum` 供外部包构造；`pub enum` 仅允许 match。

- 字典数据用 `Map` 字面量 `{ k => v, ... }` 构建；大字典分段后 `.merge()` 合并。

- 黑盒测试（`_test.mbt`）与 README 可执行块中引用宿主包类型/方法/全局变量须加 `@pinyin.` 限定前缀（避免 [0025] test_unqualified_package）。

- 枚举变体在类型可推断位置（如 `format=` 参数）应裸用，不加 `@pinyin.` 限定（避免 [0073] unnecessary_annotation）。

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
  format the code.

## Project: pinyin

拼音转换库，移植自 `pinyin4cj`（仓颉）。
汉字→拼音 + 繁简转换 + 多音字 + 声调格式（带调标记/无调/数字调/首字母）。

- 模块名：`walkzzz/pinyin`，版本 0.1.1，MIT 许可证
- 仓库：https://github.com/toadium/pinyin.git
- moon 工具链：0.1.20260713

### 包结构

```
pinyin/                       # 根包 — 核心 API（源码在仓库根目录，非 src/）
├── pinyin_helper.mbt         # PinyinHelper 命名空间（拼音转换主入口，8 方法）
├── chinese_helper.mbt        # ChineseHelper 命名空间（繁简转换，6 方法）
├── tone_conversion.mbt       # 声调转换内部逻辑
├── pinyin_format.mbt         # PinyinFormat 枚举（4 种输出格式）
├── pinyin_error.mbt          # PinyinError 错误类型
├── pinyin_dicts.mbt          # 字典视图常量（与 data 包共享引用）
├── pinyin_easy_wbtest.mbt    # 白盒测试（内部逻辑，13 测试）
├── pinyin_mid_test.mbt       # 黑盒测试（正向/格式/自定义字典，19 测试）
├── pinyin_difficult_test.mbt # 黑盒测试（字典完整性，5 测试）
├── data/                     # 字典数据包（零依赖）
│   ├── chinese_dict.mbt      # 繁→简映射（2533 条）
│   ├── pinyin_dict.mbt       # 单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt # 词组拼音（843 条）
│   └── tongyong_pinyin_dict.mbt # 通用拼音（82 条）
├── examples/                 # 示例包（14 个示例测试）
├── docs/                     # 开发文档（roadmap/architecture/api/testing）
└── scripts/                  # 字典生成脚本（gen_pinyin_dict.py）
```

### 多后端支持

- `supported_targets = "+wasm+wasm-gc+js+native"`
- 四后端各 60 测试全通过，共 240 测试
- 严格模式 `--warn-list +73 --deny-warn` 零警告零错误
- 无 WASM local count 问题（字典用 Map 字面量，非大 match）

### MoonBit 语法要点

- **`pub(all) suberror`**：`pub(all) suberror PinyinError { PinyinError(String) }` 自动提升 Error，可用 `raise PinyinError("msg")` 抛错
- **`pub(all) enum`**：外部包可构造（黑盒测试需 pub(all)）
- **Map 字面量**：`{ k1 => v1, k2 => v2 }` 构建 Map；大字典分段后 `.merge()` 合并
- **snake_case**：MoonBit 函数命名用 snake_case（移植自 Cangjie camelCase）
- **字典视图共享**：根包 `chinese_map` 等与 data 包 `chinese_dict` 等共享同一 Map 对象引用（非拷贝），`add_*_dict_resource` 追加对两者均可见

### 测试约定

- 白盒测试（`_wbtest.mbt`）：验证内部逻辑，可访问包私有成员
- 黑盒测试（`_test.mbt`）：通过公开 API 验证端到端行为，须 `@pinyin.` 限定访问宿主包
- 示例测试（`examples/`）：可运行的示例，兼做测试
- `inspect` / `debug_inspect` 用于快照断言，`assert_eq` / `assert_true` / `assert_false` 用于稳定结果断言
- 自定义字典测试用 `set` + `remove` 清理副作用，避免测试间污染

### 文档

- `README.md`：项目文档（用户读）
- `README.mbt.md`：mooncakes 发布文档，含可执行测试块
- `CHANGELOG.md`：版本变更日志
- `docs/`：开发文档（roadmap / architecture / api / testing）
- `AGENTS.md`：本文件，项目规范

### Warning 治理记录（v0.1.1）

| Warning | 根因 | 治理 |
|---|---|---|
| `[0025] test_unqualified_package` | 黑盒测试/README 裸用宿主包符号 | 加 `@pinyin.` 限定前缀 |
| `[0020] deprecated to_repr` | example 用过时 `to_repr(x)` | 改为 `Repr(x)` |
| `[0073] unnecessary_annotation` | `format=@pinyin.PinyinFormat::Xxx` 限定冗余 | 枚举变体裸用（类型由参数推断） |