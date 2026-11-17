<div align="center">
<h1>pinyin</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.6.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/tests-900-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/packages-12-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/moon-0.1.20260713-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/targets-wasm%2Bwasm--gc%2Bjs%2Bnative-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/license-MIT-brightgreen" style="display: inline-block;" />
</p>

## 介绍

pinyin 是一个自研的 MoonBit 拼音引擎，提供汉字→拼音、拼音→汉字、繁简转换、多音字消歧、拼音分词、模糊匹配、搜索索引、声调变调、编辑距离、规范化、N-gram 语言模型、拼音输入法引擎等全栈拼音能力。

### 适用场景

- 拼音输入法引擎核心（Beam Search + N-gram LM 评分）
- 中文文本搜索与索引（拼音首字母/连续/模糊搜索）
- 多音字上下文消歧（Viterbi + bigram 动态规划）
- 拼音教学与声调变调规则处理
- 拼音规范化与拼写纠错（编辑距离 + 模糊匹配）
- 中文 NLP 前处理（繁简转换 + 拼音标注）
- WASM/Web 端中文处理（四后端支持，零 IO 依赖）

### 不适用场景

- 不提供中文分词（专注于拼音层面处理）
- 不提供语音合成/语音识别
- 不支持方言拼音（仅支持普通话汉语拼音）
- N-gram 语言模型基于内置字典训练，不支持外部语料训练

### 特性

- 🚀 支持词、句转换成拼音
- 🧠 支持多音字上下文消歧（Viterbi + bigram 词频模型）
- 🔍 支持拼音→汉字反向查找（无调/带调/数字调）
- 📑 支持拼音搜索索引（首字母/连续拼音/模糊拼音搜索）
- ✂️ 支持连续拼音串分词（Trie + 动态规划，处理歧义切分）
- 🌫️ 支持拼音模糊匹配（zh↔z, ch↔c, sh↔s, n↔l, f↔h, in↔ing, en↔eng, an↔ang, ong↔eng）
- 🎵 支持声调变调规则（三声变调/一变调/不变调/七变调/八变调）
- 📏 支持拼音编辑距离（音节级 Levenshtein + 模糊距离）
- 🔧 支持拼音规范化（大小写/ü/v/声调格式统一）
- 🌊 支持拼音流式处理（PinyinStreamProcessor，逐字符输入实时输出）
- 📊 支持 N-gram 语言模型（Unigram/Bigram/Trigram 频率表、Laplace 平滑、Katz 回退、Interpolation 平滑、困惑度）
- ⌨️ 支持拼音输入法引擎（Beam Search + LM 评分、全切分候选、用户词库、模糊输入、可配置 beam 宽度）
- 🔤 支持声母/韵母提取（get_initial/get_final/initials_list）
- 💪 支持常用简体/繁体中文字符转换成拼音
- 🛠️ 支持常见多音字符转换成拼音
- 🌍 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 💪 支持常用简体、繁体中文字符互转
- 🚀 支持添加自定义字典
- 🛠️ 支持常用简体/繁体中文字符转换成通用拼音
- ✅ 四后端（wasm / wasm-gc / js / native）全通过，严格 `--warn-list +73 --deny-warn` 零警告

### 算法复杂度

| 模块 | 核心算法 | 时间复杂度 | 说明 |
|------|----------|-----------|------|
| `core` | PinyinTrie 查询 | O(L) | L = 拼音串长度 |
| `segment` | Trie + DP 分词 | O(n²×L) | n = 串长，L = 最长音节 |
| `fuzzy` | BFS 模糊扩展 | O(V+E) | V = 音节数，E = 规则边数 |
| `disambiguate` | Viterbi 动态规划 | O(n×k²) | n = 字数，k = 每字候选音节数 |
| `input` | Beam Search 解码 | O(S×B×C) | S = 音节数，B = beam 宽度，C = 每音节候选数 |
| `normalize` | Levenshtein 编辑距离 | O(m×n) | m,n = 音节序列长度 |
| `lm` | N-gram 概率查表 | O(1) | 频率表直接查表 |

### mooncakes 生态对比

mooncakes.io 31909 个包中仅有 2 个拼音库，本项目是功能最完整的拼音引擎：

