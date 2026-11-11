<div align="center">
<h1>pinyin</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.4.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/tests-604-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/packages-10-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/moon-0.1.20260713-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/targets-wasm%2Bwasm--gc%2Bjs%2Bnative-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/license-MIT-brightgreen" style="display: inline-block;" />
</p>

## 介绍

pinyin 是一个支持将汉字转换成拼音的 MoonBit 三方库，输出的拼音格式可以自定义设置。移植自 Cangjie 库 [`pinyin4cj`](https://gitcode.com/pinyin4cj/pinyin4cj)。

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
- 💪 支持常用简体/繁体中文字符转换成拼音
- 🛠️ 支持常见多音字符转换成拼音
- 🌍 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 💪 支持常用简体、繁体中文字符互转
- 🚀 支持添加自定义字典
- 🛠️ 支持常用简体/繁体中文字符转换成通用拼音
- ✅ 四后端（wasm / wasm-gc / js / native）全通过，严格 `--warn-list +73 --deny-warn` 零警告

## 软件架构

### 包结构（10 包扁平多根布局）

```
pinyin/                             # 根包 — 文档入口（不导入任何子包）
├── pinyin.mbt                      # 根包文档入口
├── core/                           # 核心类型 + 声调转换 + Trie（零依赖）
│   ├── pinyin_format.mbt           # PinyinFormat 枚举
│   ├── pinyin_error.mbt            # PinyinError suberror + raise_invalid_input
│   ├── fuzzy_rule.mbt              # FuzzyRule 枚举
│   ├── tone_conversion.mbt         # 声调转换函数
│   ├── pinyin_trie.mbt             # PinyinTrie + pinyin_syllables + strip_tone
│   ├── pinyin_core_wbtest.mbt      # 白盒测试（5）
│   └── pinyin_trie_wbtest.mbt      # 白盒测试（9）
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
├── examples/                       # 示例包（依赖 convert）
│   ├── chinese_helper_example.mbt  # 示例测试（2）
│   ├── pinyin_helper_example.mbt   # 示例测试（5）
│   ├── pinyin_array_example.mbt    # 示例测试（4）
│   └── custom_dict_example.mbt     # 示例测试（3）
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
```

线性无环依赖，core 和 data 零依赖，各子包职责单一。

### 接口说明

| 包 | 类 / 类型 | 方法 / 变体 | 说明 |
| --- | --- | --- | --- |
| `core` | `PinyinFormat` | `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter` | 输出格式枚举 |
| `core` | `FuzzyRule` | `Prefix` / `Suffix` | 模糊匹配规则枚举 |
| `core` | `PinyinError` | `InvalidInput(String)` | 统一错误类型（`pub(all) suberror`） |
| `core` | `PinyinTrie` | `new` / `insert` / `contains` / `prefix_lengths` | Trie 数据结构 |
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

## 使用说明

### 安装

```bash
moon add walkzzz/pinyin@0.4.0
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

## 字典条目数

| 字典 | 条目数 | 类型 | 源库对应 |
|------|--------|------|----------|
| `chinese_map` | 2533 | `Map[Int, Int]` | `CHINESE_MAP` |
| `pinyin_table` | 20903 | `Map[String, String]` | `PINYIN_TABLE` |
| `mutil_pinyin_table` | 843 | `Map[String, String]` | `MUTIL_PINYIN_TABLE` |
| `tongyong_pinyin_table` | 82 | `Map[String, String]` | `TONGYONG_PINYIN_TABLE` |

## 字典生成

字典字面量由 `scripts/gen_pinyin_dict.py` 从源库 `pinyin4cj` 生成：

```bash
python scripts/gen_pinyin_dict.py
```

## 约束与限制

在下述版本验证通过：

| 编号 | 依赖构建工具 | 版本号 |
| ---- | ------------ | ------ |
| 1    | **moon**     | 0.1.20260713 |

四后端（wasm / wasm-gc / js / native）各 151 个测试全通过，共 604 测试。严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

## 移植说明

本项目移植自 Cangjie 库 [pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj)。

| 项 | 内容 |
|---|---|
| 原项目名称 | pinyin4cj |
| 原项目链接 | https://gitcode.com/pinyin4cj/pinyin4cj |
| 原项目语言 | Cangjie（仓颉） |
| 原项目许可证 | MIT |
| 移植范围 | pinyin_helper + chinese_helper 全部 API，完整移植 |
| 修改适配 | camelCase→snake_case、异常改用 raise、字典内嵌为字面量、10 包扁平布局 |
| 未支持功能 | 无（完整移植） |

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
