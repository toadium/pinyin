# 测试审查报告（v4 r1）

## 审查结果
APPROVED

## 发现

- **[轻微]** `chinese_dict_test.mbt:39-50` — 用例 `chinese_dict_values_are_valid_codepoints` 注释提及"抽样验证首条目 0x4E1F→0x4E22 与末条目 0x9F9C→0x9F9F"，但代码仅断言 `v <= 0xFFFF`（BMP 区间），未用 `inspect` 验证具体映射值 0x4E22 / 0x9F9F。注释主要意图（BMP 区间验证）与代码一致，且首末条目 key 确为数据文件首末行（已核对 `data/chinese_dict.mbt:5` 与 `:2537`），不影响测试有效性。若补充 `inspect(v, content="...")` 验证具体映射值可使断言更强。此条沿用 v3 r2 已记录的轻微发现，v4 未修复，不阻断通过。

- **[轻微]** `implements/202608070645_pinyin-port-implementation/test_v4.md` — 该文件不存在。v4 为 v3 的首次 RETRY，仅修改 2 个测试文件断言值（2543→2533 / 845→843），未单独编写 v4 测试报告；测试验证结果（`moon test` 26/26 通过）记录于 `code_v4.md` §编译验证。测试代码本身（4 个 `*_test.mbt` 文件）完整可审，文档缺失不影响测试有效性判断。

## 审查依据说明

### 验证执行

- `moon check`：成功（exit code 0），2 warnings（`unused_package` / `text_segment_excceed`，均预期，与 v3 状态一致），0 errors
- `moon test`：Total tests: 26, passed: 26, failed: 0

### 设计契约对齐核对（§F 测试文件断言更新契约）

| 契约项 | 期望 | 实际 | 核对 |
|--------|------|------|------|
| `chinese_dict_test.mbt` 用例名 | `chinese_dict_has_2533_entries` | line 4 一致 | ✓ |
| `chinese_dict_test.mbt` 断言 | `content="2533"` | line 5 一致 | ✓ |
| `chinese_dict_test.mbt` 文档注释 | 含"源库条目第 13-2555 行共 2543 条（含 10 组重复 key），去重后 2533 条" | line 2-3 一致 | ✓ |
| `mutil_pinyin_dict_test.mbt` 用例名 | `mutil_pinyin_dict_has_843_entries` | line 4 一致 | ✓ |
| `mutil_pinyin_dict_test.mbt` 断言 | `content="843"` | line 5 一致 | ✓ |
| `mutil_pinyin_dict_test.mbt` 文档注释 | 含"源库条目第 13-857 行共 845 条（含 2 组重复 key），去重后 843 条" | line 2-3 一致 | ✓ |
| `tongyong_pinyin_dict_test.mbt` | 不变 | 断言 82，用例 4 个不变 | ✓ |
| `pinyin_dict_test.mbt` | 不变 | 断言 20903，用例 5 个不变 | ✓ |

### 数据产物与断言一致性核对

| 字典 | 数据文件总行数 | 行数构成 | 条目数 | 测试断言 | 运行时 `Map.length()` | 一致 |
|------|--------------|---------|--------|---------|---------------------|------|
| `chinese_dict` | 2538 | 3 文档 + 1 声明 + 2533 条目 + 1 收尾 | 2533 | 2533 | 2533 | ✓ |
| `mutil_pinyin_dict` | 848 | 3 文档 + 1 声明 + 843 条目 + 1 收尾 | 843 | 843 | 843 | ✓ |
| `tongyong_pinyin_dict` | 85 | 2 文档 + 1 声明 + 82 条目 + 1 收尾 | 82 | 82 | 82 | ✓ |
| `pinyin_dict` | 20906 | 2 文档 + 1 声明 + 20903 条目 + 1 收尾 | 20903 | 20903 | 20903 | ✓ |

### 测试覆盖维度评估

| 维度 | chinese | mutil | tongyong | pinyin | 评估 |
|------|---------|-------|----------|--------|------|
| 完整性（条目数） | 1 | 1 | 1 | 1 | 4 张字典均覆盖 ✓ |
| 键值映射（正常路径） | 2 | 2 | 2 | 3 | 含单音/多音/带调元音/纯 ASCII 各类样本 ✓ |
| 缺失键返回 None（边界） | 1 | 1 | 1 | 1 | 4 张字典均覆盖，缺失键选取合理（0x00 / 中文词组 / "nonexistent" / CJK 扩展 B 区 U+20000）✓ |
| 码点有效性（状态交互） | 1（抽样首末 BMP） | — | — | — | 仅 chinese 抽样验证，覆盖较薄但属轻微，不影响通过 |

### v4 核心变更（去重语义）的测试覆盖评估

v4 核心变更为生成脚本增加 `dedup_by_key` 去重逻辑（保留末次 value）。测试通过以下间接方式验证去重正确性：
1. **条目数断言**：去重后 2533/843 与运行时 `Map.length()` 一致，证明去重后条目数正确
2. **键值映射断言**：`maps_*` 用例验证具体 key→value 映射，若去重保留错误 value，映射断言会失败
3. **去重逻辑的直接单元测试**：属生成脚本（Python）测试范畴，非 MoonBit 运行时测试职责

去重语义的运行时验证充分性属**轻微**覆盖评估，不构成驳回理由：去重后条目数与键值映射均经运行时验证，且 `moon test` 全通过。

### 注释与代码一致性核对

- `chinese_dict_test.mbt:9-10` 注释 `(r'臺', r'台')` → 代码 `0x81FA` (ord('臺')) / `content="21488"` (0x53F0=ord('台')) 一致 ✓
- `chinese_dict_test.mbt:19-20` 注释 `(r'萬', r'万')` → 代码 `0x842C` (ord('萬')) / `content="19975"` (0x4E07=ord('万')) 一致 ✓
- `mutil_pinyin_dict_test.mbt:9-10` 注释 `("阿訇", "ā,hōng")` → 代码一致 ✓
- `mutil_pinyin_dict_test.mbt:19-20` 注释 `("一丘之貉", "yī,qiū,zhī,hé")` → 代码一致 ✓
- `tongyong_pinyin_dict_test.mbt:2-3` 注释"92 行，去 9 行头 + 1 行收尾共 82 条" → 92-9-1=82 算术正确 ✓
- `pinyin_dict_test.mbt:2-3` 注释"41806 行 / 2 = 20903 组" → 算术正确 ✓