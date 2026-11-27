# pinyin

自研 MoonBit 拼音引擎：汉字→拼音、拼音→汉字、繁简转换、多音字消歧、拼音分词、模糊匹配、搜索索引、声调变调、编辑距离、规范化、N-gram 语言模型、拼音输入法引擎。

## 在线演示

浏览器内演示（拼音转换 / 输入法候选 / 双拼 / 消歧）：<https://toadium.github.io/pinyin/>

## 介绍

pinyin 是一个自研的 MoonBit 拼音引擎，提供汉字→拼音、拼音→汉字、繁简转换、多音字消歧、拼音分词、模糊匹配、搜索索引、声调变调、编辑距离、规范化、N-gram 语言模型、拼音输入法引擎等全栈拼音能力。

### 特性

- 支持词、句转换成拼音
- 支持常用简体/繁体中文字符转换成拼音
- 支持常见多音字符转换成拼音
- 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 支持常用简体、繁体中文字符互转
- 支持添加自定义字典
- 支持常用简体/繁体中文字符转换成通用拼音
- 支持拼音流式处理（PinyinStreamProcessor，逐字符输入实时输出）
- 支持拼音模糊匹配（9 组规则：zh↔z, ch↔c, sh↔s, n↔l, f↔h, in↔ing, en↔eng, an↔ang, ong↔eng）
- 支持声调变调规则（三声变调/一变调/不变调/七变调/八变调）
- 支持 N-gram 语言模型（Unigram/Bigram/Trigram 频率表、Laplace 平滑、Katz 回退、困惑度）
- 支持拼音输入法引擎（Beam Search + LM 评分、全切分候选、用户词库、模糊输入、可配置 beam 宽度）
- 支持声母/韵母提取（get_initial/get_final/initials_list）

## 软件架构

### 包结构（12 功能包 + data + playground，共 14 包）

> 树内测试数为快速索引；完整清单与实测口径以 `docs/testing.md` 为准。

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
│   └── pinyin_trie_wbtest.mbt      # 白盒测试（9）
├── data/                           # 字典数据包（零依赖）
│   ├── chinese_dict.mbt            # 繁→简映射（2533 条）
│   ├── pinyin_dict.mbt             # 单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt       # 词组拼音（843 条）
│   ├── tongyong_pinyin_dict.mbt    # 通用拼音（82 条）
│   ├── common_phrases.mbt          # 常用词（151 条）
│   ├── large_phrase_raw_01..06.mbt # pypinyin 大词库字符串分片（47,110 条）
│   ├── large_phrases.mbt           # 大词库运行时解析与查询
│   └── common_chars.mbt            # 常用字排序（GB2312 一级 3755 + 高频字序）
├── convert/                        # 核心转换引擎（依赖 core + data）
│   ├── pinyin_dicts.mbt            # 字典视图常量
│   ├── chinese_helper.mbt          # ChineseHelper 命名空间
│   ├── pinyin_helper.mbt           # PinyinHelper 命名空间
│   ├── pinyin_stream_processor.mbt # PinyinStreamProcessor 流式处理器
│   ├── convert_wbtest.mbt          # 白盒测试（8）
│   ├── convert_test.mbt            # 黑盒测试（22）
│   ├── convert_dict_test.mbt       # 黑盒测试（6）
│   └── stream_processor_test.mbt   # 黑盒测试（7）
├── reverse/                        # 拼音→汉字反向查找（依赖 core + data）
│   ├── pinyin_reverse.mbt
│   └── reverse_test.mbt            # 黑盒测试（10）
├── segment/                        # 拼音分词（依赖 core）
│   ├── pinyin_segmenter.mbt
│   └── segment_test.mbt            # 黑盒测试（12）
├── fuzzy/                          # 模糊匹配（依赖 core + reverse）
│   ├── pinyin_fuzzy.mbt
│   └── fuzzy_test.mbt              # 黑盒测试（20）
├── disambiguate/                   # 多音字消歧（依赖 core + convert）
│   ├── pinyin_disambiguator.mbt
│   └── disambiguate_test.mbt       # 黑盒测试（7）
├── search/                         # 搜索索引（依赖 core + convert + segment + fuzzy）
│   ├── pinyin_search.mbt
│   └── search_test.mbt             # 黑盒测试（9）
├── tone/                           # 声调变调（依赖 core）
│   ├── pinyin_tone_sandhi.mbt
│   └── tone_test.mbt               # 黑盒测试（14）
├── normalize/                      # 规范化 + 编辑距离（依赖 core + segment + fuzzy）
│   ├── pinyin_normalizer.mbt
│   ├── pinyin_edit_distance.mbt
│   ├── normalizer_test.mbt         # 黑盒测试（12）
│   └── edit_distance_test.mbt      # 黑盒测试（8）
├── lm/                             # N-gram 语言模型（依赖 core + data + math）
│   ├── pinyin_lm.mbt               # PinyinLM + LMStats + Laplace 平滑 + Katz 回退 + Interpolation
│   └── lm_test.mbt                 # 黑盒测试（15）
├── input/                          # 拼音输入法引擎（依赖 core + segment + reverse + lm + math + data + fuzzy）
│   ├── pinyin_input.mbt            # PinyinInputEngine + InputCandidate + Beam Search + 用户词库 + 模糊输入
│   └── input_test.mbt              # 黑盒测试（30）
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
├── shuangpin/                      # 双拼输入（小鹤/自然码，双拼↔全拼）
│   ├── pinyin_shuangpin.mbt
│   └── shuangpin_test.mbt          # 黑盒测试（12）
├── demo/                           # 端到端可运行演示（moon run demo）
├── playground/                     # 浏览器演示导出层（js 后端，#export_name 17 函数）
│   ├── playground.mbt
│   └── pkg.generated.mbti
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