| 能力 | pinyin (本项目) | pinyin-toolkit |
|------|:---:|:---:|
| 汉字→拼音 | ✅ | ✅ |
| 拼音→汉字反向查找 | ✅ | ❌ |
| 拼音分词（Trie+DP） | ✅ | ❌ |
| 多音字消歧（Viterbi+bigram） | ✅ | ❌ |
| 声调变调规则 | ✅ | ❌ |
| N-gram 语言模型 | ✅ | ❌ |
| 拼音输入法引擎（Beam Search） | ✅ | ❌ |

## 软件架构

### 包结构（12 包扁平多根布局）

```
pinyin/                             # 根包 — 文档入口（不导入任何子包）
├── pinyin.mbt                      # 根包文档入口
├── core/                           # 核心类型 + 声调转换 + Trie + 声母韵母（零依赖）
│   ├── pinyin_format.mbt           # PinyinFormat 枚举
│   ├── pinyin_error.mbt            # PinyinError suberror + raise_invalid_input
│   ├── fuzzy_rule.mbt              # FuzzyRule 枚举
│   ├── tone_conversion.mbt         # 声调转换函数
│   ├── pinyin_trie.mbt             # PinyinTrie + pinyin_syllables + strip_tone
│   ├── pinyin_initials_finals.mbt  # get_initial/get_final/initials_list
│   ├── pinyin_core_wbtest.mbt      # 白盒测试（5）
│   ├── pinyin_trie_wbtest.mbt      # 白盒测试（9）
│   └── pinyin_initials_finals_wbtest.mbt # 白盒测试（7）
├── data/                           # 字典数据包（零依赖）
│   ├── chinese_dict.mbt            # 繁→简映射（2533 条）
│   ├── pinyin_dict.mbt             # 单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt       # 词组拼音（843 条）
│   └── tongyong_pinyin_dict.mbt    # 通用拼音（82 条）
├── convert/                        # 核心转换引擎（依赖 core + data）
│   ├── pinyin_dicts.mbt            # 字典视图常量
│   ├── chinese_helper.mbt          # ChineseHelper 命名空间
│   ├── pinyin_helper.mbt           # PinyinHelper 命名空间
│   ├── pinyin_stream_processor.mbt # PinyinStreamProcessor 流式处理器
│   ├── convert_wbtest.mbt          # 白盒测试（8）
│   ├── convert_test.mbt            # 黑盒测试（19）
│   ├── convert_dict_test.mbt       # 黑盒测试（5）
│   └── stream_processor_test.mbt   # 黑盒测试（7）
├── reverse/                        # 拼音→汉字反向查找（依赖 core + data）
│   ├── pinyin_reverse.mbt
│   └── reverse_test.mbt            # 黑盒测试（10）
├── segment/                        # 拼音分词（依赖 core）
│   ├── pinyin_segmenter.mbt
│   └── segment_test.mbt            # 黑盒测试（12）
├── fuzzy/                          # 模糊匹配（依赖 core + reverse）
│   ├── pinyin_fuzzy.mbt
│   └── fuzzy_test.mbt              # 黑盒测试（19）
├── disambiguate/                   # 多音字消歧（依赖 core + convert）
│   ├── pinyin_disambiguator.mbt
│   └── disambiguate_test.mbt       # 黑盒测试（7）
├── search/                         # 搜索索引（依赖 core + convert + segment + fuzzy）
│   ├── pinyin_search.mbt
│   └── search_test.mbt             # 黑盒测试（7）
├── tone/                           # 声调变调（依赖 core）
│   ├── pinyin_tone_sandhi.mbt
│   └── tone_test.mbt               # 黑盒测试（12）
├── normalize/                      # 规范化 + 编辑距离（依赖 core + segment + fuzzy）
│   ├── pinyin_normalizer.mbt
│   ├── pinyin_edit_distance.mbt
│   ├── normalizer_test.mbt         # 黑盒测试（10）
│   └── edit_distance_test.mbt      # 黑盒测试（7）
├── lm/                             # N-gram 语言模型（依赖 core + data + math）
│   ├── pinyin_lm.mbt               # PinyinLM + LMStats + Laplace 平滑 + Katz 回退 + Interpolation
│   └── lm_test.mbt                 # 黑盒测试（12）
├── input/                          # 拼音输入法引擎（依赖 core + segment + reverse + lm + math + data + fuzzy）
│   ├── pinyin_input.mbt            # PinyinInputEngine + InputCandidate + Beam Search + 用户词库 + 模糊输入
│   └── input_test.mbt              # 黑盒测试（14）
├── examples/                       # 示例包（12 子包全覆盖，37 个示例测试）
│   ├── chinese_helper_example.mbt  # 示例测试（2）
│   ├── pinyin_helper_example.mbt   # 示例测试（5）
│   ├── pinyin_array_example.mbt    # 示例测试（4）
│   ├── custom_dict_example.mbt     # 示例测试（3）
│   ├── initials_finals_example.mbt # 示例测试（2）
│   ├── reverse_example.mbt         # 示例测试（2）
│   ├── segment_example.mbt         # 示例测试（2）
│   ├── fuzzy_example.mbt           # 示例测试（2）
│   ├── disambiguate_example.mbt    # 示例测试（1）
│   ├── search_example.mbt          # 示例测试（2）
│   ├── tone_example.mbt            # 示例测试（1）
│   ├── normalize_example.mbt       # 示例测试（2）
│   ├── lm_example.mbt              # 示例测试（5）
│   └── input_example.mbt           # 示例测试（4）
├── docs/                           # 开发文档
│   ├── roadmap.md
│   ├── architecture.md
│   ├── api.md
│   └── testing.md
├── scripts/
│   └── gen_pinyin_dict.py          # 字典生成脚本
├── moon.mod                        # 模块元数据
├── moon.pkg                        # 根包依赖声明（不导入子包）
├── CHANGELOG.md
├── README.md
├── README.mbt.md                   # mooncakes 发布文档
└── LICENSE                         # MIT 协议
```

