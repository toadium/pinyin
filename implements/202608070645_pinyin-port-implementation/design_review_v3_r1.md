# 设计审查报告（v3 r1）

## 审查结果
APPROVED

## 发现

### 已独立验证的事实性声称（全部通过）

- **[验证] 源库文件名勘误**：设计声称 `src/mutil_pinyin.dict.cj` 为实际文件名（task_v3.md 误写为 `mutil_pinyin_dict.cj`）。经 `ls src/` 实际确认，源库中确实为 `mutil_pinyin.dict.cj`，勘误正确。
- **[验证] 条目数核对**：设计声称四张字典实际条目数为 2543 / 845 / 82 / 20903（task_v3.md 预期 2556 / 856 / 83 / 20903 部分有误）。用 Python 实际解析源库核对，四张字典条目数分别为 2543 / 845 / 82 / 20903，与设计声称完全一致。设计阶段核对逻辑（文件总行数减去头尾非条目行）正确。
- **[验证] `pub let` 可见性语义**：设计引用 wiki `language/packages.md:79-80` 确认 `pub` modifier 使 toplevel `let` 对其他包可见。经查阅 wiki 原文确认，第 79-80 行明确陈述"默认所有函数定义和变量绑定对其他包不可见，可以使用 `pub` modifier 使 toplevel `let`/`fn` 公开"。可见性决策（`pub let` 而非 `pub(self) let`）正确，符合跨包 `@data` 引用场景。
- **[验证] Map 字面量语法**：设计引用 wiki `stdlib/builtin.md:115` 示例 `let m : Map[String, Int] = { "a": 1, "b": 2 }`。经查阅 wiki 确认示例存在。进一步创建临时 `.mbt` 文件实测 `pub let x : Map[Int, Int] = { 0x81FA: 0x53F0, }` 与 `pub let y : Map[String, String] = { "〇": "líng", }`，`moon check` 通过（0 errors），语法正确。
- **[验证] 正则表达式在实际数据下的正确性**：设计给出 `parse_chinese_dict` 正则 `r'\(r\'(.)\'\s*,\s*r\'(.)\'\)'` 与 `parse_string_dict` 正则 `r'\("(.+?)"\s*,\s*"(.+?)"\)'`。用 Python 实际解析源库，匹配条目数分别为 2543 / 845 / 82，与预期一致。额外检查源库数据中无 value 含 `"` 字符的条目（mutil 0 条、tongyong 0 条），无 `r'` 但不匹配的行（chinese 0 行），设计假设"拼音数据不含 `"`，无需转义"经验证成立。
- **[验证] 当前项目状态符合设计前置条件**：设计假设 R1/R2 产出存在且 `moon check` 通过（exit code 0，1 warning `unused_package`）。经实际运行 `moon check`，输出 exit code 0，1 warning `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`，0 errors，与设计假设一致。`data/` 目录及 `data/moon.pkg` 存在，`moon.pkg` 含 `import "pinyin/pinyin/data"`，均与设计描述一致。

### 轻微发现（不影响正确性，不阻断通过）

- **[轻微]** §行为契约/A 第 268 行描述"四个解析函数 + 两个输出函数 + 一个断言函数 + `main` 入口"，但 §类型定义/函数签名 实际列出三个解析函数（`parse_chinese_dict` / `parse_string_dict` / `parse_pinyin_dict`），`parse_string_dict` 复用于两个字典。此处"四个"应指"为四张字典解析"的概念表述，而非四个独立函数，但易误导。编码 agent 以 §类型定义/函数签名 为准即可，不影响实现。
- **[轻微]** §输出契约/C `write_string_dict` 契约中文件结构示例使用 `{文档注释说明}` 占位符，未明确该函数如何为三个不同字典（mutil/tongyong/pinyin）生成各自文档注释。函数签名 `write_string_dict(var_name, items, out_path)` 未含文档注释参数。但 §类型定义/MoonBit 数据常量签名 已给出三个字典各自的完整文档注释内容，编码 agent 有充分信息据此实现（可通过 `var_name` 分派或增加 `doc_comment` 参数），属实现细节未指定，不构成规格缺口。
- **[轻微]** §类型定义/解析逻辑规格 `parse_pinyin_dict` 描述"跳过空行（若有）"同时声称"长度 = 行数 / 2"，若存在空行则两表述矛盾。经实际验证源库 `pinyin.dict.txt` 41806 行全部非空（无非空行），"跳过空行"为 no-op，"长度 = 41806 / 2 = 20903"成立。表述属防御性描述，实际无影响。
- **[轻微]** 设计未明确讨论 `pinyin_dict` 的 key 唯一性假设。若源库 `pinyin.dict.txt` 中同一汉字出现多组，`Map[String, String]` 字面量将产生重复 key。经实际解析 20903 组条目数与 41806/2 精确匹配，且拼音字典惯例保证 key 唯一，风险可忽略。即便存在重复，`moon check` 会报错（有验证机制兜底）。

## 修改要求（不适用）