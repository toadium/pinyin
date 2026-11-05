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

## Tooling

- `moon fmt` is used to format your code properly.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- `moon check --target all` 验证四后端（wasm/wasm-gc/js/native）编译。

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code.

## Project: pinyin

拼音转换库，移植自 `pinyin4cj`（仓颉）。
汉字→拼音 + 繁简转换 + 多音字 + 声调格式（带调标记/无调/数字调/首字母）。

### 包结构

```
pinyin/               # 根包 — 核心 API
├── pinyin_helper.mbt     # PinyinHelper 命名空间（拼音转换主入口）
├── chinese_helper.mbt    # ChineseHelper 命名空间（繁简转换）
├── tone_conversion.mbt   # 声调转换内部逻辑
├── pinyin_format.mbt     # PinyinFormat 枚举（4 种输出格式）
├── pinyin_error.mbt      # PinyinError 错误类型
├── pinyin_dicts.mbt      # 字典视图常量（从 data 包加载）
├── data/                 # 字典数据包（零依赖）
│   ├── chinese_dict.mbt      # 繁→简映射（2533 条）
│   ├── pinyin_dict.mbt       # 单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt # 词组拼音（843 条）
│   └── tongyong_pinyin_dict.mbt # 通用拼音（82 条）
└── examples/             # 示例包（14 个示例测试）
```

### 多后端支持

- `supported_targets = "+wasm+wasm-gc+js+native"`
- 四后端验证：wasm 60/60 ✓ / wasm-gc 60/60 ✓ / js 60/60 ✓ / native 60/60 ✓

### MoonBit 语法要点

- **`pub(all) suberror`**：`pub(all) suberror PinyinError { PinyinError(String) }` 自动提升 Error，可用 `raise PinyinError("msg")` 腍错
- **`pub(all) enum`**：外部包可构造（黑盒测试需 pub(all)）
- **Map 字面量**：`{ k1 => v1, k2 => v2 }` 构建 Map；大字典分段后 `.merge()` 合并
- **snake_case**：MoonBit 函数命名用 snake_case（移植自 Cangjie camelCase）

### 文档

开发文档在 `docs/`：roadmap / architecture / api / testing。