- `core/` 核心类型包，零依赖，含 PinyinFormat / PinyinError / FuzzyRule / PinyinTrie / 声调转换
- `data/` 纯数据包，零依赖，存放字典字面量（由生成脚本从源库转写）
- `convert/` 核心转换引擎，依赖 core + data，含 PinyinHelper / ChineseHelper
- `reverse/` 拼音→汉字反向查找，依赖 core + data
- `segment/` 拼音分词（Trie+DP），依赖 core
- `fuzzy/` 模糊匹配，依赖 core + reverse
- `disambiguate/` 多音字消歧（Viterbi+bigram），依赖 core + convert
- `search/` 搜索索引（倒排索引），依赖 core + convert + segment + fuzzy
- `tone/` 声调变调规则，依赖 core
- `normalize/` 规范化 + 编辑距离，依赖 core + segment + fuzzy
- `lm/` N-gram 语言模型，依赖 core + data + math，含 PinyinLM / LMStats / Laplace 平滑 / Katz 回退
- `input/` 拼音输入法引擎，依赖 core + segment + reverse + lm + math + data + fuzzy，含 PinyinInputEngine / InputCandidate / Beam Search / 用户词库 / 模糊输入
- `examples/` 示例包，12 子包全覆盖，37 个示例测试
- `shuangpin/` 双拼输入（小鹤/自然码 ↔ 全拼，零依赖）
- `playground/` 浏览器演示导出层，17 个 `#export_name`（js 后端）
- `docs/` 开发文档（roadmap / architecture / api / testing）
- 根包为文档入口（如 owl-mbt），不导入任何子包

## 使用说明

### 编译构建

```bash
moon check
moon test
moon run demo --target native
```

### 功能示例

#### 繁体转简体

```mbt nocheck
///|
test "readme_convert_to_simplified" {
  inspect(
    @convert.ChineseHelper::convert_to_simplified_chinese("臺，喪，麗"),
    content="台，丧，丽",
  )
}
```

#### 简体转繁体

```mbt nocheck
///|
test "readme_convert_to_traditional" {
  inspect(
    @convert.ChineseHelper::convert_to_traditional_chinese("我是中国人"),
    content="我是中國人",
  )
}
```

#### 词、句转换成拼音

```mbt nocheck
///|
test "readme_convert_to_pinyin_string" {
  inspect(
    @convert.PinyinHelper::convert_to_pinyin_string("我是中国人", " "),
    content="wǒ shì zhōng zhòng guó rén",
  )
}
```

#### 自定义输出格式

```mbt nocheck
///|
test "readme_with_tone_number" {
  inspect(
    @convert.PinyinHelper::convert_to_pinyin_string(
      "中国",
      " ",
      format=WithToneNumber,
    ),
    content="zhong1 zhong4 guo2",
  )
}
```

#### 多音字转拼音集合

```mbt nocheck
///|
test "readme_convert_to_pinyin_array" {
  debug_inspect(
    @convert.PinyinHelper::convert_to_pinyin_array('长'),
    content="[\"cháng\", \"zhǎng\"]",
  )
}
```

#### 繁简体转通用拼音

