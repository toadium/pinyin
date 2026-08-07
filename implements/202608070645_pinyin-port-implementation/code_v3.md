# 实现报告（v3）

## 概述

实现了 pinyin4cj → MoonBit 字典字面量生成脚本 `scripts/gen_pinyin_dict.py`（Python 3），并运行脚本生成 4 个数据子包源文件：
- `data/chinese_dict.mbt` — `pub let chinese_dict : Map[Int, Int]`，2543 条繁→简码点映射
- `data/mutil_pinyin_dict.mbt` — `pub let mutil_pinyin_dict : Map[String, String]`，845 条词组拼音
- `data/tongyong_pinyin_dict.mbt` — `pub let tongyong_pinyin_dict : Map[String, String]`，82 条通用拼音
- `data/pinyin_dict.mbt` — `pub let pinyin_dict : Map[String, String]`，20903 条单字拼音

脚本含模块文档字符串、函数文档字符串、关键步骤注释；所有文件读写显式指定 `encoding="utf-8"`；四张字典按 key 排序输出，多次运行产生字节级一致产物；条目数严格断言（2543 / 845 / 82 / 20903），全部通过。

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | scripts/gen_pinyin_dict.py | Python 3 生成脚本：解析源库四张字典 → 断言条目数 → 按 key 排序 → 写入 4 个 .mbt 字面量文件 |
| 新建（脚本生成） | data/chinese_dict.mbt | `pub let chinese_dict : Map[Int, Int]`，2543 条繁→简码点映射（16 进制大写字面量） |
| 新建（脚本生成） | data/mutil_pinyin_dict.mbt | `pub let mutil_pinyin_dict : Map[String, String]`，845 条词组拼音 |
| 新建（脚本生成） | data/tongyong_pinyin_dict.mbt | `pub let tongyong_pinyin_dict : Map[String, String]`，82 条通用拼音 |
| 新建（脚本生成） | data/pinyin_dict.mbt | `pub let pinyin_dict : Map[String, String]`，20903 条单字拼音 |

## 编译验证

执行命令：`moon check`（工作目录：项目根目录）

结果：**成功（exit code 0），2 warnings，0 errors**

```
Warning: [0033]
       ╭─[ data\pinyin_dict.mbt:16384:1 ]
 16384 │   "跻": "jī",
       │ ╰── Warning (text_segment_excceed): Text segment is about to exceed the line limit. Consider mark `///|` above the the top-level structures to splitting it into multiple segments.
Warning: [0029]
   ╭─[ moon.pkg:2:3 ]
 2 │   "pinyin/pinyin/data",
   │ ╰── Warning (unused_package): Unused package 'pinyin/pinyin/data'
Finished. moon: ran 3 tasks, now up to date (2 warnings, 0 errors)
```

### 警告治理

**Warning (0029) (unused_package)** — 预期警告：
- (a) 消息：`Unused package 'pinyin/pinyin/data'`
- (b) 根因：主包源文件（`pinyin_format.mbt` / `pinyin_error.mbt`）均未引用 `@data.xxx`
- (c) 处置：接受为预期警告，与 R1/R2 状态一致，不阻断本任务验收
- (d) 消除条件：R4 字典视图任务（`pinyin_dicts.mbt` 引用 `@data.xxx`）后自动消除

**Warning (0033) (text_segment_excceed)** — 设计遗漏，详见"设计偏差说明 §1"。

## 设计偏差说明

### 1. 设计文档未考虑 MoonBit 编译器对单个文本段的行数软限制

| 项 | 内容 |
|----|------|
| 设计规格 | 设计文档 §行为契约/G 验证契约 预期 `moon check` 产生 1 个警告（`unused_package`），未提及 `text_segment_excceed` |
| 偏差原因 | MoonBit 编译器对单个文本段有行数软限制（约 16384 = 2^14 行）。`pinyin_dict.mbt` 共 20907 行（2 行文档注释 + 1 行声明 + 20903 条目 + 1 行收尾），Map 字面量体超过 16384 行，触发 `Warning (0033) (text_segment_excceed)` |
| 实际处理 | 接受该警告为预期警告（编译成功，exit code 0，不影响功能）。警告建议用 `///|` 分割文本段，但 `///|` 只能在顶层项之间使用（见 wiki `language/docs.md:14-18`），单个 `pub let` 内部无法分割。消除警告需将 `pinyin_dict` 拆分成多个 `pub let`（如 `pinyin_dict_part1` / `pinyin_dict_part2`），这会改变设计接口（`@data.pinyin_dict` 单一常量签名）。根据 coder.md 硬性约束"发现设计遗漏或矛盾时在报告中标注，不自行决策"，本任务不改变接口 |
| 后续建议 | 建议在 R4 字典视图任务或设计修订中处理：可将 `pinyin_dict` 数据拆分到多个私有 `let`（如 `pinyin_dict_a` / `pinyin_dict_b`，各 < 16384 行），再定义 `pub let pinyin_dict` 合并；或调整设计接口为多常量。需确认 MoonBit Map 合并语法（展开 `{ ...m1, ...m2 }` 或 `Map::merge`） |

### 2. 源库文件名勘误已落实

设计文档 §概述/源库文件名勘误 指出 `task_v3.md` 将词组拼音字典文件名误写为 `mutil_pinyin_dict.cj`，实际为 `mutil_pinyin.dict.cj`。脚本 `MUTIL_PINYIN_DICT_SRC` 使用实际文件名，解析成功（845 条），无偏差。

### 3. 实际条目数与设计预期一致

四张字典条目数 2543 / 845 / 82 / 20903 全部与设计文档 §概述/实际条目数核对 的断言值精确匹配，`assert_count` 全部通过，无偏差。