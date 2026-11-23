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

## data 包

### common_char_rank

```moonbit
pub fn common_char_rank(ch : String) -> Int32
```

返回汉字在常用字序列中的字节偏移（越小越常用），未收录返回 100000。序列由 `scripts/gen_common_chars.py` 生成：约 500 字高频字序 + GB2312-80 一级汉字 3755 字；输入法候选排序使用。

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

### PinyinStreamProcessor

流式拼音处理器，支持逐字符输入汉字实时输出拼音，适用于输入法等实时场景。

#### new

```moonbit
pub fn PinyinStreamProcessor::new(
  format~ : PinyinFormat = WithToneMark,
  separator~ : String = " ",
) -> PinyinStreamProcessor
```

创建流式拼音处理器。

#### feed

```moonbit
pub fn PinyinStreamProcessor::feed(self : PinyinStreamProcessor, c : Char) -> String
```

输入一个字符，返回增量拼音输出（与上次相比新增的片段）。

#### flush

```moonbit
pub fn PinyinStreamProcessor::flush(self : PinyinStreamProcessor) -> String
```

刷新缓冲区，输出剩余未处理的字符。

#### reset

```moonbit
pub fn PinyinStreamProcessor::reset(self : PinyinStreamProcessor) -> Unit
```

重置处理器，清空缓冲区。

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

拼音模糊匹配，支持 9 组双向规则：zh↔z, ch↔c, sh↔s, n↔l, f↔h, in↔ing, en↔eng, an↔ang, ong↔eng。

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

#### add_fuzzy_rules

```moonbit
pub fn FuzzyPinyinHelper::add_fuzzy_rules(rules : Array[FuzzyRule]) -> Unit
```

追加自定义模糊规则（如方言 r→l）。**全局状态副作用**：修改共享 `fuzzy_rules`，后续 `fuzzy_expand`/`fuzzy_match` 立即生效。

## disambiguate 包

### PinyinDisambiguator

多音字上下文消歧（词表最大匹配 + Viterbi + bigram 词频模型）。

#### disambiguate

```moonbit
pub fn PinyinDisambiguator::disambiguate(text : String) -> Array[String] raise PinyinError
```

多音字上下文消歧，返回每个字的**带调拼音**。句子中出现词表已知词组时先做最大匹配并固定词级读音，其余字符走带调 bigram Viterbi，例如 `"我明天还钱"` → `["wǒ", "míng", "tiān", "huán", "qián"]`。

词级读音优先级：`common_phrases`（151）> pypinyin 大词库（47,110）> `mutil_pinyin_table`（843）。

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

声调变调规则（三声变调/一变调/不变调/七变调/八变调）。

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

## lm 包

### PinyinLM

N-gram 语言模型，从 data 包字典自动构建频率表，提供概率查询与困惑度评估。

#### unigram_prob

```moonbit
pub fn PinyinLM::unigram_prob(pinyin : String) -> Double
```

查询 unigram 概率。使用 Laplace 平滑：P(w) = (C(w) + 1) / (N + V)，其中 C(w) 为该音节频率，N 为总音节数，V 为词汇表大小。

#### bigram_prob

```moonbit
pub fn PinyinLM::bigram_prob(prev : String, curr : String) -> Double
```

查询 bigram 概率 P(curr|prev)。Katz 回退条件：当 C(prev, curr) ≥ 阈值时使用折扣估计，否则回退到 α(prev) × P(curr)（unigram）。

#### trigram_prob

```moonbit
pub fn PinyinLM::trigram_prob(p2 : String, p1 : String, curr : String) -> Double
```

查询 trigram 概率 P(curr|p2,p1)。Katz 回退条件：当 C(p2,p1,curr) ≥ 阈值时使用折扣估计，否则回退到 α(p2,p1) × P(curr|p1)（bigram），逐级降级到 unigram。

#### sentence_log_prob

```moonbit
pub fn PinyinLM::sentence_log_prob(pinyin_array : Array[String]) -> Double
```

计算句子 bigram 对数概率：log P(s) = Σ log P(w_i | w_{i-1})。

#### sentence_log_prob_trigram

```moonbit
pub fn PinyinLM::sentence_log_prob_trigram(pinyin_array : Array[String]) -> Double
```

计算句子 trigram 对数概率：log P(s) = Σ log P(w_i | w_{i-2}, w_{i-1})。

#### perplexity

```moonbit
pub fn PinyinLM::perplexity(sentences : Array[Array[String]]) -> Double
```

计算 bigram 困惑度：PP = exp(-1/N × Σ log P(w_i | w_{i-1}))，N 为总音节数。

#### perplexity_trigram

```moonbit
pub fn PinyinLM::perplexity_trigram(sentences : Array[Array[String]]) -> Double
```

计算 trigram 困惑度：PP = exp(-1/N × Σ log P(w_i | w_{i-2}, w_{i-1}))。

#### stats

```moonbit
pub fn PinyinLM::stats() -> LMStats
```

返回语言模型统计信息。

### LMStats

```moonbit
pub struct LMStats {
  vocab_size : Int32
  unigram_total : Int32
  bigram_total : Int32
  trigram_total : Int32
  unigram_types : Int32
  bigram_types : Int32
  trigram_types : Int32
}
```

语言模型统计信息：词汇表大小、各阶 n-gram 总频次与类型数。