### 依赖拓扑

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
    ↑
lm（core+data+math）
  ↑
input（core+segment+reverse+lm+math+data+fuzzy）
```

线性无环依赖，core 和 data 零依赖，各子包职责单一。

### 接口说明

| 包 | 类 / 类型 | 方法 / 变体 | 说明 |
| --- | --- | --- | --- |
| `core` | `PinyinFormat` | `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter` | 输出格式枚举 |
| `core` | `FuzzyRule` | `Prefix` / `Suffix` | 模糊匹配规则枚举 |
| `core` | `PinyinError` | `InvalidInput(String)` | 统一错误类型（`pub(all) suberror`） |
| `core` | `PinyinTrie` | `new` / `insert` / `contains` / `prefix_lengths` | Trie 数据结构 |
| `core` | `PinyinInitialsFinals` | `get_initial` / `get_final` / `initials_list` | 声母/韵母提取 |
| `convert` | `PinyinHelper` | `convert_to_pinyin_string` | 词句转拼音字符串 |
| `convert` | `PinyinHelper` | `convert_to_pinyin_string_traditional` | 繁体词句转拼音 |
| `convert` | `PinyinHelper` | `convert_to_pinyin_array` | 单字转拼音数组 |
| `convert` | `PinyinHelper` | `get_short_pinyin` | 首字母格式拼音 |
| `convert` | `PinyinHelper` | `has_multi_pinyin` | 多音字检测 |
| `convert` | `PinyinHelper` | `to_tongyong_pinyin_string_array` | 通用拼音数组 |
| `convert` | `PinyinHelper` | `add_pinyin_dict_resource` | 添加自定义拼音字典 |
| `convert` | `PinyinHelper` | `add_mutil_pinyin_dict_resource` | 添加自定义词组字典 |
| `convert` | `ChineseHelper` | `convert_to_simplified_chinese` | 繁体转简体 |
| `convert` | `ChineseHelper` | `convert_to_traditional_chinese` | 简体转繁体 |
| `convert` | `ChineseHelper` | `is_chinese` | 汉字判断 |
| `convert` | `ChineseHelper` | `is_traditional_chinese` | 繁体汉字判断 |
| `convert` | `ChineseHelper` | `contains_chinese` | 包含汉字判断 |
| `convert` | `ChineseHelper` | `add_chinese_dict_resource` | 添加自定义中文字典 |
| `convert` | `PinyinStreamProcessor` | `new` / `feed` / `flush` / `reset` | 流式拼音处理器（逐字符输入实时输出） |
| `reverse` | `ReversePinyinHelper` | `reverse_lookup` | 拼音→汉字反向查找（无调） |
| `reverse` | `ReversePinyinHelper` | `reverse_lookup_tone_mark` | 拼音→汉字反向查找（带调） |
| `reverse` | `ReversePinyinHelper` | `reverse_lookup_tone_number` | 拼音→汉字反向查找（数字调） |
| `reverse` | `ReversePinyinHelper` | `is_valid_pinyin` | 合法拼音音节判断 |
| `segment` | `PinyinSegmenter` | `segment` | 连续拼音串全切分 |
| `segment` | `PinyinSegmenter` | `segment_best` | 连续拼音串最优切分 |
| `segment` | `PinyinSegmenter` | `can_segment` | 判断是否可完全切分 |
| `fuzzy` | `FuzzyPinyinHelper` | `fuzzy_expand` | 拼音模糊扩展 |
| `fuzzy` | `FuzzyPinyinHelper` | `fuzzy_match` | 两个拼音是否模糊等价 |
| `fuzzy` | `FuzzyPinyinHelper` | `fuzzy_reverse_lookup` | 模糊拼音→汉字反向查找 |
| `disambiguate` | `PinyinDisambiguator` | `disambiguate` | 多音字上下文消歧 |
| `search` | `PinyinSearchIndex` | `new` / `add_document` / `search_initial` / `search_pinyin` / `search_fuzzy` | 拼音搜索索引 |
| `tone` | `ToneSandhiHelper` | `apply_tone_sandhi` | 声调变调规则 |
| `normalize` | `PinyinEditDistance` | `distance` / `fuzzy_distance` | 拼音编辑距离 |
| `normalize` | `PinyinNormalizer` | `normalize` / `normalize_to_tone_number` / `normalize_to_without_tone` | 拼音规范化 |
| `lm` | `PinyinLM` | `unigram_prob` | Unigram 概率（Laplace 平滑） |
| `lm` | `PinyinLM` | `bigram_prob` | Bigram 概率（Laplace 平滑 + 回退） |
| `lm` | `PinyinLM` | `trigram_prob` | Trigram 概率（Katz 回退） |
| `lm` | `PinyinLM` | `sentence_log_prob` | 整句对数概率（Bigram） |
| `lm` | `PinyinLM` | `sentence_log_prob_trigram` | 整句对数概率（Trigram） |
| `lm` | `PinyinLM` | `perplexity` | 困惑度（Bigram） |
| `lm` | `PinyinLM` | `perplexity_trigram` | 困惑度（Trigram） |
| `lm` | `PinyinLM` | `interpolation_prob` | Interpolation 平滑概率（λ₁trigram+λ₂bigram+λ₃unigram） |
| `lm` | `PinyinLM` | `sentence_log_prob_interpolation` | 整句对数概率（Interpolation） |
| `lm` | `PinyinLM` | `perplexity_interpolation` | 困惑度（Interpolation） |
| `lm` | `PinyinLM` | `stats` | 语言模型统计信息 |
| `lm` | `LMStats` | `vocab_size` / `unigram_total` / `bigram_total` / `trigram_total` / `unigram_types` / `bigram_types` / `trigram_types` | 统计信息结构体 |
| `input` | `PinyinInputEngine` | `new` / `with_beam_width` / `set_beam_width` / `beam_width` | 输入法引擎创建与配置 |
| `input` | `PinyinInputEngine` | `input` | 拼音串→汉字候选（最优切分） |
| `input` | `PinyinInputEngine` | `input_all_segments` | 拼音串→汉字候选（全切分路径） |
| `input` | `PinyinInputEngine` | `input_from_segments` | 从预分词音节生成候选 |
| `input` | `PinyinInputEngine` | `input_with_limit` | 限制返回候选数量 |
| `input` | `PinyinInputEngine` | `input_fuzzy` | 模糊拼音输入（自动扩展模糊音节） |
| `input` | `PinyinInputEngine` | `add_user_dict` | 添加用户自定义词库 |
| `input` | `PinyinInputEngine` | `build_phrase_table` | 构建词组优先查找表 |
| `input` | `InputCandidate` | `text` / `score` / `segments` | 候选结果（文本+对数概率+音节切分） |

## 使用说明

### 安装

```bash
moon add walkzzz/pinyin@0.6.0
```

### 编译构建

```bash
moon check --target all --warn-list +73 --deny-warn   # 四后端严格编译检查
moon test  --target all --warn-list +73 --deny-warn   # 四后端测试
moon fmt    --check                                    # 格式检查
moon info   --target all                              # 生成接口文件
```

### 功能示例

> 各子包通过 `@包名.` 限定访问，如 `@convert.PinyinHelper`、`@reverse.ReversePinyinHelper`。

#### 繁体转简体

```moonbit
let result = @convert.ChineseHelper::convert_to_simplified_chinese("臺，喪，麗")
println(result)
// 输出: 台，丧，丽
```

#### 简体转繁体

```moonbit
let result = @convert.ChineseHelper::convert_to_traditional_chinese("我是中国人")
println(result)
// 输出: 我是中國人
```

#### 词、句转换成拼音

```moonbit
let result = @convert.PinyinHelper::convert_to_pinyin_string("我是中国人", " ")
println(result)
// 输出: wǒ shì zhōng zhòng guó rén
```

#### 自定义输出格式

```moonbit
let result = @convert.PinyinHelper::convert_to_pinyin_string("中国", " ", format=WithToneNumber)
println(result)
// 输出: zhong1 zhong4 guo2
```

#### 添加自定义拼音字典

```moonbit
let map : Map[String, String] = { "上": "shǎng" }
@convert.PinyinHelper::add_pinyin_dict_resource(map)
let result = @convert.PinyinHelper::convert_to_pinyin_string("上午", " ")
println(result)
// 输出: shǎng wǔ
```

#### 添加自定义拼音组合字典

```moonbit
let map : Map[String, String] = { "阿弥陀佛": "ā,mí,tuó,fó" }
@convert.PinyinHelper::add_mutil_pinyin_dict_resource(map)
let result = @convert.PinyinHelper::convert_to_pinyin_string("阿弥陀佛", " ")
println(result)
// 输出: ā mí tuó fó
```

#### 添加自定义中文字典

```moonbit
let map : Map[Int, Int] = { 0x7691: 0x75C7 }  // 癥 → 症
@convert.ChineseHelper::add_chinese_dict_resource(map)
let result = @convert.ChineseHelper::convert_to_simplified_chinese("癥")
println(result)
// 输出: 症
```

#### 多音字转拼音集合

```moonbit
let result = @convert.PinyinHelper::convert_to_pinyin_array('长')
println(result)
// 输出: ["cháng", "zhǎng"]
```

#### 繁简体转拼音

```moonbit
let result = @convert.PinyinHelper::convert_to_pinyin_array('嚴')
println(result)
// 输出: ["yán"]
```

#### 繁简体转通用拼音

```moonbit
let simple = @convert.PinyinHelper::to_tongyong_pinyin_string_array('傳')
let traditional = @convert.PinyinHelper::to_tongyong_pinyin_string_array('传')
println(simple)
println(traditional)
// 输出: ["chuan2", "jhuan4"]
//       ["chuan2", "jhuan4"]
```

#### 拼音→汉字反向查找

```moonbit
let chars = @reverse.ReversePinyinHelper::reverse_lookup("zhong")
println(chars)
// 输出: ["中", "重", "种", ...]

