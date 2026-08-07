# 任务指令（v4）

## 动作
RETRY

## 任务描述
修正 R3 字典数据子包字面量生成的重复 key 去重缺陷：

1. **修改 `scripts/gen_pinyin_dict.py`**：
   - 在 `parse_chinese_dict` / `parse_string_dict` / `parse_pinyin_dict` 返回后，按 key 去重，**保留末次 value**（与 MoonBit Map 字面量语义及源库 Cangjie HashMap 构造语义一致）
   - 去重时打印被丢弃的重复 key 审计日志（key + 保留 value + 丢弃 value），便于追溯
   - 更新 `EXPECTED_COUNTS` 为去重后条目数：`chinese_dict: 2533`、`mutil_pinyin_dict: 843`（`tongyong_pinyin_dict: 82`、`pinyin_dict: 20903` 不变）
   - 断言时序调整：先去重，再断言去重后条目数（断言的是最终写入 .mbt 的条目数，须与运行时 `Map.length()` 一致）

2. **重新运行脚本生成 4 个 .mbt 文件**：`python scripts/gen_pinyin_dict.py`（工作目录：项目根目录）

3. **同步更新测试文件断言**：
   - `chinese_dict_test.mbt`：用例名 `chinese_dict_has_2543_entries` → `chinese_dict_has_2533_entries`，`content="2543"` → `content="2533"`，文档注释同步
   - `mutil_pinyin_dict_test.mbt`：用例名 `mutil_pinyin_dict_has_845_entries` → `mutil_pinyin_dict_has_843_entries`，`content="845"` → `content="843"`，文档注释同步
   - 其余测试文件（`tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt`）不变

4. **验证**：`moon check`（预期 exit code 0，2 warnings：`unused_package` + `text_segment_excceed`，均预期/不阻断）+ `moon test`（预期 26 tests, passed 26, failed 0）

预期修改文件路径：`scripts/gen_pinyin_dict.py`、`data/chinese_dict.mbt`、`data/mutil_pinyin_dict.mbt`、`data/tongyong_pinyin_dict.mbt`、`data/pinyin_dict.mbt`、`chinese_dict_test.mbt`、`mutil_pinyin_dict_test.mbt`

## 选择理由
R3 v3 失败于重复 key 去重缺陷（`chinese_dict` 实际 2533≠预期 2543，`mutil_pinyin_dict` 实际 843≠预期 845）。源库 `chinese.dict.cj` / `mutil_pinyin.dict.cj` 含重复 key（10 / 2 组），生成脚本原样写入导致 MoonBit Map 字面量静默去重，运行时条目数丢失。源库 Cangjie `HashMap([...])` 与 MoonBit Map 字面量对重复 key 均取末次 value，**去重保留末次是语义保真的正确处置**，非放宽断言。本任务为 R3 首次 RETRY，修正生成脚本 + 测试断言后重验。

## 任务上下文
- **失败报告**：`verify_v3.md` — FAILED，24 passed / 2 failed
- **失败根因详析**：`test_v3.md` §moon test 实际结果/失败用例原因分析 与 §建议处置（供编码 agent 后续修复）
- **实现报告**：`code_v3.md` — 脚本与产物已生成，`assert_count` 通过但漏检 Map 字面量去重
- **设计文档**：`detail_v3.md` §D 完整性断言契约 — "严格相等，不使用约等于容差"，授权"由编码 agent 核对源库后修正预期值（而非放宽断言）"
- **去重语义依据**：MoonBit Map 字面量对重复 key 取末次 value（运行时验证）；源库 Cangjie `HashMap([...])` 构造同样对重复 key 去重取末次；去重保留末次 = 源库语义保真
- **text_segment_excceed 警告**：`pinyin_dict.mbt` 超 16384 行软限制，exit code 0 不阻断验收；消除需拆分 `pinyin_dict` 为多常量（设计变更，改变 `@data.pinyin_dict` 单一常量接口），**本任务不强制处理**，留待 R4 字典视图任务或设计修订评估

## 已有代码上下文
- **R1 产出**：`moon.mod` / `moon.pkg` / `data/moon.pkg` / `README.mbt.md`（本任务不修改）
- **R2 产出**：`pinyin_format.mbt` / `pinyin_error.mbt` / `pinyin_format_test.mbt` / `pinyin_error_test.mbt`（本任务不修改）
- **R3 v3 产出（待修正）**：
  - `scripts/gen_pinyin_dict.py`（182 行）— `parse_*` 按行正则匹配收集所有条目（含重复），`write_*` 按 key 排序后原样写入（保留重复 key 行），`EXPECTED_COUNTS` = {chinese: 2543, mutil: 845, tongyong: 82, pinyin: 20903}，`assert_count` 在去重前执行
  - `data/chinese_dict.mbt`（2547 行 = 2 文档 + 1 声明 + 2543 条目 + 1 收尾）— 含 10 组重复 key 行
  - `data/mutil_pinyin_dict.mbt`（849 行 = 2 文档 + 1 声明 + 845 条目 + 1 收尾）— 含 2 组重复 key 行
  - `data/tongyong_pinyin_dict.mbt`（85 行）— 无重复 key，不变
  - `data/pinyin_dict.mbt`（20907 行）— 无重复 key，不变
  - `chinese_dict_test.mbt`（5 用例）— `chinese_dict_has_2543_entries` 断言 content="2543"（待改为 2533）
  - `mutil_pinyin_dict_test.mbt`（4 用例）— `mutil_pinyin_dict_has_845_entries` 断言 content="845"（待改为 843）
  - `tongyong_pinyin_dict_test.mbt`（4 用例）/ `pinyin_dict_test.mbt`（5 用例）— 不变
- **当前 `moon check`**：exit code 0，2 warnings（unused_package + text_segment_excceed），0 errors
- **当前 `moon test`**：26 tests, passed 24, failed 2

## RETRY 说明
**失败原因**：R3 v3 生成脚本 `parse_*` 按行正则匹配收集所有条目（含重复 key），`write_*` 原样写入 .mbt 文件（保留重复 key 行），MoonBit Map 字面量构造时对重复 key 静默去重（取末次 value），导致运行时 `Map.length()` < 写入条目数。`chinese_dict` 写入 2543 行 → 运行时 2533（去重 10 条）；`mutil_pinyin_dict` 写入 845 行 → 运行时 843（去重 2 条）。测试断言 2543/845 与运行时实际 2533/843 不符，2 用例失败。

**修正方向**：
1. 生成脚本在解析后按 key 去重，保留末次 value（与 MoonBit Map 字面量及源库 Cangjie HashMap 语义一致），打印去重审计日志
2. `EXPECTED_COUNTS` 更新为去重后条目数（2533 / 843 / 82 / 20903），断言的是最终写入 .mbt 的条目数（= 运行时 `Map.length()`）
3. 重新生成 4 个 .mbt 文件
4. 测试文件断言同步更新（2543→2533, 845→843）
5. `moon check` + `moon test` 全通过

**不放宽断言**：去重后条目数 2533/843 是源库语义保真的正确值（源库 HashMap 同样去重），非容差放宽。设计文档 §D 授权"核对源库后修正预期值"。