### unigram_freq

```moonbit
pub let unigram_freq : Map[String, Int32]
```

unigram 频率表（从 data 包字典自动构建）。

### bigram_freq

```moonbit
pub let bigram_freq : Map[String, Map[String, Int32]]
```

bigram 频率表（从 data 包字典自动构建，嵌套 Map 结构）。

## shuangpin 包

### ShuangpinScheme

双拼方案：`Xiaohe`（小鹤）、`Ziranma`（自然码）。

#### from_name

```moonbit
pub fn ShuangpinScheme::from_name(name : String) -> ShuangpinScheme?
```

从 `"xiaohe"`/`"小鹤"`、`"ziranma"`/`"自然码"` 解析方案。

#### from_full

```moonbit
pub fn ShuangpinScheme::from_full(self, syllable : String) -> String
```

全拼音节 → 双拼音节（声母键 + 韵母键）；零声母原样返回。

#### to_full

```moonbit
pub fn ShuangpinScheme::to_full(self, input : String) -> String
```

双拼串（每音节 2 键）→ 空格分隔全拼；奇数长度或未知键位原样返回。

#### name

```moonbit
pub fn ShuangpinScheme::name(self) -> String
```

方案展示名。

## input 包

### PinyinInputEngine

拼音输入法引擎，基于 Beam Search 解码 + LM 评分，支持全拼、简拼、双拼、词组候选与用户学习。

算法流程：分词（segment）→ 反查（reverse）→ 常用字优先 → Beam Search + LM 剪枝 → 词组合并/去重 → 用户学习重排。时间复杂度 O(S×B×C)，S=音节数、B=beam 宽度、C=单音节最大候选数。

#### new

```moonbit
pub fn PinyinInputEngine::new() -> PinyinInputEngine
```

创建输入法引擎，默认 beam 宽度 10。

#### with_beam_width

```moonbit
pub fn PinyinInputEngine::with_beam_width(beam_width : Int32) -> PinyinInputEngine
```

创建指定 beam 宽度的输入法引擎。

#### set_beam_width

```moonbit
pub fn PinyinInputEngine::set_beam_width(self, w : Int32) -> Unit
```

动态设置 beam 宽度。

#### beam_width

```moonbit
pub fn PinyinInputEngine::beam_width(self) -> Int32
```

获取当前 beam 宽度。

#### input

```moonbit
pub fn PinyinInputEngine::input(self, pinyin_str : String) -> Array[InputCandidate] raise PinyinError
```

主输入接口：对拼音串执行最优分词 → 反查 → Beam Search，返回排序后的候选列表。无效拼音抛 `PinyinError`。

#### input_from_segments

```moonbit
pub fn PinyinInputEngine::input_from_segments(self, segments : Array[String]) -> Array[InputCandidate] raise PinyinError
```

从已有音节序列直接执行 Beam Search（跳过分词步骤）。空 segments 抛 `PinyinError`。

#### input_all_segments

```moonbit
pub fn PinyinInputEngine::input_all_segments(self, pinyin_str : String) -> Array[InputCandidate] raise PinyinError
```

全切分路径输入：对拼音串执行全切分，对每种切分方案分别执行 Beam Search，合并去重后返回候选列表。

#### input_with_limit

```moonbit
pub fn PinyinInputEngine::input_with_limit(self, pinyin_str : String, limit : Int32) -> Array[InputCandidate] raise PinyinError
```

限定候选数量的输入接口，返回最多 `limit` 个候选。`limit < 1` 抛 `PinyinError`。

#### input_shuangpin

```moonbit
pub fn PinyinInputEngine::input_shuangpin(self, scheme : ShuangpinScheme, input : String) -> Array[InputCandidate] raise PinyinError
```

双拼输入：先转为全拼，再执行标准解码。空串抛 `PinyinError`。

#### input_initial

```moonbit
pub fn PinyinInputEngine::input_initial(self, initials : String) -> Array[InputCandidate]
```

简拼输入：词组首字母串（如 `"zg"`、`"srf"`）→ 词组候选，支持前缀匹配。

#### learn

```moonbit
pub fn PinyinInputEngine::learn(self, text : String) -> Unit
```

记录一次用户选择；学习过的候选在后续排序中优先。

#### set_scoring_config

```moonbit
pub fn PinyinInputEngine::set_scoring_config(self, config : InputScoringConfig) -> Unit
```

运行时调整评分策略（用户词库加分 / 词组加分 / 每音节候选上限）。

#### scoring_config

```moonbit
pub fn PinyinInputEngine::scoring_config(self) -> InputScoringConfig
```

获取当前评分配置。

### InputCandidate

```moonbit
pub(all) struct InputCandidate {
  text : String
  score : Double
  segments : Array[String]
}
```

输入法候选结构：`text` 为候选汉字文本，`score` 为 LM 对数概率评分（越高越好），`segments` 为对应的拼音音节切分。同分候选按汉字常用度排序，文本去重。

### InputScoringConfig

```moonbit
pub(all) struct InputScoringConfig {
  user_dict_bonus : Double
  phrase_bonus : Double
  candidate_limit : Int32
}
```

输入法评分配置：用户词库加分（默认 10.0）、内置词组加分（默认 5.0）、每音节候选汉字上限（默认 20）。