let chars2 = @reverse.ReversePinyinHelper::reverse_lookup_tone_mark("zhōng")
println(chars2)
// 输出: ["中", ...]

let chars3 = @reverse.ReversePinyinHelper::reverse_lookup_tone_number("zhong1")
println(chars3)
// 输出: ["中", ...]
```

#### 拼音分词

```moonbit
let segments = @segment.PinyinSegmenter::segment("nihao")
println(segments)
// 输出: [["ni", "hao"]]

let segments2 = @segment.PinyinSegmenter::segment("xian")
println(segments2)
// 输出: [["xi", "an"], ["xian"]]

let best = @segment.PinyinSegmenter::segment_best("xian")
println(best)
// 输出: ["xian"]
```

#### 模糊匹配

```moonbit
let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("zhong")
println(variants)
// 输出: ["zhong", "zong"]

let match = @fuzzy.FuzzyPinyinHelper::fuzzy_match("zhong", "zong")
println(match)
// 输出: true

let chars = @fuzzy.FuzzyPinyinHelper::fuzzy_reverse_lookup("zhong")
println(chars)
// 输出: ["中", "重", "种", ..., "总", "宗", ...]
```

#### 多音字消歧

```moonbit
let result = @disambiguate.PinyinDisambiguator::disambiguate("中国")
println(result)
// 输出: ["zhong1", "guo2"]

