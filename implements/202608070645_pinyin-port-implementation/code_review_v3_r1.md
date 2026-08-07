# 代码审查报告（v3 r1）

## 审查结果
APPROVED

## 发现

- **[轻微]** scripts/gen_pinyin_dict.py — `write_string_dict` 签名增加 `doc_lines: list[str]` 参数，偏离设计 §类型定义/函数签名（设计签名为 `def write_string_dict(var_name: str, items: list[tuple[str, str]], out_path: str) -> None:`）。这是合理扩展：设计 §C 输出契约 文件结构 `/// {文档注释说明}` 暗示文档注释需参数化，设计签名不够完整。实现更准确，不影响正确性。

- **[轻微]** scripts/gen_pinyin_dict.py — `parse_pinyin_dict` 空行处理逻辑与设计 §类型定义/解析逻辑规格 "跳过空行（若有）" 的意图不完全一致。实现使用 `if key == "" and value == "":` 仅跳过两个连续空行组成的组，而非跳过任何含空行的组。实际运行结果 20903 条精确匹配（源文件 `pinyin.dict.txt` 41806 行全部为有效内容，无空行），证明当前行为正确，但若源文件格式未来引入空行分隔符可能产生错误条目。不影响当前正确性。

- **[轻微]** data/pinyin_dict.mbt — `moon check` 产生 `Warning (0033) (text_segment_excceed)`，设计 §G 验证契约 未提及（设计预期仅 1 个 `unused_package` 警告）。根因：MoonBit 编译器对单个文本段有约 16384 行软限制，`pinyin_dict.mbt` 共 20907 行（Map 字面量体 20903 条）超过限制。实现报告已记录为设计偏差，按 coder.md 硬性约束"不自行决策"保留单一 `pub let pinyin_dict` 接口，并给出后续建议（R4 拆分为多个私有 `let` 合并）。不影响功能（exit code 0，编译成功）。

## 验证证据

- `moon check`：exit code 0，2 warnings（`text_segment_excceed` + `unused_package`），0 errors，与实现报告一致
- 脚本重跑：4 张字典条目数 2543 / 845 / 82 / 20903 全部精确匹配 `EXPECTED_COUNTS`
- 确定性输出：二次重跑 SHA-256 哈希不变（`85e6831b0f0da5b9` / `92c663807c316b3f` / `b32c67209b5fdc2c` / `f1eb1e0fa3e4d48b`）
- 源库文件行数核对：`chinese.dict.cj` 2556 行 / `mutil_pinyin.dict.cj` 858 行 / `tongyong_pinyin_dict.cj` 92 行 / `pinyin.dict.txt` 41806 行，全部与设计 §概述 一致
- 源库格式核对：四张字典首尾条目与正则匹配模式一致，`pinyin.dict.txt` 使用 CRLF 换行，脚本 `rstrip("\n").rstrip("\r")` 正确处理
- 生成文件结构核对：4 个 `.mbt` 文件均含 2 行文档注释 + 1 行 `pub let` 声明 + 条目行 + 1 行 `}` 收尾，条目数与行数关系正确（chinese 2547=2+1+2543+1，mutil 849=2+1+845+1，tongyong 86=2+1+82+1，pinyin 20907=2+1+20903+1）
- 排序核对：`chinese_dict.mbt` 首条 `0x4E1F` 按 Int key 升序；`pinyin_dict.mbt` 首条 `"〇"`（U+3007）按 String key 字典序，符合设计 §C 输出契约
- 可见性核对：4 个常量均使用 `pub let`（非 `pub(self) let`），符合设计 §类型定义/MoonBit 数据常量签名 §可见性决策
- 编码核对：脚本所有 `open()` 显式指定 `encoding="utf-8"`，符合设计 §A 内容契约
- 源库文件名勘误核对：`MUTIL_PINYIN_DICT_SRC` 使用实际文件名 `mutil_pinyin.dict.cj`，符合设计 §概述/源库文件名勘误