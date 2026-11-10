<div align="center">
<h1>pinyin</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.3.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
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
- 🌫️ 支持拼音模糊匹配（zh↔z, ch↔c, sh↔s, n↔l, in↔ing, en↔eng）
- 🎵 支持声调变调规则（三声变调/一变调/不变调）
- 📏 支持拼音编辑距离（音节级 Levenshtein + 模糊距离）
- 🔧 支持拼音规范化（大小写/ü/v/声调格式统一）
- 💪 �=持常用简体/繁体中文字符转换成拼音
- 🛠️ 支持常见多音字符转换成拼音
- 🌍 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 💪 支持常用简体、繁体中文字符互转
- 🚀 支持添加自定义字典
- 🛠️ 支持常用简体/繁体中文字符转换成通用拼音
- ✅ 四后端（wasm / wasm-gc / js / native）全通过，严格 `--warn-list +73 --deny-warn` 零警告

## 软件架构

### 源码目录

```
.
├── data/                          # 字典数据包（零依赖）
│   ├── chinese_dict.mbt           # 繁→简码点映射（2533 条）
│   ├── pinyin_dict.mbt            # 单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt      # 词组拼音（843 条）
│   └── tongyong_pinyin_dict.mbt   # 通用拼音（82 条）
├── examples/                      # 示例包（14 个示例测试）
│   ├── chinese_helper_example.mbt
│   ├── pinyin_helper_example.mbt
│   ├── pinyin_array_example.mbt
│   └── custom_dict_example.mbt
├── docs/                          # 开发文档
│   ├── roadmap.md                 # 路线图
│   ├── architecture.md            # 架构设计
│   ├── api.md                     # API 文档
│   └── testing.md                 # 测试策略
├── pinyin_helper.mbt              # PinyinHelper：拼音转换核心 API
├── chinese_helper.mbt             # ChineseHelper：繁简转换、汉字判断
├── tone_conversion.mbt            # 声调转换内部逻辑
├── pinyin_format.mbt              # PinyinFormat 格式枚举
├── pinyin_error.mbt               # PinyinError 错误类型
├── pinyin_dicts.mbt               # 四张字典视图常量
├── pinyin_trie.mbt                # PinyinTrie：拼音 Trie 数据结构 + 音节表
├── pinyin_reverse.mbt             # ReversePinyinHelper：拼音→汉字反向查找
├── pinyin_segmenter.mbt           # PinyinSegmenter：拼音分词（Trie+DP）
├── pinyin_fuzzy.mbt               # FuzzyPinyinHelper：模糊匹配
├── pinyin_disambiguator.mbt       # PinyinDisambiguator：多音字消歧（Viterbi+bigram）
├── pinyin_search.mbt              # PinyinSearchIndex：拼音搜索索引
├── pinyin_tone_sandhi.mbt         # ToneSandhiHelper：声调变调规则引擎
├── pinyin_edit_distance.mbt       # PinyinEditDistance：拼音编辑距离
├── pinyin_normalizer.mbt          # PinyinNormalizer：拼音规范化
├── pinyin_easy_wbtest.mbt         # 白盒测试（内部逻辑）
├── pinyin_trie_wbtest.mbt         # Trie 白盒测试
├── pinyin_mid_test.mbt            # 黑盒测试（正向用例、格式、自定义字典）
├── pinyin_difficult_test.mbt      # 黑盒测试（字典完整性验证）
├── pinyin_reverse_test.mbt        # 反向查找黑盒测试
├── pinyin_segmenter_test.mbt      # 分词黑盒测试
├── pinyin_fuzzy_test.mbt          # 模糊匹配黑盒测试
├── pinyin_disambiguator_test.mbt  # 多音字消歧黑盒测试
├── pinyin_search_test.mbt         # 搜索索引黑盒测试
├── pinyin_tone_sandhi_test.mbt    # 变调规则黑盒测试
├── pinyin_edit_distance_test.mbt  # 编辑距离黑盒测试
├── pinyin_normalizer_test.mbt     # 拼音规范化黑盒测试
├── scripts/
│   └── gen_pinyin_dict.py         # 字典生成脚本
├── moon.mod                       # 模块元数据
├── moon.pkg                       # 根包依赖声明
├── CHANGELOG.md                   # 变更日志
├── README.md                      # 项目文档
├── README.mbt.md                  # mooncakes 发布文档（含可执行测试）
└── LICENSE                        # MIT 协议
```