let result2 = @disambiguate.PinyinDisambiguator::disambiguate("重要")
println(result2)
// 输出: ["zhong4", "yao4"]
```

#### 拼音搜索索引

```moonbit
let index = @search.PinyinSearchIndex::new()
index.add_document(1, "中国")
index.add_document(2, "中华")
let results = index.search_initial("zhg")
println(results)
// 输出: [1, 2]

let results2 = index.search_pinyin("zhongguo")
println(results2)
// 输出: [1]
```

#### 声调变调

```moonbit
let result = @tone.ToneSandhiHelper::apply_tone_sandhi(["ni3", "hao3"])
println(result)
// 输出: ["ni2", "hao3"]  // 三声变调：ni3→ni2

let result2 = @tone.ToneSandhiHelper::apply_tone_sandhi(["yi1", "ge4"])
println(result2)
// 输出: ["yi2", "ge4"]  // 一变调：yi1→yi2
```

#### 拼音流式处理

```moonbit
let processor = @convert.PinyinStreamProcessor::new()
let delta1 = processor.feed('你')
println(delta1)
// 输出: nǐ

let delta2 = processor.feed('好')
println(delta2)
// 输出: hǎo

processor.reset()
```

#### 拼音编辑距离

```moonbit
let dist = @normalize.PinyinEditDistance::distance(["zhong", "guo"], ["zhong", "ren"])
println(dist)
// 输出: 1

