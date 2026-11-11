# pinyin

MoonBit port of pinyin4cj: Chinese-to-pinyin conversion.

## 介绍

pinyin 是一个支持将汉字转换成拼音的库，输出的拼音格式可以自定义设置。移植自 Cangjie 库 `pinyin4cj`。

### 特性

- 支持词、句转换成拼音
- 支持常用简体/繁体中文字符转换成拼音
- 支持常见多音字符转换成拼音
- 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 支持常用简体、繁体中文字符互转
- 支持添加自定义字典
- 支持常用简体/繁体中文字符转换成通用拼音

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
│   ├── convert_wbtest.mbt          # 白盒测试（8）
│   ├── convert_test.mbt            # 黑盒测试（19）
│   └── convert_dict_test.mbt       # 黑盒测试（5）
├── reverse/                        # 拼音→汉字反向查找（依赖 core + data）
│   ├── pinyin_reverse.mbt
│   └── reverse_test.mbt            # 黑盒测试（10）
├── segment/                        # 拼音分词（依赖 core）
│   ├── pinyin_segmenter.mbt
│   └── segment_test.mbt            # 黑盒测试（12）
├── fuzzy/                          # 模糊匹配（依赖 core + reverse）
│   ├── pinyin_fuzzy.mbt
│   └── fuzzy_test.mbt              # 黑盒测试（14）
├── disambiguate/                   # 多音字消歧（依赖 core + convert）
│   ├── pinyin_disambiguator.mbt
│   └── disambiguate_test.mbt       # 黑盒测试（7）
├── search/                         # 搜索索引（依赖 core + convert + segment + fuzzy）
│   ├── pinyin_search.mbt
│   └── search_test.mbt             # 黑盒测试（7）
├── tone/                           # 声调变调（依赖 core）
│   ├── pinyin_tone_sandhi.mbt
│   └── tone_test.mbt               # 黑盒测试（8）
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
- `examples/` 示例包，依赖 convert，14 个示例测试
- `docs/` 开发文档（roadmap / architecture / api / testing）
- 根包为文档入口（如 owl-mbt），不导入任何子包

## 使用说明

### 编译构建

```bash
moon check
moon test
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

四后端（wasm / wasm-gc / js / native）各 135 测试全通过，严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。