- `data/` 纯数据包，零依赖，存放字典字面量（由生成脚本从源库转写）
- `examples/` 示例包，依赖根包，14 个示例测试覆盖所有公开 API
- `docs/` 开发文档（roadmap / architecture / api / testing）
- 根目录为库源码包（`walkzzz/pinyin`），含核心 API 与测试

### 接口说明

| 类 / 类型 | 方法 / 变体 | 说明 |
| --- | --- | --- |
| `PinyinHelper` | `convert_to_pinyin_string` | 词句转拼音字符串 |
| `PinyinHelper` | `convert_to_pinyin_string_traditional` | 繁体词句转拼音 |
| `PinyinHelper` | `convert_to_pinyin_array` | 单字转拼音数组 |
| `PinyinHelper` | `get_short_pinyin` | 首字母格式拼音 |
| `PinyinHelper` | `has_multi_pinyin` | 多音字检测 |
| `PinyinHelper` | `to_tongyong_pinyin_string_array` | 通用拼音数组 |
| `PinyinHelper` | `add_pinyin_dict_resource` | 添加自定义拼音字典 |
| `PinyinHelper` | `add_mutil_pinyin_dict_resource` | 添加自定义词组字典 |
| `ChineseHelper` | `convert_to_simplified_chinese` | 繁体转简体 |
| `ChineseHelper` | `convert_to_traditional_chinese` | 简体转繁体 |
| `ChineseHelper` | `is_chinese` | 汉字判断 |
| `ChineseHelper` | `is_traditional_chinese` | 繁体汉字判断 |
| `ChineseHelper` | `contains_chinese` | 包含汉字判断 |
| `ChineseHelper` | `add_chinese_dict_resource` | 添加自定义中文字典 |
| `ReversePinyinHelper` | `reverse_lookup` | 拼音→汉字反向查找（无调） |
| `ReversePinyinHelper` | `reverse_lookup_tone_mark` | 拼音→汉字反向查找（带调） |
| `ReversePinyinHelper` | `reverse_lookup_tone_number` | 拼音→汉字反向查找（数字调） |
| `ReversePinyinHelper` | `is_valid_pinyin` | 合法拼音音节判断 |
| `PinyinSegmenter` | `segment` | 连续拼音串全切分（所有方案） |
| `PinyinSegmenter` | `segment_best` | 连续拼音串最优切分（最少音节） |
| `PinyinSegmenter` | `can_segment` | 判断是否可完全切分 |
| `FuzzyPinyinHelper` | `fuzzy_expand` | 拼音模糊扩展（生成等价集合） |
| `FuzzyPinyinHelper` | `fuzzy_match` | 两个拼音是否模糊等价 |
| `FuzzyPinyinHelper` | `fuzzy_reverse_lookup` | 模糊拼音→汉字反向查找 |
| `PinyinTrie` | `new` / `insert` / `contains` / `prefix_lengths` | Trie 数据结构 |
| `PinyinDisambiguator` | `disambiguate` | 多音字上下文消歧（Viterbi + bigram 词频模型） |
| `PinyinSearchIndex` | `new` / `add_document` / `search_initial` / `search_pinyin` / `search_fuzzy` | 拼音搜索索引（倒排索引） |
| `ToneSandhiHelper` | `apply_tone_sandhi` | 声调变调规则（三声变调/一变调/不变调） |
| `PinyinEditDistance` | `distance` / `fuzzy_distance` | 拼音编辑距离（音节级 Levenshtein + 模糊距离） |
| `PinyinNormalizer` | `normalize` / `normalize_to_tone_number` / `normalize_to_without_tone` | 拼音规范化（大小写/ü/v/声调格式统一） |
| `PinyinFormat` | `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter` | 输出格式枚举 |
| `FuzzyRule` | `Prefix` / `Suffix` | 模糊匹配规则枚举 |
| `PinyinError` | `PinyinError(String)` | 统一错误类型（`pub(all) suberror`） |