let fuzzy_dist = @normalize.PinyinEditDistance::fuzzy_distance(["zhong"], ["zong"])
println(fuzzy_dist)
// 输出: 0  // zh↔z 模糊等价
```

#### 拼音规范化

```moonbit
let result = @normalize.PinyinNormalizer::normalize("ZHONG1")
println(result)
// 输出: "zhōng"  // 大写转小写 + 数字调→带调标记

let result2 = @normalize.PinyinNormalizer::normalize("lv3")
println(result2)
// 输出: "lǚ"  // v→ü + 数字调→带调标记

let result3 = @normalize.PinyinNormalizer::normalize_to_without_tone("zhōng")
println(result3)
// 输出: "zhong"  // 去除声调标记
```

#### 声母/韵母提取

```moonbit
let initial = @core.PinyinInitialsFinals::get_initial("zhong")
println(initial)
// 输出: "zh"

let final = @core.PinyinInitialsFinals::get_final("zhong")
println(final)
// 输出: "ong"

let initials = @core.PinyinInitialsFinals::initials_list()
println(initials.length())
// 输出: 22  // 22 个声母
```

#### N-gram 语言模型

```moonbit
let p = @lm.PinyinLM::unigram_prob("zhong")
println(p)
// 输出: 0.012...  // Unigram 概率（Laplace 平滑）

let p2 = @lm.PinyinLM::bigram_prob("zhong", "guo")
println(p2)
// 输出: 0.085...  // Bigram 条件概率

let p3 = @lm.PinyinLM::trigram_prob("zhong", "guo", "ren")
println(p3)
// 输出: 0.032...  // Trigram 条件概率（Katz 回退）

let log_p = @lm.PinyinLM::sentence_log_prob(["zhong", "guo"])
println(log_p)
// 输出: -8.5...  // 整句对数概率（Bigram）

let pp = @lm.PinyinLM::perplexity([["zhong", "guo"], ["ni", "hao"]])
println(pp)
// 输出: 128.6...  // 困惑度

let stats = @lm.PinyinLM::stats()
println(stats.vocab_size)
// 输出: 411  // 词汇量（不同音节数）

// Interpolation 平滑
let p_interp = @lm.PinyinLM::interpolation_prob("zhong", "guo", "ren", 0.5, 0.3, 0.2)
println(p_interp)
// 输出: 0.002...  // λ₁P(trigram) + λ₂P(bigram) + λ₃P(unigram)

let log_p_interp = @lm.PinyinLM::sentence_log_prob_interpolation(
  ["zhong", "guo", "ren"], 0.5, 0.3, 0.2,
)
println(log_p_interp)
// 输出: -12.8...  // Interpolation 整句对数概率
```

#### 拼音输入法引擎

```moonbit
let engine = @input.PinyinInputEngine::new()
let candidates = engine.input("nihao")
println(candidates[0].text)
// 输出: 你好  // 得分最高的候选

println(candidates[0].score)
// 输出: -8.5...  // 对数概率

println(candidates[0].segments)
// 输出: ["ni", "hao"]  // 音节切分

