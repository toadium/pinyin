# API 文档

> 各子包通过 `@包名.` 限定访问，如 `@convert.PinyinHelper`、`@reverse.ReversePinyinHelper`。枚举变体在类型可推断位置（如 `format=` 参数）可裸用。

## core 包

### PinyinFormat

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark      // lǚ
  WithoutTone       // lü
  WithToneNumber    // lü3
  FirstLetter       // l
}
```

输出格式枚举，4 个变体分别对应：带声调标记 / 不带声调 / 带声调数字 / 首字母。

#### name

```moonbit
pub fn PinyinFormat::name(self : PinyinFormat) -> String
```

返回格式名称字符串（大写下划线形式）。

### FuzzyRule

```moonbit
pub(all) enum FuzzyRule {
  Prefix
  Suffix
}
```

模糊匹配规则枚举。

### PinyinError

```moonbit
pub(all) suberror PinyinError {
  InvalidInput(String)
}
```

统一错误类型，自动提升 `Error`。子包用 `@core.raise_invalid_input("msg")` 抛错，catch 块用 `_` 匹配所有错误。

### raise_invalid_input

```moonbit
pub fn raise_invalid_input(msg : String) -> Unit raise PinyinError
```

PinyinError 跨包包装函数，规避 MoonBit [0073] 跨包误报。

### PinyinTrie

```moonbit
pub fn PinyinTrie::new() -> PinyinTrie
pub fn PinyinTrie::insert(self : PinyinTrie, word : String) -> Unit
pub fn PinyinTrie::contains(self : PinyinTrie, word : String) -> Bool
pub fn PinyinTrie::prefix_lengths(self : PinyinTrie, word : String) -> Array[Int]
```

Trie 数据结构，用于拼音分词和音节验证。

## convert 包

### PinyinHelper

拼音转换主入口。

#### convert_to_pinyin_string

```moonbit
pub fn PinyinHelper::convert_to_pinyin_string(
  str : String,
  separator : String,
  format : PinyinFormat~ = PinyinFormat::WithToneMark
) -> String raise PinyinError
```

词句转拼音字符串。默认带声调标记。

#### convert_to_pinyin_string_traditional

```moonbit
pub fn PinyinHelper::convert_to_pinyin_string_traditional(
  str : String,
  separator : String,
  format : PinyinFormat~ = PinyinFormat::WithToneMark
) -> String raise PinyinError
```

先繁→简再转拼音。

#### convert_to_pinyin_array

```moonbit
pub fn PinyinHelper::convert_to_pinyin_array(
  c : Char,
  format : PinyinFormat~ = PinyinFormat::WithToneMark
) -> Array[String]
```

单字所有读音数组。非汉字返回 `[]`。

#### get_short_pinyin

```moonbit
pub fn PinyinHelper::get_short_pinyin(str : String) -> String raise PinyinError
```

首字母格式。空串抛 `PinyinError`。

#### has_multi_pinyin

```moonbit
pub fn PinyinHelper::has_multi_pinyin(c : Char) -> Bool raise PinyinError
```

多音字检测。非汉字抛 `PinyinError`。

#### to_tongyong_pinyin_string_array

```moonbit
pub fn PinyinHelper::to_tongyong_pinyin_string_array(char : Char) -> Array[String]
```

通用拼音数组。非汉字返回 `[]`。

#### add_pinyin_dict_resource

```moonbit
pub fn PinyinHelper::add_pinyin_dict_resource(dict : Map[String, String]) -> Unit
```

追加自定义单字拼音字典（原地合并，键冲突新值覆盖）。

#### add_mutil_pinyin_dict_resource

```moonbit
pub fn PinyinHelper::add_mutil_pinyin_dict_resource(dict : Map[String, String]) -> Unit
```

追加自定义词组拼音字典（原地合并）。

### ChineseHelper

繁简转换 + 汉字判断。

#### is_chinese

```moonbit
pub fn ChineseHelper::is_chinese(c : Char) -> Bool
```

判断字符是否为汉字（CJK 统一表意文字 U+4E00-U+9FFF 或汉字零 U+3007）。

#### is_traditional_chinese

```moonbit
pub fn ChineseHelper::is_traditional_chinese(c : Char) -> Bool
```

判断字符是否为繁体汉字（在 `chinese_map` 中存在映射）。

#### contains_chinese

```moonbit
pub fn ChineseHelper::contains_chinese(str : String) -> Bool
```

判断字符串是否包含汉字。

#### convert_to_simplified_chinese

```moonbit
pub fn ChineseHelper::convert_to_simplified_chinese(str : String) -> String
```

繁→简转换：逐字符查 `chinese_map`，命中替换为简体码点，未命中原样。

#### convert_to_traditional_chinese

```moonbit
pub fn ChineseHelper::convert_to_traditional_chinese(str : String) -> String
```

简→繁转换：逐字符遍历 `chinese_map` 反查，命中替换为键，未命中原样。

#### add_chinese_dict_resource

```moonbit
pub fn ChineseHelper::add_chinese_dict_resource(dict : Map[Int, Int]) -> Unit
```

追加自定义繁简映射（原地合并）。

## reverse 包

### ReversePinyinHelper

拼音→汉字反向查找。

#### reverse_lookup

```moonbit
pub fn ReversePinyinHelper::reverse_lookup(pinyin : String) -> Array[String] raise PinyinError
```

无调拼音→汉字反向查找。

#### reverse_lookup_tone_mark

```moonbit
pub fn ReversePinyinHelper::reverse_lookup_tone_mark(pinyin : String) -> Array[String] raise PinyinError
```

带调拼音→汉字反向查找。

#### reverse_lookup_tone_number

```moonbit
pub fn ReversePinyinHelper::reverse_lookup_tone_number(pinyin : String) -> Array[String] raise PinyinError
```

数字调拼音→汉字反向查找。

#### is_valid_pinyin

```moonbit
pub fn ReversePinyinHelper::is_valid_pinyin(pinyin : String) -> Bool
```

合法拼音音节判断。

## segment 包

### PinyinSegmenter

连续拼音串分词。

#### segment

```moonbit
pub fn PinyinSegmenter::segment(pinyin : String) -> Array[Array[String]] raise PinyinError
```

全切分（返回所有可能方案）。

#### segment_best

```moonbit
pub fn PinyinSegmenter::segment_best(pinyin : String) -> Array[String] raise PinyinError
```

最优切分（最少音节）。

#### can_segment

```moonbit
pub fn PinyinSegmenter::can_segment(pinyin : String) -> Bool
```

判断是否可完全切分。

## fuzzy 包

### FuzzyPinyinHelper

拼音模糊匹配。

#### fuzzy_expand

```moonbit
pub fn FuzzyPinyinHelper::fuzzy_expand(pinyin : String) -> Array[String] raise PinyinError
```

拼音模糊扩展（生成等价集合）。

#### fuzzy_match

```moonbit
pub fn FuzzyPinyinHelper::fuzzy_match(pinyin1 : String, pinyin2 : String) -> Bool raise PinyinError
```

两个拼音是否模糊等价。

#### fuzzy_reverse_lookup

```moonbit
pub fn FuzzyPinyinHelper::fuzzy_reverse_lookup(pinyin : String) -> Array[String] raise PinyinError
```

模糊拼音→汉字反向查找。

## disambiguate 包

### PinyinDisambiguator

多音字上下文消歧（Viterbi + bigram 词频模型）。

#### disambiguate

```moonbit
pub fn PinyinDisambiguator::disambiguate(text : String) -> Array[String] raise PinyinError
```

多音字上下文消歧，返回每个字的数字调拼音。

## search 包

### PinyinSearchIndex

拼音搜索索引（倒排索引）。

#### new

```moonbit
pub fn PinyinSearchIndex::new() -> PinyinSearchIndex
```

创建搜索索引。

#### add_document

```moonbit
pub fn PinyinSearchIndex::add_document(self : PinyinSearchIndex, id : Int, text : String) -> Unit
```

添加文档到索引。

#### search_initial

```moonbit
pub fn PinyinSearchIndex::search_initial(self : PinyinSearchIndex, initials : String) -> Array[Int]
```

首字母搜索。

#### search_pinyin

```moonbit
pub fn PinyinSearchIndex::search_pinyin(self : PinyinSearchIndex, pinyin : String) -> Array[Int]
```

连续拼音搜索。

#### search_fuzzy

```moonbit
pub fn PinyinSearchIndex::search_fuzzy(self : PinyinSearchIndex, pinyin : String) -> Array[Int]
```

模糊拼音搜索。

## tone 包

### ToneSandhiHelper

声调变调规则引擎。

#### apply_tone_sandhi

```moonbit
pub fn ToneSandhiHelper::apply_tone_sandhi(syllables : Array[String]) -> Array[String]
```

声调变调规则（三声变调/一变调/不变调）。

## normalize 包

### PinyinNormalizer

拼音规范化。

#### normalize

```moonbit
pub fn PinyinNormalizer::normalize(pinyin : String) -> String
```

规范化（大小写/ü/v/声调格式统一为带调标记）。

#### normalize_to_tone_number

```moonbit
pub fn PinyinNormalizer::normalize_to_tone_number(pinyin : String) -> String
```

规范化为数字调格式。

#### normalize_to_without_tone

```moonbit
pub fn PinyinNormalizer::normalize_to_without_tone(pinyin : String) -> String
```

规范化为无调格式。

### PinyinEditDistance

拼音编辑距离。

#### distance

```moonbit
pub fn PinyinEditDistance::distance(s1 : Array[String], s2 : Array[String]) -> Int
```

音节级 Levenshtein 编辑距离。

#### fuzzy_distance

```moonbit
pub fn PinyinEditDistance::fuzzy_distance(s1 : Array[String], s2 : Array[String]) -> Int
```

模糊编辑距离（模糊等价音节距离为 0）。