## 使用说明

### 安装

```bash
moon add walkzzz/pinyin@0.3.0
```

### 编译构建

```bash
moon check --target all --warn-list +73 --deny-warn   # 四后端严格编译检查
moon test  --target all --warn-list +73 --deny-warn   # 四后端测试
moon fmt    --check                                    # 格式检查
moon info   --target all                              # 生成接口文件
```

### 功能示例

> 黑盒位置调用需通过 `@pinyin.` 限定访问宿主包类型与方法。

#### 繁体转简体

```moonbit
let pinyin = @pinyin.ChineseHelper::convert_to_simplified_chinese("臺，喪，麗")
println(pinyin)
// 输出: 台，丧，丽
```

#### 简体转繁体

```moonbit
let pinyin = @pinyin.ChineseHelper::convert_to_traditional_chinese("我是中国人")
println(pinyin)
// 输出: 我是中國人
```

#### 词、句转换成拼音

```moonbit
let pinyin = @pinyin.PinyinHelper::convert_to_pinyin_string("我是中国人", " ")
println(pinyin)
// 输出: wǒ shì zhōng zhòng guó rén
```

#### 自定义输出格式

```moonbit
let pinyin = @pinyin.PinyinHelper::convert_to_pinyin_string("中国", " ", format=WithToneNumber)
println(pinyin)
// 输出: zhong1 zhong4 guo2
```

#### 添加自定义拼音字典

```moonbit
let map : Map[String, String] = { "上": "shǎng" }
@pinyin.PinyinHelper::add_pinyin_dict_resource(map)
let pinyin = @pinyin.PinyinHelper::convert_to_pinyin_string("上午", " ")
println(pinyin)
// 输出: shǎng wǔ
```

#### 添加自定义拼音组合字典

```moonbit
let map : Map[String, String] = { "阿弥陀佛": "ā,mí,tuó,fó" }
@pinyin.PinyinHelper::add_mutil_pinyin_dict_resource(map)
let pinyin = @pinyin.PinyinHelper::convert_to_pinyin_string("阿弥陀佛", " ")
println(pinyin)
// 输出: ā mí tuó fó
```

#### 添加自定义中文字典

```moonbit
let map : Map[Int, Int] = { 0x7691: 0x75C7 }  // 癥 → 症
@pinyin.ChineseHelper::add_chinese_dict_resource(map)
let pinyin = @pinyin.ChineseHelper::convert_to_simplified_chinese("癥")
println(pinyin)
// 输出: 症
```

#### 多音字转拼音集合

```moonbit
let pinyin = @pinyin.PinyinHelper::convert_to_pinyin_array('长')
println(pinyin)
// 输出: ["cháng", "zhǎng"]
```

#### 繁简体转拼音

```moonbit
let pinyin = @pinyin.PinyinHelper::convert_to_pinyin_array('嚴')
println(pinyin)
// 输出: ["yán"]
```

#### 繁简体转通用拼音

```moonbit
let simplePinyin = @pinyin.PinyinHelper::to_tongyong_pinyin_string_array('傳')
let traditionalPinyin = @pinyin.PinyinHelper::to_tongyong_pinyin_string_array('传')
println(simplePinyin)
println(traditionalPinyin)
// 输出: ["chuan2", "jhuan4"]
//       ["chuan2", "jhuan4"]
```

