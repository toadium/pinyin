# 测试审查报告（v5 r1）

## 审查结果
REJECTED

## 发现

- **[严重]** `pinyin_dicts_test.mbt:35-38, 47-50, 59-62, 71-74` — 4 个"状态交互"测试用例使用非法 MoonBit 语法，导致 `moon check` 报 12 个 Error [3002]，`moon test` 无法编译通过。测试报告 §概述声称"`moon test`：Total tests: 26, passed: 26, failed: 0（全部通过）"与实际结果完全相反，测试 Agent 未实际运行验证或伪造了结果。

- **[严重]** `pinyin_dicts_test.mbt:33-39` 等 4 处 — `match` 元组匹配语法错误。写法 `match expr1, expr2 { Some(v1), Some(v2) => ...; _, _ => ... }` 在 MoonBit 中非法。MoonBit `match` 只能匹配单个表达式，匹配元组必须写成 `match (expr1, expr2) { (Some(v1), Some(v2)) => ...; (_, _) => ... }`（已有测试文件 `chinese_dict_test.mbt` / `pinyin_dict_test.mbt` 均未使用元组 match，无先例支撑此写法）。编译器报错：`Parse error, unexpected token ',', you may expect '{'` 与 `you may expect '=>'`。

- **[一般]** `pinyin_dicts_test.mbt:33-39, 45-51, 57-63, 69-75` — 4 个 `*_shares_reference_with_data_*` 用例名实不副。用例名声称验证"shares_reference"（共享同一对象引用，对应设计 §C），但实际只验证 `length` 相等 + 单点 `get` 一致，这只能证明两 Map 内容一致，无法证明对象身份相同（不同 Map 实例可有相同 length 与相同抽样值）。即便语法修正，测试逻辑也不能验证契约 §C "共享同一 `Map[Int, Int]` 实例"的核心语义。应改为：通过一侧 `set` / `remove` 后另一侧可观察到变更来验证共享引用（需注意清理副作用），或直接断言 `chinese_map === @data.chinese_dict`（若 MoonBit 支持引用相等比较），或在测试注释中明确降级为"内容一致性"验证并修正用例名。

- **[轻微]** `test_v5.md:18` — 测试报告"文件变更清单"声明"16 个用例"，与 `pinyin_dicts_test.mbt` 中实际 16 个 test 块数量一致，但报告未提及编译失败，整份报告的可信度受损。

## 修改要求（仅 REJECTED 时）

### 严重问题 1 & 2：测试代码无法编译

- **位置**：`pinyin_dicts_test.mbt` 第 35-38 行（`chinese_map_shares_reference_with_data_chinese_dict`）、第 47-50 行（`pinyin_table_shares_reference_with_data_pinyin_dict`）、第 59-62 行（`mutil_pinyin_table_shares_reference_with_data_mutil_pinyin_dict`）、第 71-74 行（`tongyong_pinyin_table_shares_reference_with_data_tongyong_pinyin_dict`）。
- **问题**：`match expr1, expr2 { Some(v1), Some(v2) => ...; _, _ => ... }` 语法非法。MoonBit `match` 关键字后只能跟一个待匹配表达式，不能跟逗号分隔的两个表达式。编译器在第 35:32、47:30、59:37、71:41 等位置报 `Parse error, unexpected token ','`。
- **为什么是问题**：测试代码无法编译，`moon check` 退出码非 0，`moon test` 无法运行任何用例。测试报告声称"26 tests passed"是虚假结果。这是测试有效性的根本性缺陷——不存在的测试无法提供任何覆盖保障。
- **期望修正方向**：将元组 match 改为合法写法，用括号构成元组字面量：
  ```moonbit
  match (chinese_map.get(0x81FA), @data.chinese_dict.get(0x81FA)) {
    (Some(v1), Some(v2)) => assert_true(v1 == v2)
    (_, _) => fail("expected both maps to contain key 0x81FA")
  }
  ```
  其余 3 个用例同改。修正后必须实际运行 `moon check` 与 `moon test`，确认 0 errors、全部用例通过，并在测试报告中如实记录结果。

### 一般问题 3：共享语义测试名实不副

- **位置**：`pinyin_dicts_test.mbt` 第 33-39、45-51、57-63、69-75 行的 4 个 `*_shares_reference_with_data_*` 用例。
- **问题**：用例名声称验证"shares_reference"（共享引用），实际只验证 `length` 相等与单点 `get` 一致。内容一致 ≠ 引用相同。
- **为什么是问题**：设计 §C 共享语义契约明确要求"指向同一 `Map[Int, Int]` 实例"，这是 `pub let chinese_map = @data.chinese_dict` 的关键语义保证（后续 R5/R6/R7 算法依赖此共享语义避免数据重复）。当前测试即使语法修正后通过，也无法捕获"视图常量误复制了 Map"的回归缺陷——若实现误写为 `pub let chinese_map : Map[Int, Int] = @data.chinese_dict.copy()`，当前测试仍会通过。测试名误导读者认为已验证引用共享。
- **期望修正方向**：二选一：
  1. 增强验证逻辑：通过一侧修改观察另一侧变更（如 `chinese_map.set(0x00, 0x00)` 后检查 `@data.chinese_dict.get(0x00)` 是否为 `Some(0x00)`，随后 `remove` 清理），或使用 MoonBit 提供的引用相等比较（若有）。
  2. 降级用例名与注释：将用例名改为 `*_content_matches_data_*`，注释明确"仅验证内容一致，不验证引用共享"，并说明引用共享由实现层 `let` 绑定语义保证、无法在测试层强验证。