# 实现报告（v2）

## 概述

本任务为 pinyin4cj → MoonBit 移植的第 2 个编码任务，在主包根目录新增两个基础类型源文件：

1. `pinyin_format.mbt` — 定义 `PinyinFormat`（`pub(all) enum`，4 变体）与 `PinyinFormat::name` 方法，作为所有拼音转换方法的参数类型。
2. `pinyin_error.mbt` — 定义 `PinyinError`（`pub(all) suberror`，单变体 `PinyinError(String)`），作为拼音库统一错误类型。

两文件均位于主包根目录，与 `moon.pkg` 同级，被主包自动识别。未修改任何 R1 产出文件，未引用数据子包，未添加 `import`。

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | pinyin_format.mbt | `PinyinFormat` 枚举类型（4 变体）+ `PinyinFormat::name` 方法，对齐源库 `pinyin_format.cj` |
| 新建 | pinyin_error.mbt | `PinyinError` suberror 类型（单变体 `PinyinError(String)`），对齐源库 `utils.cj` 的 `Pinyin4cjException` |

## 编译验证

执行命令：`moon check`（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`）

结果：**成功**（exit code 0，0 errors，1 warnings）

警告原文：
```
Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'
  ╭─[ D:\CodeWorkspace\forMoonbit\pinyin\moon.pkg:2:3 ]
  │
2 │   "pinyin/pinyin/data",
  │   ──────────┬─────────  
  │             ╰─────────── Warning (unused_package): Unused package 'pinyin/pinyin/data'
───╯
Finished. moon: ran 1 task, now up to date (1 warnings, 0 errors)
```

警告治理：
- (a) 警告类型与消息文本：`Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`
- (b) 根因：主包源文件（`pinyin_format.mbt` / `pinyin_error.mbt`）均未引用 `@data.xxx` → import 的数据子包未被引用
- (c) 处置决策：**接受为预期警告**，不阻断本任务验收（与 R1 状态一致）
- (d) 消除条件：后续字典加载任务（`pinyin_dicts.mbt` 引用 `@data.xxx`）后警告自动消除
- (e) 记录方式：本报告此处记录警告原文与处置决策

## 设计偏差说明

无偏差。两文件内容、类型签名、方法实现、命名规范均与 `detail_v2.md` §类型定义 / §行为契约 A/B 逐字节对齐：

- `PinyinFormat` 为 `pub(all) enum`，4 变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`（PascalCase）。
- `PinyinFormat::name` 为 `pub fn PinyinFormat::name(self : PinyinFormat) -> String`，对每个变体返回大写下划线形式字符串字面量（逐字符对齐源库 `getName()`）。
- `PinyinError` 为 `pub(all) suberror`，单变体 `PinyinError(String)`（变体名与类型名同名，MoonBit `suberror` 惯例）。
- 两文件均含 `///` 文档注释，无 `import`，无 `derive` 子句，无额外方法（`to_string` / `get_message` 等留待后续任务）。
- 未修改 `moon.mod` / `moon.pkg` / `data/moon.pkg` / `README.mbt.md` / `README.md`，与 §行为契约 D 一致。
- 未创建后续任务文件（`pinyin_helper.mbt` / `chinese_helper.mbt` / `pinyin_dicts.mbt` / `tone_conversion.mbt` / `pinyin_spec.mbt` / 测试文件 / `data/*.mbt` 等），与 §依赖关系/后续任务边界一致，避免过度设计。