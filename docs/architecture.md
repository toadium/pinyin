# 架构设计

## 包依赖关系

```
core（零依赖）    data（零依赖）
  ↑                  ↑
convert（core+data）
  ↑
┌───┴───┬──────────┬──────────┐
reverse segment  fuzzy    disambiguate
(core+data) (core) (core+reverse) (core+convert)
    ↑         ↑         ↑
  search（core+convert+segment+fuzzy）
  normalize（core+segment+fuzzy）
  tone（core）

lm（core+data+math）
  ↑
input（core+segment+reverse+lm+math）
```

线性无环依赖，core 和 data 零依赖，各子包职责单一。lm 和 input 形成独立链条，不引入循环。参照 owl-mbt 项目的扁平多根包布局理念。

## 根包（pinyin）

文档入口包，不导入任何子包（如 owl-mbt 的做法）。仅含 `pinyin.mbt`，提供模块级别的文档说明。用户直接导入所需子包。

## core 包（零依赖）

核心类型与工具，无外部依赖。

| 文件 | 职责 |
|------|------|
| `pinyin_format.mbt` | PinyinFormat 输出格式枚举（4 变体） |
| `pinyin_error.mbt` | PinyinError suberror + `raise_invalid_input` 包装函数 |
| `fuzzy_rule.mbt` | FuzzyRule 模糊匹配规则枚举 |
| `tone_conversion.mbt` | 声调转换内部逻辑 |
| `pinyin_trie.mbt` | PinyinTrie 数据结构 + ~420 拼音音节 + strip_tone/strip_tone_number |

### PinyinError 跨包设计

`pub(all) suberror PinyinError { InvalidInput(String) }` 自动提升为 `Error`。由于 MoonBit [0073] 跨包 bug（`raise @core.PinyinError::InvalidInput("msg")` 触发误报），提供 `pub fn raise_invalid_input(msg : String) -> Unit raise PinyinError` 包装函数。子包用 `@core.raise_invalid_input("msg")` 代替直接 raise，catch 块用 `_` 匹配所有错误。

## data 包（零依赖）

纯数据包，零依赖。包含 4 张字典：

| 字典 | 类型 | 条目数 | 说明 |
|------|------|--------|------|
| `chinese_dict` | Map[Int, Int] | 2533 | 繁→简码点映射 |
| `pinyin_dict` | Map[String, String] | 20903 | 单字拼音（分 11 段 merge） |
| `mutil_pinyin_dict` | Map[String, String] | 843 | 词组拼音 |
| `tongyong_pinyin_dict` | Map[String, String] | 82 | 通用拼音 |

### pinyin_dict 分段设计

`pinyin_dict.mbt`（20962 行）分 11 段（seg0..seg10）后 `.merge()` 合并，规避单段文本过长警告。

## convert 包（依赖 core + data）

核心转换引擎，包含拼音转换和繁简转换的所有公开接口。

| 文件 | 职责 |
|------|------|
| `pinyin_dicts.mbt` | 字典视图常量（与 data 包共享引用） |
| `chinese_helper.mbt` | ChineseHelper 命名空间（繁简转换 + 汉字判断） |
| `pinyin_helper.mbt` | PinyinHelper 命名空间（拼音转换主入口） |
| `pinyin_stream_processor.mbt` | PinyinStreamProcessor 流式处理器（逐字符输入实时输出） |

### 字典视图共享

`pinyin_dicts.mbt` 中的 `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table` 与 data 包的 `chinese_dict` 等共享同一 Map 对象引用（非拷贝），`add_*_dict_resource` 的自定义追加对两者均可见。

## reverse 包（依赖 core + data）

拼音→汉字反向查找。支持无调/带调/数字调三种查询方式。

## segment 包（依赖 core）

连续拼音串分词，基于 Trie + 动态规划，处理歧义切分。

## fuzzy 包（依赖 core + reverse）

拼音模糊匹配，支持 9 组双向规则：zh↔z, ch↔c, sh↔s, n↔l, f↔h, in↔ing, en↔eng, an↔ang, ong↔eng。

## disambiguate 包（依赖 core + convert）

多音字上下文消歧，基于 Viterbi + bigram 词频模型。

## search 包（依赖 core + convert + segment + fuzzy）

拼音搜索索引，倒排索引结构，支持首字母/连续拼音/模糊拼音搜索。

## tone 包（依赖 core）

声调变调规则引擎，支持 5 类变调：三声变调、一变调、不变调、七变调、八变调。

## normalize 包（依赖 core + segment + fuzzy）

拼音规范化 + 编辑距离。大小写/ü/v/声调格式统一，音节级 Levenshtein + 模糊距离。

## lm 包（依赖 core + data + moonbitlang/core/math）

N-gram 语言模型，从 data 包字典自动构建 unigram/bigram/trigram 频率表，提供概率查询与困惑度评估。

| 文件 | 职责 |
|------|------|
| `pinyin_lm.mbt` | PinyinLM 命名空间 + LMStats 结构体 + Laplace 平滑 + Katz 回退 |

### 平滑策略

- **Laplace 平滑**：P(w) = (C(w) + 1) / (N + V)，避免零概率
- **Katz 回退**：高阶 n-gram 频率不足时回退到低阶，trigram→bigram→unigram 逐级降级

## input 包（依赖 core + segment + reverse + lm + moonbitlang/core/math）

拼音输入法引擎，基于 Beam Search 解码 + LM 评分，将连续拼音串转换为汉字候选列表。

| 文件 | 职责 |
|------|------|
| `pinyin_input.mbt` | PinyinInputEngine 结构体 + InputCandidate 结构体 + Beam Search |

### 算法流程

1. **分词**：segment 包对拼音串执行最优切分
2. **反查**：reverse 包将各音节映射为候选汉字集合
3. **Beam Search**：逐音节扩展候选路径，LM 评分剪枝，保留 top-B 条路径
4. **排序**：按 LM 对数概率降序排列，去重输出

时间复杂度 O(S×B×C)，其中 S=音节数、B=beam 宽度、C=单音节最大候选数。

## examples 包（依赖 convert）

示例包，4 个示例文件共 14 个示例测试：
- `chinese_helper_example.mbt`（2）
- `pinyin_helper_example.mbt`（5）
- `pinyin_array_example.mbt`（4）
- `custom_dict_example.mbt`（3）

## 多后端

- `supported_targets = "+wasm+wasm-gc+js+native"`
- 四后端各 169 测试全通过，共 676 测试
- 严格模式 `--warn-list +73 --deny-warn` 零警告零错误
- 无 WASM local count 问题（字典用 Map 字面量，非大 match）