```mbt nocheck
///|
test "readme_tongyong_pinyin" {
  debug_inspect(
    @convert.PinyinHelper::to_tongyong_pinyin_string_array('传'),
    content="[\"chuan2\", \"jhuan4\"]",
  )
}
```

#### 首字母格式

```mbt nocheck
///|
test "readme_get_short_pinyin" {
  inspect(@convert.PinyinHelper::get_short_pinyin("中国"), content="z z g")
}
```

#### 多音字检测

```mbt nocheck
///|
test "readme_has_multi_pinyin" {
  inspect(@convert.PinyinHelper::has_multi_pinyin('中'), content="true")
}
```

#### 汉字判断

```mbt nocheck
///|
test "readme_is_chinese" {
  inspect(@convert.ChineseHelper::is_chinese('中'), content="true")
  inspect(@convert.ChineseHelper::contains_chinese("abc中"), content="true")
}
```

#### N-gram 语言模型

```mbt nocheck
///|
test "readme_lm_unigram_prob" {
  let p = @lm.PinyinLM::unigram_prob("zhong")
  assert_true(p > 0.0)
  assert_true(p < 1.0)
}
```

```mbt nocheck
///|
test "readme_lm_bigram_prob" {
  let p = @lm.PinyinLM::bigram_prob("zhong", "guo")
  assert_true(p > 0.0)
  assert_true(p < 1.0)
}
```

```mbt nocheck
///|
test "readme_lm_sentence_log_prob" {
  let log_p = @lm.PinyinLM::sentence_log_prob(["zhong", "guo"])
  assert_true(log_p < 0.0)
}
```

#### 拼音输入法引擎

```mbt nocheck
///|
test "readme_input" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input("nihao")
  assert_true(candidates.length() > 0)
  assert_true(candidates[0].text.length() > 0)
  assert_true(candidates[0].score < 0.0)
  assert_true(candidates[0].segments.length() > 0)
}
```

```mbt nocheck
///|
test "readme_input_all_segments" {
  let engine = @input.PinyinInputEngine::new()
  let candidates = engine.input_all_segments("xian")
  assert_true(candidates.length() > 0)
}
```

#### 用户词库与模糊输入

```mbt nocheck
///|
test "readme_input_user_dict" {
  let engine = @input.PinyinInputEngine::new()
  engine.add_user_dict({ "zhangsan" => "张三" })
  let candidates = engine.input("zhangsan")
  let found = candidates.iter().any(fn(c) { c.text == "张三" })
  assert_true(found)
}
```

#### N-gram 语言模型 Interpolation 平滑

```mbt nocheck
///|
test "readme_lm_interpolation" {
  let p = @lm.PinyinLM::interpolation_prob("zhong", "guo", "ren", 0.5, 0.3, 0.2)
  assert_true(p > 0.0)
  assert_true(p < 1.0)
}
```

## 字典条目数

| 字典 | 条目数 | 类型 | 源库对应 |
|------|--------|------|----------|
| `chinese_map` | 2533 | `Map[Int, Int]` | `CHINESE_MAP` |
| `pinyin_table` | 20903 | `Map[String, String]` | `PINYIN_TABLE` |
| `mutil_pinyin_table` | 843 | `Map[String, String]` | `MUTIL_PINYIN_TABLE` |
| `tongyong_pinyin_table` | 82 | `Map[String, String]` | `TONGYONG_PINYIN_TABLE` |

## 参考来源

本项目核心转换 API（PinyinHelper / ChineseHelper）的字典数据与接口设计参考自 Cangjie 库 [pinyin4cj](https://gitcode.com/Cangjie-TPC/pinyin4cj)（MIT 许可证；Gitcode 仓库页 license 徽章为 MIT，GitHub 三个公开镜像仓库 license 经 API 核验均为 MIT），并在此基础上自研了反向查找、分词、模糊匹配、消歧、搜索索引、声调变调、编辑距离、规范化、声母韵母提取、N-gram 语言模型、拼音输入法引擎等十大核心引擎。字典字面量由 `scripts/gen_pinyin_dict.py` 生成：

```bash
python scripts/gen_pinyin_dict.py
```

## 约束与限制

在下述版本验证通过：

| 编号 | 依赖构建工具 | 版本号 |
| ---- | ------------ | ------ |
| 1    | **moon**     | 0.1.20261117 |

四后端（wasm / wasm-gc / js / native）各 328 测试全通过，共 1312 测试。严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。