let engine2 = @input.PinyinInputEngine::with_beam_width(3)
let candidates2 = engine2.input("zhongguo")
// beam 宽度为 3，最多返回 3 个候选

let all = engine.input_all_segments("xian")
// 全切分模式：同时考虑 ["xi","an"] 和 ["xian"] 两种切分

let top3 = engine.input_with_limit("nihao", 3)
// 限制返回候选数量

// 添加用户词库
engine.add_user_dict({ "zhangsan" => "张三" })
let result = engine.input("zhangsan")
// "张三" 获得额外 +10.0 加分

// 模糊拼音输入
let fuzzy_candidates = engine.input_fuzzy("zongguo")
// 自动扩展 zong→zhong/zong, guo→guo, 匹配 "中国" 等
```

## 常见问题

### Q: `reverse_lookup` 返回空数组？

确认输入为合法无调拼音音节（如 `"zhong"` 而非 `"zhōng"`）。带调查找请使用 `reverse_lookup_tone_mark`，数字调查找请使用 `reverse_lookup_tone_number`。

### Q: `segment` 抛出 PinyinError？

空串会抛出 `PinyinError`，请先检查输入非空。无法完全切分的拼音串返回空数组（不抛错），可用 `can_segment` 预检。

### Q: `perplexity` 抛出 PinyinError？

空句子列表或所有句子均为空时困惑度无定义，会抛出 `PinyinError`。请确保至少传入一个非空句子。

### Q: 自定义字典添加后不生效？

`add_pinyin_dict_resource` 修改的是共享字典引用，对 `convert` 和 `data` 包均可见。但反向查找索引和语言模型频率表是构建期固化的，添加新拼音条目后 `reverse_lookup` 和 LM 概率不会自动更新。

### Q: 输入法引擎候选质量如何提升？

1. 使用 `add_user_dict` 添加领域专用词组（+10.0 加分优先）
2. 调大 `beam_width`（默认 10，值越大候选越多）
3. 使用 `input_fuzzy` 支持模糊输入（如 `zongguo` → `中国`）

### Q: Interpolation 平滑的 λ 如何选择？

λ₁ + λ₂ + λ₃ 应等于 1.0（函数不做归一化检查，调用者负责）。常见选择：λ₁=0.6, λ₂=0.3, λ₃=0.1（偏重高阶）或 λ₁=0.1, λ₂=0.3, λ₃=0.6（偏重低阶平滑）。负数 λ 会抛出 `PinyinError`。

## 字典条目数

| 字典 | 条目数 | 类型 |
|------|--------|------|
| `chinese_map` | 2533 | `Map[Int, Int]` |
| `pinyin_table` | 20903 | `Map[String, String]` |
| `mutil_pinyin_table` | 843 | `Map[String, String]` |
| `tongyong_pinyin_table` | 82 | `Map[String, String]` |

## 字典生成

字典字面量由 `scripts/gen_pinyin_dict.py` 生成：

```bash
python scripts/gen_pinyin_dict.py
```

## 约束与限制

在下述版本验证通过：

| 编号 | 依赖构建工具 | 版本号 |
| ---- | ------------ | ------ |
| 1    | **moon**     | 0.1.20260713 |

四后端（wasm / wasm-gc / js / native）各 225 个测试全通过，共 900 测试。严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

## 参考来源

本项目核心转换 API（PinyinHelper / ChineseHelper）的字典数据与接口设计参考自 Cangjie 库 [pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj)（MIT 许可证），并在此基础上自研了反向查找、分词、模糊匹配、消歧、搜索索引、声调变调、编辑距离、规范化、声母韵母提取、N-gram 语言模型、拼音输入法引擎等十大核心引擎。

| 项 | 内容 |
|---|---|
| 参考项目 | pinyin4cj |
| 参考链接 | https://gitcode.com/pinyin4cj/pinyin4cj |
| 参考项目语言 | Cangjie（仓颉） |
| 参考项目许可证 | MIT |
| 参考范围 | pinyin_helper + chinese_helper 的字典数据与接口设计 |
| 自研引擎 | reverse / segment / fuzzy / disambiguate / search / tone / normalize / lm / input + core 声母韵母（共 10 包自研引擎） |
| 适配改造 | camelCase→snake_case、异常改用 raise、字典内嵌为字面量、12 包扁平布局 |

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
