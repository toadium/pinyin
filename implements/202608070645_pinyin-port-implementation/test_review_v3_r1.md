# 测试审查报告（v3 r1）

## 审查结果
REJECTED

## 发现

- **[严重]** `implements/202608070645_pinyin-port-implementation/test_v3.md` — 测试报告文件缺失。任务指定该路径为测试报告交付物，但文件不存在。测试 agent 实际编写了 4 个测试文件（`chinese_dict_test.mbt` / `mutil_pinyin_dict_test.mbt` / `tongyong_pinyin_dict_test.mbt` / `pinyin_dict_test.mbt`，均位于项目根目录主包，2026/8/7 8:40 创建），但未生成测试报告记录设计依据、覆盖维度、验证结果。实际运行 `moon test` 显示 2 个测试失败（`chinese_dict_has_2543_entries` 实际 2533≠预期 2543；`mutil_pinyin_dict_has_845_entries` 实际 843≠预期 845），无任何报告记录此结果。此外，`detail_v3.md` §行为契约/G 验证契约/不执行的验证 明确声明"本任务无测试文件，数据子包纯数据无公开行为 API；测试在后续算法实现任务中编写"，§行为契约/F 与已有代码的交互契约 声明"测试文件：不受影响（本任务不修改、不引用）"，测试 agent 编写测试文件属设计偏差，无报告说明偏差原因与后续处置。

- **[一般]** `chinese_dict_test.mbt:37-45` — 用例 `chinese_dict_values_are_valid_codepoints` 注释与代码不一致。注释声称"抽样验证首条目 0x4E1F→0x4E22 与末条目均落在 BMP 区间（<= 0xFFFF）"，但代码仅检查首条目 0x4E1F 的 value <= 0x10FFFF（Unicode 最大码点 0x10FFFF，非 BMP 限制 0xFFFF），且未验证任何末条目。注释提及的"末条目"验证完全缺失，BMP 区间断言被替换为更宽松的 Unicode 码点有效性检查。

## 修改要求（仅 REJECTED 时）

1. **test_v3.md（新建）**：测试 agent 须生成测试报告，至少包含以下内容：
   - 文件变更清单（4 个 `_test.mbt` 文件）
   - 测试用例说明（每个用例名、覆盖维度、对应行为契约条目）
   - 设计依据说明（说明为何在"设计文档声明无测试"的情况下仍编写测试，属何种设计偏差）
   - `moon check` 实际输出（2 warnings：`unused_package` + `text_segment_excceed`，须说明测试文件引用 `@data` 后 `unused_package` 警告未消除的原因——test 块引用不计入包使用）
   - `moon test` 实际结果（26 tests, passed 24, failed 2），明确记录 2 个失败用例及其原因分析（实际条目数 2533/843 与预期 2543/845 不符，疑似 Map 字面量重复 key 去重导致数据丢失，须追溯至 `gen_pinyin_dict.py` 解析逻辑或源库数据重复）
   - 与实现报告 `code_v3.md` 的偏差说明（`code_v3.md` 声称"四张字典条目数 2543 / 845 / 82 / 20903 全部精确匹配，assert_count 全部通过"，但 `moon test` 证明 chinese_dict 与 mutil_pinyin_dict 实际条目数不符，实现报告声明与产物不一致）

2. **chinese_dict_test.mbt:37-45**：修正注释与代码的不一致。两种方向任选其一：
   - 方向 A（代码向注释对齐）：若意图验证 BMP 区间，将断言改为 `assert_true(v <= 0xFFFF)`，并补充末条目验证（需确认 chinese_dict 按 Int key 升序排序后的末条目 key 与 value）。
   - 方向 B（注释向代码对齐）：若意图验证 Unicode 码点有效性，修正注释为"抽样验证首条目 0x4E1F 的 value 为有效 Unicode 码点（<= 0x10FFFF）"，删除"末条目"与"BMP 区间"的表述。