#### 拼音→汉字反向查找

```moonbit
let chars = @pinyin.ReversePinyinHelper::reverse_lookup("zhong")
println(chars)
// 输出: ["中", "重", "种", ...]

let chars2 = @pinyin.ReversePinyinHelper::reverse_lookup_tone_mark("zhōng")
println(chars2)
// 输出: ["中", ...]

let chars3 = @pinyin.ReversePinyinHelper::reverse_lookup_tone_number("zhong1")
println(chars3)
// 输出: ["中", ...]
```

#### 拼音分词

```moonbit
let segments = @pinyin.PinyinSegmenter::segment("nihao")
println(segments)
// 输出: [["ni", "hao"]]

let segments2 = @pinyin.PinyinSegmenter::segment("xian")
println(segments2)
// 输出: [["xi", "an"], ["xian"]]

let best = @pinyin.PinyinSegmenter::segment_best("xian")
println(best)
// 输出: ["xian"]
```

#### 模糊匹配

```moonbit
let variants = @pinyin.FuzzyPinyinHelper::fuzzy_expand("zhong")
println(variants)
// 输出: ["zhong", "zong"]

let match = @pinyin.FuzzyPinyinHelper::fuzzy_match("zhong", "zong")
println(match)
// 输出: true

let chars = @pinyin.FuzzyPinyinHelper::fuzzy_reverse_lookup("zhong")
println(chars)
// 输出: ["中", "重", "种", ..., "总", "宗", ...]
```

#### 多音字消歧

```moonbit
let result = @pinyin.PinyinDisambiguator::disambiguate("中国")
println(result)
// 输出: ["zhong1", "guo2"]

let result2 = @pinyin.PinyinDisambiguator::disambiguate("重要")
println(result2)
// 输出: ["zhong4", "yao4"]
```

#### 拼音搜索索引

```moonbit
let index = @pinyin.PinyinSearchIndex::new()
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
let result = @pinyin.ToneSandhiHelper::apply_tone_sandhi(["ni3", "hao3"])
println(result)
// 输出: ["ni2", "hao3"]  // 三声变调：ni3→ni2

let result2 = @pinyin.ToneSandhiHelper::apply_tone_sandhi(["yi1", "ge4"])
println(result2)
// 输出: ["yi2", "ge4"]  // 一变调：yi1→yi2
```

#### 拼音编辑距离

```moonbit
let dist = @pinyin.PinyinEditDistance::distance(["zhong", "guo"], ["zhong", "ren"])
println(dist)
// 输出: 1

let fuzzy_dist = @pinyin.PinyinEditDistance::fuzzy_distance(["zhong"], ["zong"])
println(fuzzy_dist)
// 输出: 0  // zh↔z 模糊等价
```

#### 拼音规范化

```moonbit
let result = @pinyin.PinyinNormalizer::normalize("ZHONG1")
println(result)
// 输出: "zhōng"  // 大写转小写 + 数字调→带调标记

let result2 = @pinyin.PinyinNormalizer::normalize("lv3")
println(result2)
// 输出: "lǚ"  // v→ü + 数字调→带调标记

let result3 = @pinyin.PinyinNormalizer::normalize_to_without_tone("zhōng")
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

四后端（wasm / wasm-gc / js / native）各 144 个测试全通过，共 576 测试。严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

## 移植说明

本项目移植自 Cangjie 库 [pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj)。

| 项 | 内容 |
|---|---|
| 原项目名称 | pinyin4cj |
| 原项目链接 | https://gitcode.com/pinyin4cj/pinyin4cj |
| 原项目语言 | Cangjie（仓颉） |
| 原项目许可证 | MIT |
| 移植范围 | pinyin_helper + chinese_helper 全部 API，完整移植 |
| 修改适配 | camelCase→snake_case、异常改用 raise、字典内嵌为字面量、根目录布局 |
| 未支持功能 | 无（完整移植） |

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
