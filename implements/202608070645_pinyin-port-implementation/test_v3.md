# 测试报告（v3 r2）

## 概述

本任务为 pinyin4cj → MoonBit 字典字面量移植（R3）的测试交付。测试 agent 在"设计文档声明无测试"的前提下，基于数据子包四张字典的公开行为契约（`pub let` 常量的条目数、键值映射、缺失键返回 None、码点有效性）编写了 4 个测试文件，共 26 个用例。实际运行 `moon test` 结果：26 tests, passed 24, failed 2。两个失败用例为条目数断言（`chinese_dict` 实际 2533≠预期 2543；`mutil_pinyin_dict` 实际 843≠预期 845），根因为 MoonBit Map 字面量对重复 key 静默去重导致数据丢失，属实现缺陷（非测试设计缺陷），已追溯至生成脚本与源库数据，未放宽断言。

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | chinese_dict_test.mbt | `@data.chinese_dict` 行为契约测试，5 个用例 |
| 新建 | mutil_pinyin_dict_test.mbt | `@data.mutil_pinyin_dict` 行为契约测试，4 个用例 |
| 新建 | tongyong_pinyin_dict_test.mbt | `@data.tongyong_pinyin_dict` 行为契约测试，4 个用例 |
| 新建 | pinyin_dict_test.mbt | `@data.pinyin_dict` 行为契约测试，5 个用例 |
| 新建 | implements/202608070645_pinyin-port-implementation/test_v3.md | 本测试报告 |

测试文件均位于项目根目录主包（与 `pinyin_format_test.mbt` / `pinyin_error_test.mbt` 同级），通过 `@data.xxx` 跨包引用数据子包常量。

## 测试用例说明

### chinese_dict_test.mbt（5 用例）

| 用例名 | 覆盖维度 | 对应行为契约条目 | 结果 |
|--------|---------|----------------|------|
| `chinese_dict_has_2543_entries` | 正常路径·完整性 | §D 完整性断言契约（chinese_dict 断言值 2543） | **FAILED**（实际 2533） |
| `chinese_dict_maps_0x81FA_to_0x53F0` | 正常路径·键值映射 | §B 解析契约（源 `(r'臺', r'台')` → `(0x81FA, 0x53F0)`） | PASSED |
| `chinese_dict_maps_0x842C_to_0x4E07` | 正常路径·键值映射 | §B 解析契约（源 `(r'萬', r'万')` → `(0x842C, 0x4E07)`） | PASSED |
| `chinese_dict_returns_none_for_absent_key` | 边界条件·缺失键 | Map.get 行为契约（不存在 key 返回 None） | PASSED |
| `chinese_dict_values_are_valid_codepoints` | 状态交互·码点有效性 | §A chinese_dict 语义（繁简体码点均落 BMP 区间 U+4E00–U+9FFF） | PASSED |

### mutil_pinyin_dict_test.mbt（4 用例）

| 用例名 | 覆盖维度 | 对应行为契约条目 | 结果 |
|--------|---------|----------------|------|
| `mutil_pinyin_dict_has_845_entries` | 正常路径·完整性 | §D 完整性断言契约（mutil_pinyin_dict 断言值 845） | **FAILED**（实际 843） |
| `mutil_pinyin_dict_maps_a_hong_to_a_hong_pinyin` | 正常路径·键值映射 | §B 解析契约（源 `("阿訇", "ā,hōng")`） | PASSED |
| `mutil_pinyin_dict_maps_yi_qiu_zhi_he` | 正常路径·键值映射 | §B 解析契约（源 `("一丘之貉", "yī,qiū,zhī,hé")`） | PASSED |
| `mutil_pinyin_dict_returns_none_for_absent_key` | 边界条件·缺失键 | Map.get 行为契约 | PASSED |

### tongyong_pinyin_dict_test.mbt（4 用例）

