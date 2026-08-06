# 测试报告（v2）

## 概述

本任务为 pinyin4cj → MoonBit 移植的第 2 个编码任务的测试验证轮次。基于 `detail_v2.md` 行为契约与 `code_v2.md` 实现报告，为两个公开类型编写黑盒单元测试：

1. `pinyin_format_test.mbt` — 验证 `PinyinFormat::name` 方法对 4 个变体的返回值行为。
2. `pinyin_error_test.mbt` — 验证 `PinyinError` 的 raise/catch 行为与消息载荷保留。

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | pinyin_format_test.mbt | `PinyinFormat::name` 行为契约黑盒测试（5 用例） |
| 新建 | pinyin_error_test.mbt | `PinyinError` raise/catch 行为契约黑盒测试（3 用例） |

## 测试用例

### pinyin_format_test.mbt（5 用例）

| 用例名 | 覆盖维度 | 行为契约 |
|--------|---------|---------|
| `with_tone_mark_name_returns_WITH_TONE_MARK` | 正向 | `WithToneMark.name()` == `"WITH_TONE_MARK"` |
| `without_tone_name_returns_WITHOUT_TONE` | 正向 | `WithoutTone.name()` == `"WITHOUT_TONE"` |
| `with_tone_number_name_returns_WITH_TONE_NUMBER` | 正向 | `WithToneNumber.name()` == `"WITH_TONE_NUMBER"` |
| `first_letter_name_returns_FIRST_LETTER` | 正向 | `FirstLetter.name()` == `"FIRST_LETTER"` |
| `name_returns_distinct_strings_for_all_variants` | 边界/穷尽/状态交互 | 4 变体 name 返回值两两互异 |

### pinyin_error_test.mbt（3 用例）

| 用例名 | 覆盖维度 | 行为契约 |
|--------|---------|---------|
| `pinyin_error_carries_message` | 正向/错误路径 | `raise PinyinError("msg")` 可被 catch 捕获并提取消息 |
| `pinyin_error_with_empty_message` | 边界 | 空字符串消息可被承载与捕获 |
| `pinyin_error_preserves_distinct_messages` | 状态交互 | 不同消息产生可区分的错误值，消息载荷忠实保留 |

**辅助函数**：`raise_pinyin_error(msg : String) -> Unit raise @pinyin.PinyinError` — 包裹 `raise` 以适配 `try expr catch` 语法（MoonBit 中 `try` 后不可直接接 `raise` 表达式）。

## 设计依据

- 测试基于 `detail_v2.md` §行为契约 A/B 的公开接口行为，非实现细节。
- 黑盒测试惯例：`*_test.mbt` 文件，通过 `@pinyin.` 前缀引用主包公开 API（`pub(all) enum` / `pub(all) suberror` 允许外部构造与模式匹配）。
- 覆盖维度：正常路径（4 个 name 正向用例 + 1 个 error 捕获正向用例）、边界条件（穷尽 4 变体 + 空消息）、错误路径（raise/catch）、状态交互（变体可区分 + 消息可区分）。
- 每个被测类型对应一个测试文件（符合 verifier.md 规范）。
- 用例独立，不依赖执行顺序。

## 验证结果

### `moon check`

命令：`moon check`（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`）

结果：**成功**（exit code 0，0 errors，1 warnings）

警告原文：
```
Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'
```

处置：预期警告，与 R1/R2 状态一致，后续字典加载任务后消除。

### `moon test`

命令：`moon test`（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`）

结果：**全部通过**

```
Total tests: 8, passed: 8, failed: 0.
```

## 与实现报告的偏差

无偏差。测试覆盖 `code_v2.md` 暴露的全部公开 API：
- `PinyinFormat` 4 变体 + `PinyinFormat::name` 方法
- `PinyinError` 单变体 `PinyinError(String)` 的 raise/catch 行为

未测试 `to_string` / `get_message` 等方法（`code_v2.md` 未实现，属后续任务）。

## 修订说明

本任务为 NEW 动作（首轮测试编写），无前序审查意见。