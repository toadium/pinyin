# 代码审查报告（v4 r1）

## 审查结果
APPROVED

## 发现
- **[轻微]** scripts/gen_pinyin_dict.py — `dedup_by_key` docstring 称"保持原列表中首次出现的 key 顺序"，设计 §去重逻辑规格称"保持原列表中末次出现的相对顺序"，两者措辞不一致。脚本实现返回 `list(seen.items())` 即 dict 插入顺序（首次出现顺序），脚本 docstring 准确，设计描述有误。因后续 `write_*` 按 key 排序，不影响输出确定性，不影响正确性。
- **[轻微]** scripts/gen_pinyin_dict.py — 设计 §去重逻辑规格要求"无重复 key 时：直接返回原列表（不打印审计日志），零开销"，脚本实现总是构造 dict 并返回新列表，无重复 key 时有轻微构造开销。功能等价，不影响正确性。
- **[轻微]** detail_v4.md — 设计 §去重逻辑规格 `format_repr` 示例 "33266 → 33266 (0x81FA)" 为文档笔误（33266 的十六进制为 0x81F2，非 0x81FA），脚本实现 `f"{v} (0x{v:X})"` 正确，不影响正确性。

## 验证证据
- `moon check`：exit code 0，2 warnings（unused_package / text_segment_excceed，均预期），0 errors
- `moon test`：Total tests: 26, passed: 26, failed: 0
- 数据文件条目数与重复 key 验证：
  - chinese_dict.mbt：2533 条，无重复 key（源库 2543 条含 10 组重复，去重 10 条）
  - mutil_pinyin_dict.mbt：843 条，无重复 key（源库 845 条含 2 组重复，去重 2 条）
  - tongyong_pinyin_dict.mbt：82 条，无重复 key（源库 82 条无重复）
  - pinyin_dict.mbt：20903 条，无重复 key（源库 20903 条无重复）
- 文件行数验证：2538 / 848 / 86 / 20907，均符合设计 §D 输出契约
- `dedup_by_key` 行为验证：保留末次 value，多次重复 key 逐次打印覆盖日志，无重复 key 时不打印日志
- `format_repr` 行为验证：Int 输出 `十进制 (0x十六进制)`，str 输出 `repr()` 形式
- 测试文件断言验证：`chinese_dict_has_2533_entries` / `mutil_pinyin_dict_has_843_entries`，`content="2533"` / `content="843"`，文档注释含"源库"前缀与"含 N 组重复 key"说明