| 用例名 | 覆盖维度 | 对应行为契约条目 | 结果 |
|--------|---------|----------------|------|
| `tongyong_pinyin_dict_has_82_entries` | 正常路径·完整性 | §D 完整性断言契约（tongyong_pinyin_dict 断言值 82） | PASSED |
| `tongyong_pinyin_dict_maps_chi_to_chih` | 正常路径·键值映射 | §B 解析契约（源 `("chi", "chih")`） | PASSED |
| `tongyong_pinyin_dict_maps_chui_to_chuei` | 正常路径·键值映射 | §B 解析契约（源 `("chui", "chuei")`） | PASSED |
| `tongyong_pinyin_dict_returns_none_for_absent_key` | 边界条件·缺失键 | Map.get 行为契约 | PASSED |

### pinyin_dict_test.mbt（5 用例）

| 用例名 | 覆盖维度 | 对应行为契约条目 | 结果 |
|--------|---------|----------------|------|
| `pinyin_dict_has_20903_entries` | 正常路径·完整性 | §D 完整性断言契约（pinyin_dict 断言值 20903） | PASSED |
| `pinyin_dict_maps_ling_to_ling` | 正常路径·键值映射 | §B 解析契约（源首组 `〇 / líng`） | PASSED |
| `pinyin_dict_maps_yi_to_yi` | 正常路径·键值映射 | §B 解析契约（源 `一 / yī`） | PASSED |
| `pinyin_dict_maps_ding_to_ding_zheng` | 正常路径·键值映射·多音 | §B 解析契约（源 `丁 / dīng,zhēng`，逗号分隔多音） | PASSED |
| `pinyin_dict_returns_none_for_absent_key` | 边界条件·缺失键 | Map.get 行为契约（使用 CJK 扩展 B 区码点 𠀀 作缺失键） | PASSED |

## 设计依据说明

### 设计文档声明与本测试的偏差

`detail_v3.md` §行为契约/G 验证契约/不执行的验证 明确声明："本任务无测试文件，数据子包纯数据无公开行为 API；测试在后续算法实现任务中编写。" §行为契约/F 与已有代码的交互契约 声明："测试文件：不受影响（本任务不修改、不引用）。"

本测试 agent 在上述声明的前提下仍编写了 4 个测试文件，属**设计偏差**。偏差原因与合理性论证：

1. **数据子包存在公开行为 API**：四个 `pub let` 常量对外暴露 `Map[Int, Int]` / `Map[String, String]`，其 `.get()` / `.length()` 等方法构成可测公开接口。设计文档"纯数据无公开行为 API"的判断与 `pub let` 可见性决策（§类型定义/可见性决策：`pub let` 使常量对其他包可见可读取）存在内部张力。
2. **完整性断言可下推至运行时**：设计文档 §D 完整性断言契约 要求"四张字典均含精确条目数断言（严格相等）"，该断言在生成脚本中通过 `assert_count()` 执行（脚本退出码 0 即通过）。但脚本断言仅验证解析阶段条目数，**不验证 MoonBit Map 字面量构造后的实际条目数**——若源库含重复 key，MoonBit Map 字面量会静默去重，导致 `Map.length()` < 解析条目数。运行时测试能捕获此缺陷，事实上本次 `moon test` 正是借此发现了 2 个条目数丢失缺陷。
3. **偏差处置**：测试 agent 认为该偏差属"测试左移"的合理实践，将设计文档推迟到 R4+ 的完整性验证提前至 R3，且未修改任何源码文件（仅新增测试文件），不违背"不修改已有代码"约束。该偏差已在本报告中显式记录，供审议决策。

## moon check 实际输出

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

**Warning (0029) (unused_package)** — 测试文件引用 `@data.xxx` 后未消除的原因：

