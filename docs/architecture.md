# 架构设计

## 包依赖关系

```
examples ──> pinyin (根包) ──> data
```

线性无环，三层结构。根包与 data/examples 之间通过 `moon.pkg` 声明依赖。

## 根包（pinyin）

核心 API 包，包含拼音转换的所有公开接口。源码位于仓库根目录（非 src/ 子目录，对齐 chrono_tz-mbt 约定）。

### 模块划分

| 文件 | 职责 | 行数 |
|------|------|------|
| `pinyin_helper.mbt` | 拼音转换主入口（PinyinHelper 命名空间） | 190 |
| `chinese_helper.mbt` | 繁简转换 + 汉字判断（ChineseHelper 命名空间） | 90 |
| `tone_conversion.mbt` | 声调转换内部逻辑 | 104 |
| `pinyin_format.mbt` | 输出格式枚举 | 20 |
| `pinyin_error.mbt` | 统一错误类型 | 7 |
| `pinyin_dicts.mbt` | 字典视图常量 | 20 |
| `pinyin_trie.mbt` | PinyinTrie 数据结构 + ~420 拼音音节 + strip_tone/strip_tone_number | 237 |
| `pinyin_reverse.mbt` | ReversePinyinHelper：拼音→汉字反向查找 | 78 |
| `pinyin_segmenter.mbt` | PinyinSegmenter：Trie+DP 拼音分词 | 116 |
| `pinyin_fuzzy.mbt` | FuzzyPinyinHelper：模糊匹配 + FuzzyRule 枚举 | 120 |
| `pinyin_disambiguator.mbt` | PinyinDisambiguator：多音字消歧（Viterbi+bigram） | 180 |
| `pinyin_search.mbt` | PinyinSearchIndex：拼音搜索索引（倒排索引） | 130 |
| `pinyin_tone_sandhi.mbt` | ToneSandhiHelper：声调变调规则引擎 | 140 |
| `pinyin_edit_distance.mbt` | PinyinEditDistance：音节级编辑距离 + 模糊距离 | 100 |
| `pinyin_normalizer.mbt` | PinyinNormalizer：拼音规范化 | 120 |

### 公开 API

- `PinyinHelper`：convert_to_pinyin_string / convert_to_pinyin_string_traditional / convert_to_pinyin_array / get_short_pinyin / has_multi_pinyin / to_tongyong_pinyin_string_array / add_pinyin_dict_resource / add_mutil_pinyin_dict_resource
- `ChineseHelper`：is_chinese / is_traditional_chinese / contains_chinese / convert_to_simplified_chinese / convert_to_traditional_chinese / add_chinese_dict_resource
- `ReversePinyinHelper`：reverse_lookup / reverse_lookup_tone_mark / reverse_lookup_tone_number / is_valid_pinyin
- `PinyinSegmenter`：segment / segment_best / can_segment
- `FuzzyPinyinHelper`：fuzzy_expand / fuzzy_match / fuzzy_reverse_lookup
- `PinyinDisambiguator`：disambiguate（Viterbi + bigram 词频模型）
- `PinyinSearchIndex`：new / add_document / search_initial / search_pinyin / search_fuzzy
- `ToneSandhiHelper`：apply_tone_sandhi（三声变调/一变调/不变调）
- `PinyinEditDistance`：distance / fuzzy_distance（音节级 Levenshtein + 模糊距离）
- `PinyinNormalizer`：normalize / normalize_to_tone_number / normalize_to_without_tone
- `PinyinTrie`：new / insert / contains / prefix_lengths
- `PinyinFormat`：WithToneMark / WithoutTone / WithToneNumber / FirstLetter
- `FuzzyRule`：Prefix / Suffix
- `PinyinError`：`pub(all) suberror`，统一错误类型，可用 `raise PinyinError("msg")` 抛错

### 错误处理

采用 MoonBit `pub(all) suberror PinyinError { PinyinError(String) }`，自动提升为 `Error`。`convert_to_pinyin_string` / `get_short_pinyin` / `has_multi_pinyin` 等方法用 `raise PinyinError` 抛错，调用方用 `try ... catch { PinyinError::PinyinError(msg) => ... }` 捕获。

## data 包

纯数据包，零依赖。包含 4 张字典：

| 字典 | 类型 | 条目数 | 说明 |
|------|------|--------|------|
| `chinese_dict` | Map[Int, Int] | 2533 | 繁→简码点映射 |
| `pinyin_dict` | Map[String, String] | 20903 | 单字拼音（分 11 段 merge） |
| `mutil_pinyin_dict` | Map[String, String] | 843 | 词组拼音 |
| `tongyong_pinyin_dict` | Map[String, String] | 82 | 通用拼音 |

### pinyin_dict 分段设计

`pinyin_dict.mbt`（20962 行）分 11 段（seg0..seg10）后 `.merge()` 合并，规避单段文本过长警告。

### 字典视图共享

根包 `pinyin_dicts.mbt` 中的 `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table` 与 data 包的 `chinese_dict` 等共享同一 Map 对象引用（非拷贝），`add_*_dict_resource` 的自定义追加对两者均可见。

## examples 包

示例包，依赖根包。4 个示例文件共 14 个示例测试覆盖所有公开 API：
- `chinese_helper_example.mbt`（2）
- `pinyin_helper_example.mbt`（5）
- `pinyin_array_example.mbt`（4）
- `custom_dict_example.mbt`（3）

## 多后端

- `supported_targets = "+wasm+wasm-gc+js+native"`
- 四后端各 144 测试全通过，共 576 测试
- 严格模式 `--warn-list +73 --deny-warn` 零警告零错误
- 无 WASM local count 问题（字典用 Map 字面量，非大 match）