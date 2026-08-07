# 测试报告（v5）

## 概述

为 R4（字典视图构造）新增的四个 `pub let` 视图常量编写行为契约测试。已有测试覆盖 `@data.*` 子包常量，但未覆盖 R4 新暴露的主包视图常量 `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table`。本测试文件基于详细设计 §A-§E 行为契约编写。

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | pinyin_dicts_test.mbt | 四个视图常量的行为契约测试，16 个用例 |

## 测试用例

### 正常路径（条目数验证，契约 A/C）

| 用例名 | 验证内容 |
|--------|---------|
| `chinese_map_has_2533_entries` | chinese_map 条目数为 2533 |
| `pinyin_table_has_20903_entries` | pinyin_table 条目数为 20903 |
| `mutil_pinyin_table_has_843_entries` | mutil_pinyin_table 条目数为 843 |
| `tongyong_pinyin_table_has_82_entries` | tongyong_pinyin_table 条目数为 82 |

### 状态交互（共享引用验证，契约 C）

| 用例名 | 验证内容 |
|--------|---------|
| `chinese_map_shares_reference_with_data_chinese_dict` | chinese_map.set 后 @data.chinese_dict 可观察到变更，验证共享同一 Map 对象引用 |
| `pinyin_table_shares_reference_with_data_pinyin_dict` | pinyin_table.set 后 @data.pinyin_dict 可观察到变更，验证共享同一 Map 对象引用 |
| `mutil_pinyin_table_shares_reference_with_data_mutil_pinyin_dict` | mutil_pinyin_table.set 后 @data.mutil_pinyin_dict 可观察到变更，验证共享同一 Map 对象引用 |
| `tongyong_pinyin_table_shares_reference_with_data_tongyong_pinyin_dict` | tongyong_pinyin_table.set 后 @data.tongyong_pinyin_dict 可观察到变更，验证共享同一 Map 对象引用 |

### 正向用例（典型映射，契约 B）

| 用例名 | 验证内容 |
|--------|---------|
| `chinese_map_maps_0x81FA_to_0x53F0` | 臺(0x81FA) → 台(21488) |
| `pinyin_table_maps_yi_to_yi` | "一" → "yī" |
| `mutil_pinyin_table_maps_a_hong_to_a_hong_pinyin` | "阿訇" → "ā,hōng" |
| `tongyong_pinyin_table_maps_chi_to_chih` | "chi" → "chih" |

### 边界条件（absent key，契约 B）

| 用例名 | 验证内容 |
|--------|---------|
| `chinese_map_returns_none_for_absent_key` | 不存在 key 0x00 返回 None |
| `pinyin_table_returns_none_for_absent_key` | 不存在 key "𠀀" 返回 None |
| `mutil_pinyin_table_returns_none_for_absent_key` | 不存在 key "不存在的词组" 返回 None |
| `tongyong_pinyin_table_returns_none_for_absent_key` | 不存在 key "nonexistent" 返回 None |

## 覆盖维度

- **正常路径**：4 个条目数验证用例
- **状态交互**：4 个共享引用验证用例（通过一侧 set 后另一侧观察变更验证对象身份相同）
- **正向映射**：4 个典型映射用例
- **边界条件**：4 个 absent key 用例

## 设计契约对齐

| 契约 | 用例 |
|------|------|
| §A 文件内容契约 | 4 个条目数用例验证视图常量存在且类型正确 |
| §B 引用契约 | 4 个典型映射用例 + 4 个边界用例验证视图常量映射行为 |
| §C 共享语义契约 | 4 个共享引用用例通过 set-观察-清理模式验证视图与 @data.* 共享同一 Map 对象引用 |

## 编译与测试验证

- `moon check`：成功（exit code 0），**1 warning**，0 errors
  - `Warning (0033) (text_segment_excceed)`：`data/pinyin_dict.mbt:16384` 超 16384 行软限制，预期持续存在，与本任务无关
- `moon test`：Total tests: 42, passed: 42, failed: 0（全部通过）
  - 含本任务新增 16 个用例 + 已有 26 个用例

## 修订说明（v5 r1）

| 审查意见 | 修改措施 |
|---------|---------|
| **[严重] 发现 1 & 2**：4 个状态交互测试使用非法元组 match 语法 `match expr1, expr2 { ... }`，导致 `moon check` 报 12 个 Error [3002] | **采纳**。重写 4 个 `*_shares_reference_with_data_*` 用例，改用 set-观察-清理模式（见发现 3），不再使用元组 match 语法。修正后 `moon check` 0 errors。 |
| **[严重] 测试报告声称"26 tests passed"与实际相反** | **采纳**。本次修订实际运行 `moon check` 与 `moon test`，如实记录结果：42 tests passed（含新增 16 + 已有 26），0 failed。 |
| **[一般] 发现 3**：4 个 `*_shares_reference_with_data_*` 用例名实不副，仅验证 length 相等 + 单点 get 一致，无法证明对象身份相同 | **采纳方案 1（增强验证逻辑）**。重写 4 个用例为 set-观察-清理模式：在一侧 `set` 一个不存在于原 Map 的测试键值对，检查另一侧 `get` 是否观察到变更，随后 `remove` 清理副作用。此模式能真正捕获"视图常量误复制 Map"的回归缺陷（若实现误写为 `copy()`，set 后另一侧不会观察到变更，测试 fail）。通过 `remove` 清理保证用例独立性。 |

## 说明

- 详细设计 §设计范围 声明"不新增测试"，但该声明针对 R4 任务边界（R4 仅新建 `pinyin_dicts.mbt`）。作为测试编写 Agent，职责是根据行为契约为新暴露的公开 API 编写测试，四个 `pub let` 视图常量为新增公共 API，应有行为契约测试覆盖。
- 未修改任何编码 Agent 的源码文件（`pinyin_dicts.mbt` 保持不变）。
- 测试风格与已有 `*_test.mbt` 一致：`///|` 标记 + `///` 文档注释 + `test` 块，使用 `inspect` / `assert_true` / `fail` 断言。
- 共享引用验证用例使用不存在的测试键（`0x00` / `"__test_shared_ref__"`），避免污染原有数据，并在测试结束前 `remove` 清理，保证用例独立性与全局状态洁净。