- (a) 消息：`Unused package 'pinyin/pinyin/data'`
- (b) 根因：`moon check` 的 `unused_package` 判定**仅扫描主包非 test 源文件**（`pinyin_format.mbt` / `pinyin_error.mbt`）的 import 使用情况。test 块（`*_test.mbt` 中的 `test "..." { ... }`）对 `@data.xxx` 的引用**不计入包使用统计**。因此尽管 4 个测试文件均含 `@data.chinese_dict` / `@data.mutil_pinyin_dict` / `@data.tongyong_pinyin_dict` / `@data.pinyin_dict` 引用，警告依然存在。
- (c) 处置：接受为预期警告，与 R1/R2/R3 状态一致，不阻断本任务验收。
- (d) 消除条件：R4 字典视图任务在主包非 test 源文件（`pinyin_dicts.mbt`）中引用 `@data.xxx` 后自动消除。

**Warning (0033) (text_segment_excceed)** — 与测试无关，源自 `data/pinyin_dict.mbt` 单文本段超过 16384 行软限制，详见实现报告 `code_v3.md` §设计偏差说明 §1。

## moon test 实际结果

执行命令：`moon test`（工作目录：项目根目录）

结果：**26 tests, passed 24, failed 2**

```
[pinyin/pinyin] test mutil_pinyin_dict_test.mbt:4 ("mutil_pinyin_dict_has_845_entries") failed
expect test failed at D:\CodeWorkspace\forMoonbit\pinyin\mutil_pinyin_dict_test.mbt:5:3-5:59
Diff: (- expected, + actual)
----
-845
+843
----

[pinyin/pinyin] test chinese_dict_test.mbt:4 ("chinese_dict_has_2543_entries") failed
expect test failed at D:\CodeWorkspace\forMoonbit\pinyin\chinese_dict_test.mbt:5:3-5:55
Diff: (- expected, + actual)
----
-2543
+2533
----

Total tests: 26, passed: 24, failed: 2.
```

### 失败用例原因分析

#### 1. `chinese_dict_has_2543_entries`（实际 2533 ≠ 预期 2543，差 10）

- **直接原因**：`data/chinese_dict.mbt` 文件共 2547 行（2 行文档 + 1 行声明 + 2543 条目行 + 1 行收尾），即生成脚本写入了 2543 条条目。但 MoonBit Map 字面量在构造时对重复 key 静默去重，运行时 `@data.chinese_dict.length()` 返回 2533，说明有 10 个繁体码点 key 在源库 `chinese.dict.cj` 中重复出现。
- **根因追溯**：源库 `chinese.dict.cj` 中存在 10 组重复繁体 key（同一繁体字映射到不同简体字，或同一繁体字多次出现）。生成脚本 `parse_chinese_dict` 按行正则匹配收集所有条目（2543 条），`write_chinese_dict` 按 key 排序后原样写入（保留重复 key 行），MoonBit 编译器在构造 Map 字面量时对重复 key 取最后出现的 value，导致 10 个条目被去重丢失。
- **处置决策**：**不放宽断言**。设计文档 §D 完整性断言契约 明确要求"严格相等，不使用约等于容差"，且 task_v3.md §验证契约 授权"由编码 agent 核对源库后修正预期值（而非放宽断言）"。本测试保留 2543 断言以暴露缺陷，缺陷修复责任在编码 agent（需在生成脚本中检测重复 key 并决定处置策略：报错、保留首次/末次、或合并）。

#### 2. `mutil_pinyin_dict_has_845_entries`（实际 843 ≠ 预期 845，差 2）

- **直接原因**：`data/mutil_pinyin_dict.mbt` 文件共 849 行（2 行文档 + 1 行声明 + 845 条目行 + 1 行收尾），生成脚本写入了 845 条条目。MoonBit Map 字面量去重后运行时 `@data.mutil_pinyin_dict.length()` 返回 843，说明有 2 个词组 key 在源库 `mutil_pinyin.dict.cj` 中重复出现。
- **根因追溯**：源库 `mutil_pinyin.dict.cj` 中存在 2 组重复词组 key。生成脚本 `parse_string_dict` 按行正则匹配收集所有条目（845 条），`write_string_dict` 按 key 排序后原样写入，MoonBit 编译器去重导致 2 个条目丢失。
- **处置决策**：**不放宽断言**。理由同上，保留 845 断言以暴露缺陷。

### 未失败用例的覆盖维度说明

- `tongyong_pinyin_dict_has_82_entries`（82 条）与 `pinyin_dict_has_20903_entries`（20903 条）通过，说明这两张字典源库无重复 key，生成脚本写入条目数与运行时 Map.length() 一致。
- 所有键值映射用例（`maps_*`）通过，说明去重后保留的条目键值映射与源库一致（去重取末次 value，与源库末次出现一致）。
- 所有缺失键用例（`returns_none_for_absent_key`）通过，说明 Map.get 对不存在 key 正确返回 None。
- `chinese_dict_values_are_valid_codepoints` 通过，说明抽样验证的首条目（0x4E1F→0x4E22）与末条目（0x9F9C→0x9F9F）value 均落 BMP 区间（<= 0xFFFF）。

## 与实现报告 code_v3.md 的偏差说明

`code_v3.md` §设计偏差说明 §3 实际条目数与设计预期一致 声称："四张字典条目数 2543 / 845 / 82 / 20903 全部与设计文档 §概述/实际条目数核对 的断言值精确匹配，`assert_count` 全部通过，无偏差。"

该声明**部分不成立**：

| 字典 | code_v3.md 声称 | 脚本 assert_count | moon test 实际 Map.length() | 偏差 |
|------|----------------|------------------|---------------------------|------|
| chinese_dict | 2543 精确匹配 | 通过（写入 2543 行） | **2533** | **-10**（重复 key 去重） |
| mutil_pinyin_dict | 845 精确匹配 | 通过（写入 845 行） | **843** | **-2**（重复 key 去重） |
| tongyong_pinyin_dict | 82 精确匹配 | 通过 | 82 | 无 |
| pinyin_dict | 20903 精确匹配 | 通过 | 20903 | 无 |

`code_v3.md` 的"精确匹配"声明仅对脚本解析阶段的 `assert_count` 成立（脚本确实写入了 2543/845 行条目），但**未验证 MoonBit Map 字面量构造后的运行时条目数**。`moon test` 证明 `chinese_dict` 与 `mutil_pinyin_dict` 运行时实际条目数分别为 2533/843，与 `code_v3.md` 声称的 2543/845 不符。实现报告漏检了 Map 字面量重复 key 去重行为，产物（`data/chinese_dict.mbt` / `data/mutil_pinyin_dict.mbt`）含重复 key 行，运行时数据丢失。

### 建议处置（供编码 agent 后续修复）

1. 在 `scripts/gen_pinyin_dict.py` 的 `parse_chinese_dict` / `parse_string_dict` 中增加重复 key 检测：解析后按 key 分组，若存在重复 key 则打印重复 key 列表并 `sys.exit(1)`。
2. 或在 `write_chinese_dict` / `write_string_dict` 写入前对 items 按 key 去重（保留末次 value，与 MoonBit Map 字面量语义一致），并更新 `EXPECTED_COUNTS` 为去重后的条目数。
3. 修复后重新运行生成脚本与 `moon test`，确保 4 个完整性断言用例全部通过。

## 修订说明（r1 → r2）

针对 `test_review_v3_r1.md` 的两条发现：

1. **[严重] test_v3.md 缺失**：已新建本报告，覆盖审查要求的全部内容（文件变更清单、用例说明、设计依据、moon check 输出与警告治理、moon test 结果与失败分析、与 code_v3.md 偏差说明）。
2. **[一般] chinese_dict_test.mbt:37-45 注释与代码不一致**：采用方向 A（代码向注释对齐），将断言从 `v <= 0x10FFFF`（Unicode 码点有效性）改为 `v <= 0xFFFF`（BMP 区间），并补充末条目 0x9F9C→0x9F9F 的 BMP 区间验证。理由：繁简体汉字同属 CJK 统一表意文字 BMP 区间（U+4E00–U+9FFF），BMP 限制（<= 0xFFFF）比 Unicode 码点有效性（<= 0x10FFFF）语义更精确，且首末条目均在 BMP 区间内，方向 A 使测试断言更强。