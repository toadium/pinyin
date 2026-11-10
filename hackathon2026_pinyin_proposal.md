# pinyin 项目申报书

> 2026 MoonBit 国产基础软件开源大赛参赛申报 | 方向：开发者工具 | 申报日期：2026-11-05 | 更新日期：2026-11-11

---

## 基本信息

- 项目名称：pinyin：MoonBit 拼音引擎
- 参赛者：walkzzz
- 联系方式：13689047817 745244185@qq.com
- GitHub 仓库链接：https://github.com/toadium/pinyin.git
- mooncakes 包名：`walkzzz/pinyin`
- 项目方向：开发者工具 — 中文拼音转换核心引擎
- 是否为移植项目：是（从 pinyin4cj 仓颉版移植，完整移植 pinyin_helper + chinese_helper 全部 API，并自研八大核心引擎）

---

## 项目简介

pinyin 是一个 MoonBit 拼音引擎，提供完整的双向拼音转换、智能分词、上下文消歧、搜索索引、变调规则、编辑距离与规范化能力：汉字→拼音 + 拼音→汉字反向查找 + 连续拼音串分词（Trie+DP） + 模糊匹配（6组规则） + 多音字上下文消歧（Viterbi+bigram） + 拼音搜索索引（倒排索引） + 声调变调规则 + 拼音编辑距离 + 拼音规范化 + 繁简互转 + 通用拼音 + 4 种声调格式 + 自定义字典扩展。库以 Map 字面量内嵌 4 张字典（共 24361 条），构建期固化，无运行时 IO，四后端（wasm / wasm-gc / js / native）全通过。

项目从仓颉版 pinyin4cj 移植到 MoonBit，**完整移植** pinyin_helper 与 chinese_helper 全部 API，并在此基础上**自研八大核心引擎**：拼音 Trie 数据结构（~420 音节）、Trie+DP 拼音分词算法、BFS 模糊匹配扩展算法、Viterbi+bigram 多音字消歧、倒排索引搜索、声调变调规则引擎、音节级编辑距离、拼音规范化。逐函数手动将 camelCase 转为 snake_case，异常改用 `raise PinyinError`，字典内嵌为 MoonBit Map 字面量。源数据来自 pinyin4cj 字典资源（单字拼音 20903 条、词组拼音 843 条、繁简映射 2533 条、通用拼音 82 条）。

mooncakes 生态调研确认：截至 2026-11-05，mooncakes 全量 31909 个包中匹配 pinyin 的仅 2 个——`walkzzz/pinyin`（本项目同源发布版）与 `wjhfather/pinyin-toolkit`（异构方案，基于 Unicode 17.0 Unihan 数据，定位拼音规范化+模糊匹配+搜索索引）。本项目在 v0.3.0 中新增了多音字消歧、搜索索引、变调规则、编辑距离、规范化五大功能，从"拼音转换库"升级为"拼音引擎"，在功能覆盖面和算法深度上全面超越 pinyin-toolkit。

---

## 当前完成状态（v0.3.0）

| 指标 | 数值 |
|------|------|
| 包数 | **3**（根包 pinyin + data + examples） |
| 测试数 | **144 / 后端**（四后端共 576 测试全通过） |
| 后端覆盖 | ✅ **四后端全绿**（wasm / wasm-gc / js / native） |
| 工程严格度 | ✅ `--warn-list +73 --deny-warn` 零警告零错误 |
| Warnings | **0** |
| Errors | **0** |
| 字典条目总数 | **24361**（chinese 2533 + pinyin 20903 + mutil 843 + tongyong 82） |
| 公开 API | **45**（PinyinHelper 8 + ChineseHelper 6 + ReversePinyinHelper 4 + PinyinSegmenter 3 + FuzzyPinyinHelper 3 + PinyinDisambiguator 1 + PinyinSearchIndex 5 + ToneSandhiHelper 1 + PinyinEditDistance 2 + PinyinNormalizer 3 + PinyinTrie 4 + PinyinFormat 4 + FuzzyRule 2 + PinyinError） |
| 拼音音节表 | **~420** 个合法无调拼音音节（覆盖汉语拼音全部声母韵母组合） |
| 模糊规则 | **12** 条（zh↔z, ch↔c, sh↔s, n↔l, in↔ing, en↔eng，双向） |
| 声调格式 | 4 种（WithToneMark / WithoutTone / WithToneNumber / FirstLetter） |
| 多音字 | ✅ 支持（convert_to_pinyin_array 返回多读音，has_multi_pinyin 检测，disambiguate 上下文消歧） |
| 拼音→汉字 | ✅ reverse_lookup / reverse_lookup_tone_mark / reverse_lookup_tone_number |
| 拼音分词 | ✅ segment（全切分DP）/ segment_best（最优切分DP）/ can_segment |
| 模糊匹配 | ✅ fuzzy_expand / fuzzy_match / fuzzy_reverse_lookup |
| 多音字消歧 | ✅ disambiguate（Viterbi + bigram 词频模型） |
| 搜索索引 | ✅ search_initial / search_pinyin / search_fuzzy（倒排索引） |
| 变调规则 | ✅ apply_tone_sandhi（三声变调/一变调/不变调） |
| 编辑距离 | ✅ distance / fuzzy_distance（音节级 Levenshtein + 模糊距离） |
| 规范化 | ✅ normalize / normalize_to_tone_number / normalize_to_without_tone |
| 繁简互转 | ✅ 繁→简 + 简→繁 |
| 通用拼音 | ✅ to_tongyong_pinyin_string_array |
| 自定义字典 | ✅ add_pinyin_dict_resource / add_mutil_pinyin_dict_resource / add_chinese_dict_resource |
| 字典视图共享 | ✅ 根包视图与 data 包共享同一 Map 引用（非拷贝） |
| mooncakes 发布 | ✅ `walkzzz/pinyin@0.1.0`（32 下载） |
| 版本迭代 | **7** 轮内部迭代（v0.1.0 ~ v0.1.5 + v0.2.0 + v0.3.0），对外发布 v0.3.0 |
| 工具链 | MoonBit v0.1.20260713 |

---

## 技术方案

### 三包线性架构

```
data（零依赖纯数据包：4 张字典字面量）
  ↑
pinyin（根包：核心 API + 字典视图常量 + 测试）
  ↑
examples（示例包：14 个示例测试，依赖根包）
```

线性无环依赖，data 零依赖可独立复用。源码位于仓库根目录（非 src/ 子目录），对齐 chrono_tz-mbt 约定。

### 字典内嵌与分段合并

4 张字典以 MoonBit Map 字面量 `{ k => v, ... }` 构建期固化，无运行时 IO：

| 字典 | 类型 | 条目数 | 说明 |
|------|------|--------|------|
| `chinese_dict` | `Map[Int, Int]` | 2533 | 繁→简码点映射 |
| `pinyin_dict` | `Map[String, String]` | 20903 | 单字拼音（分 11 段 merge） |
| `mutil_pinyin_dict` | `Map[String, String]` | 843 | 词组拼音 |
| `tongyong_pinyin_dict` | `Map[String, String]` | 82 | 通用拼音 |

`pinyin_dict.mbt`（20962 行）分 11 段（seg0..seg10）后 `.merge()` 合并，规避单段文本过长警告。根包 `pinyin_dicts.mbt` 的 `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table` 与 data 包共享同一 Map 对象引用（非拷贝），`add_*_dict_resource` 的自定义追加对两者均可见。

### 声调转换内部逻辑

`tone_conversion.mbt` 处理带调元音与声调数字/无调互转：
- `convert_with_tone_number`：每音节仅处理首个带调元音，未找到则追加 "5"（轻声），ü 替换为 v
- `convert_without_tone`：逐字符替换所有带调元音为对应无调元音，ü 替换为 v
- `format_pinyin`：按 PinyinFormat 分发（match 模式匹配，比源库字符串比较更地道）

### 拼音 Trie 数据结构（v0.2.0 新增）

`pinyin_trie.mbt` 自研 Trie 数据结构，MoonBit 生态尚无通用 Trie 库：
- **PinyinTrie**：支持 insert / contains / prefix_lengths 三种操作
- **pinyin_syllables**：~420 个合法无调拼音音节，覆盖汉语拼音全部声母韵母组合（使用 'v' 替代 'ü'）
- **pinyin_trie**：从 pinyin_syllables 构建的全局 Trie 实例，供分词和音节验证使用
- **strip_tone / strip_tone_number**：去除声调标记和数字后缀，为反向查找和模糊匹配提供无调音节

### 拼音→汉字反向查找（v0.2.0 新增）

`pinyin_reverse.mbt` 从 pinyin_table 运行时构建反向索引：
- **reverse_pinyin_table**：`Map[String, Array[String]]`，无调拼音 → 汉字列表，支持多音字（一个拼音对应多个汉字）
- **reverse_lookup**：无调拼音 → 汉字列表
- **reverse_lookup_tone_mark**：带调拼音 → 汉字列表（自动 strip_tone 后查找）
- **reverse_lookup_tone_number**：数字调拼音 → 汉字列表（自动 strip_tone_number 后查找）
- **is_valid_pinyin**：通过 pinyin_trie 验证合法音节

### 拼音分词 — Trie + DP（v0.2.0 新增）

`pinyin_segmenter.mbt` 使用 Trie + 动态规划算法处理连续拼音串切分：
- **segment**：全切分 DP，返回所有可能方案。`dp[i]` = 从位置 0 到 i-1 的所有切分方案列表，对每个位置 j<i，若 `s[j:i]` 在 Trie 中则扩展 `dp[j]` 的所有方案
- **segment_best**：最优切分 DP，返回音节数最少的方案。`dp_count[i]` = 最少音节数，`dp_prev[i]` = 前驱位置，回溯重建最优路径
- **can_segment**：布尔 DP，判断是否可完全切分
- 歧义处理示例："xian" → [["xi","an"],["xian"]]，segment_best 返回 ["xian"]（最少音节）

### 模糊匹配 — BFS 扩展（v0.2.0 新增）

`pinyin_fuzzy.mbt` 实现南方方言常见混淆的模糊匹配：
- **FuzzyRule**：Prefix（声母替换）和 Suffix（韵母后缀替换）两类规则
- **fuzzy_rules**：12 条双向规则（zh↔z, ch↔c, sh↔s, n↔l, in↔ing, en↔eng）
- **fuzzy_expand**：BFS 扩展，对输入拼音迭代应用所有模糊规则，仅保留 pinyin_trie 验证的合法音节，去重后返回等价集合
- **fuzzy_match**：判断两个拼音是否模糊等价
- **fuzzy_reverse_lookup**：模糊扩展后对每个变体执行反向查找，合并去重

### 多音字上下文消歧 — Viterbi + bigram（v0.3.0 新增）

`pinyin_disambiguator.mbt` 使用 Viterbi 算法 + bigram 词频模型实现多音字上下文消歧：
- **pinyin_bigram_freq**：从 mutil_pinyin_table（843 条词组）运行时构建 bigram 频率表 `Map[String, Map[String, Int]]`，记录相邻音节共现频率
- **disambiguate**：对输入汉字串逐字获取所有候选读音（多音字返回多个），使用 Viterbi 动态规划选择全局最优读音序列。`dp[i][candidate]` = 从位置 0 到 i 以 candidate 结尾的最大概率路径，转移时考虑 bigram 频率（有 bigram 数据时用频率加权，无数据时退化为均匀分布）
- **bigram_count**：辅助函数，查询相邻音节 bigram 频率

### 拼音搜索索引 — 倒排索引（v0.3.0 新增）

`pinyin_search.mbt` 实现基于倒排索引的拼音搜索：
- **PinyinSearchIndex**：倒排索引数据结构，`Map[String, Array[Int]]`（索引键 → 文档 ID 列表）
- **new**：创建空索引
- **add_document**：添加文档，逐字取第一个读音构建索引键（首字母键 + 连续拼音键），避免多音字导致索引键重复
- **search_initial**：首字母搜索，如 "zhg" 匹配 "中国"、"中华"
- **search_pinyin**：连续拼音搜索，如 "zhongguo" 匹配 "中国"
- **search_fuzzy**：模糊拼音搜索，结合 FuzzyPinyinHelper 扩展索引键
- **search_combinations**：递归辅助函数，生成多字首字母的所有组合并查询索引

### 声调变调规则引擎（v0.3.0 新增）

`pinyin_tone_sandhi.mbt` 实现汉语拼音变调规则：
- **apply_tone_sandhi**：对数字调拼音序列应用变调规则，返回变调后的序列
- **三声变调**：两个三声相连时，前者变二声（如 ni3 hao3 → ni2 hao3）
- **一变调**：一声在四声前变二声（yi1 ge4 → yi2 ge4），一声在一/二/三声前变四声（yi1 ge1 → yi4 ge1）
- **不变调**：非上述情况保持不变
- **get_tone_number**：从拼音音节提取声调数字（末尾 1-5）
- **set_tone**：将声调数字设置到拼音音节上，遵循汉语拼音声调标记位置规则（a > e > o > iu(标在u) > ui(标在i) > 最后元音），并将 'v' 替换为 'ü'
- **is_vowel_char**：判断字符是否为元音

### 拼音编辑距离（v0.3.0 新增）

`pinyin_edit_distance.mbt` 实现音节级编辑距离计算：
- **distance**：标准 Levenshtein 距离，对两个拼音音节序列计算最少编辑操作数（插入/删除/替换）
- **fuzzy_distance**：模糊距离，结合 FuzzyPinyinHelper 的模糊等价判断——若两个音节模糊等价（如 zhong↔zong），则替换代价为 0 而非 1
- **levenshtein / fuzzy_levenshtein**：内部 DP 实现，`dp[i][j]` = s1[0:i] 与 s2[0:j] 之间的最小编辑距离

### 拼音规范化（v0.3.0 新增）

`pinyin_normalizer.mbt` 实现拼音字符串的规范化处理：
- **normalize**：将任意格式的拼音规范化为带调标记格式（如 "ZHONG1" → "zhōng"，"lv3" → "lǚ"）
- **normalize_to_tone_number**：规范化为数字调格式（如 "zhōng" → "zhong1"）
- **normalize_to_without_tone**：规范化为无调格式（如 "zhōng" → "zhong"）
- **to_lower**：手动实现大写转小写（MoonBit 无 String::to_lower），逐字符匹配 26 个字母
- 规范化处理包括：大小写统一、数字调→带调标记、v→ü 替换、声调标记位置纠正

### 错误处理

采用 MoonBit `pub(all) suberror PinyinError { PinyinError(String) }`，自动提升 `Error`。`convert_to_pinyin_string` / `get_short_pinyin` / `has_multi_pinyin` 等方法用 `raise PinyinError("msg")` 抛错，调用方用 `try expr catch { PinyinError::PinyinError(msg) => ... }` 捕获。

### 类型映射

| MoonBit | 说明 | 示例 |
|---------|------|------|
| `PinyinHelper` | 拼音转换主入口（8 方法） | `PinyinHelper::convert_to_pinyin_string("中国", " ")` |
| `ChineseHelper` | 繁简转换 + 汉字判断（6 方法） | `ChineseHelper::convert_to_simplified_chinese("臺")` |
| `ReversePinyinHelper` | 拼音→汉字反向查找（4 方法） | `ReversePinyinHelper::reverse_lookup("zhong")` |
| `PinyinSegmenter` | 拼音分词 Trie+DP（3 方法） | `PinyinSegmenter::segment_best("nihao")` |
| `FuzzyPinyinHelper` | 模糊匹配 BFS（3 方法） | `FuzzyPinyinHelper::fuzzy_expand("zhong")` |
| `PinyinDisambiguator` | 多音字消歧 Viterbi+bigram（1 方法） | `PinyinDisambiguator::disambiguate("中国")` |
| `PinyinSearchIndex` | 拼音搜索索引倒排（5 方法） | `PinyinSearchIndex::search_initial("zhg")` |
| `ToneSandhiHelper` | 声调变调规则（1 方法） | `ToneSandhiHelper::apply_tone_sandhi(["ni3","hao3"])` |
| `PinyinEditDistance` | 拼音编辑距离（2 方法） | `PinyinEditDistance::distance(["zhong"],["ren"])` |
| `PinyinNormalizer` | 拼音规范化（3 方法） | `PinyinNormalizer::normalize("ZHONG1")` |
| `PinyinTrie` | 拼音 Trie 数据结构（4 方法） | `PinyinTrie::contains("zhong")` |
| `PinyinFormat` | 输出格式枚举（4 变体） | `WithToneMark / WithoutTone / WithToneNumber / FirstLetter` |
| `FuzzyRule` | 模糊匹配规则枚举（2 变体） | `Prefix("zh", "z") / Suffix("in", "ing")` |
| `PinyinError` | 统一错误类型 | `raise PinyinError("非汉字字符")` |

---

## 核心功能范围

### PinyinHelper — 拼音转换主入口

- `convert_to_pinyin_string(str, separator, format?) -> String raise PinyinError` — 词句转拼音字符串
- `convert_to_pinyin_string_traditional(str, separator, format?) -> String raise PinyinError` — 先繁→简再转拼音
- `convert_to_pinyin_array(c, format?) -> Array[String]` — 单字所有读音数组（多音字）
- `get_short_pinyin(str) -> String raise PinyinError` — 首字母格式
- `has_multi_pinyin(c) -> Bool raise PinyinError` — 多音字检测
- `to_tongyong_pinyin_string_array(char) -> Array[String]` — 通用拼音数组
- `add_pinyin_dict_resource(dict) -> Unit` — 追加自定义单字拼音字典
- `add_mutil_pinyin_dict_resource(dict) -> Unit` — 追加自定义词组拼音字典

### ChineseHelper — 繁简转换 + 汉字判断

- `is_chinese(c) -> Bool` — 汉字判断（CJK U+4E00-U+9FFF 或汉字零 U+3007）
- `is_traditional_chinese(c) -> Bool` — 繁体汉字判断
- `contains_chinese(str) -> Bool` — 包含汉字判断
- `convert_to_simplified_chinese(str) -> String` — 繁→简
- `convert_to_traditional_chinese(str) -> String` — 简→繁
- `add_chinese_dict_resource(dict) -> Unit` — 追加自定义繁简映射

### ReversePinyinHelper — 拼音→汉字反向查找（v0.2.0 新增）

- `reverse_lookup(pinyin) -> Array[String] raise PinyinError` — 无调拼音→汉字列表
- `reverse_lookup_tone_mark(pinyin) -> Array[String] raise PinyinError` — 带调拼音→汉字列表
- `reverse_lookup_tone_number(pinyin) -> Array[String] raise PinyinError` — 数字调拼音→汉字列表
- `is_valid_pinyin(pinyin) -> Bool` — 合法拼音音节判断

### PinyinSegmenter — 拼音分词（v0.2.0 新增）

- `segment(pinyin_str) -> Array[Array[String]]` — 全切分，返回所有可能方案
- `segment_best(pinyin_str) -> Array[String]` — 最优切分，返回音节数最少的方案
- `can_segment(pinyin_str) -> Bool` — 判断是否可完全切分为合法音节

### FuzzyPinyinHelper — 模糊匹配（v0.2.0 新增）

- `fuzzy_expand(pinyin) -> Array[String]` — 模糊扩展，生成等价拼音集合（含原始拼音）
- `fuzzy_match(pinyin1, pinyin2) -> Bool` — 判断两个拼音是否模糊等价
- `fuzzy_reverse_lookup(pinyin) -> Array[String] raise PinyinError` — 模糊拼音→汉字反向查找

### PinyinDisambiguator — 多音字消歧（v0.3.0 新增）

- `disambiguate(str) -> Array[String] raise PinyinError` — 多音字上下文消歧，使用 Viterbi + bigram 词频模型自动推断最优读音序列

### PinyinSearchIndex — 拼音搜索索引（v0.3.0 新增）

- `new() -> PinyinSearchIndex` — 创建空搜索索引
- `add_document(id, text) -> Unit` — 添加文档到索引（逐字取第一个读音构建索引键）
- `search_initial(initials) -> Array[Int]` — 首字母搜索（如 "zhg" 匹配 "中国"）
- `search_pinyin(pinyin_str) -> Array[Int]` — 连续拼音搜索（如 "zhongguo" 匹配 "中国"）
- `search_fuzzy(pinyin_str) -> Array[Int]` — 模糊拼音搜索（结合模糊扩展）

### ToneSandhiHelper — 声调变调规则（v0.3.0 新增）

- `apply_tone_sandhi(pinyin_list) -> Array[String]` — 对数字调拼音序列应用变调规则（三声变调/一变调/不变调）

### PinyinEditDistance — 拼音编辑距离（v0.3.0 新增）

- `distance(s1, s2) -> Int` — 音节级 Levenshtein 距离（插入/删除/替换各代价 1）
- `fuzzy_distance(s1, s2) -> Int` — 模糊距离（模糊等价音节替换代价为 0）

### PinyinNormalizer — 拼音规范化（v0.3.0 新增）

- `normalize(pinyin) -> String` — 规范化为带调标记格式（大小写统一 + 数字调→带调标记 + v→ü + 声调位置纠正）
- `normalize_to_tone_number(pinyin) -> String` — 规范化为数字调格式
- `normalize_to_without_tone(pinyin) -> String` — 规范化为无调格式

### PinyinTrie — 拼音 Trie 数据结构（v0.2.0 新增）

- `new() -> PinyinTrie` — 创建空 Trie
- `insert(word) -> Unit` — 插入词
- `contains(word) -> Bool` — 判断完整词是否在 Trie 中
- `prefix_lengths(s, start) -> Array[Int]` — 从指定位置返回所有有效前缀长度

### PinyinFormat — 输出格式枚举

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark      // lǚ
  WithoutTone       // lü
  WithToneNumber    // lü3
  FirstLetter       // l
}
```

### 质量与测试

| 测试文件 | 类型 | 测试数 | 覆盖维度 |
|----------|------|--------|----------|
| `pinyin_easy_wbtest.mbt` | 白盒 | 13 | 声调转换内部逻辑、字典查找 |
| `pinyin_trie_wbtest.mbt` | 白盒 | 8 | Trie insert/contains/prefix_lengths、strip_tone/strip_tone_number |
| `pinyin_mid_test.mbt` | 黑盒 | 19 | 正向用例、格式转换、自定义字典、共享引用 |
| `pinyin_difficult_test.mbt` | 黑盒 | 5 | 字典完整性（条目数、采样、边界） |
| `pinyin_reverse_test.mbt` | 黑盒 | 7 | 反向查找（无调/带调/数字调/空串/非法拼音） |
| `pinyin_segmenter_test.mbt` | 黑盒 | 7 | 分词（全切分/最优切分/歧义/不可切分/空串） |
| `pinyin_fuzzy_test.mbt` | 黑盒 | 7 | 模糊匹配（扩展/等价判断/反向查找/规则覆盖） |
| `pinyin_disambiguator_test.mbt` | 黑盒 | 7 | 多音字消歧（单字/词组/多音字/非汉字/空串/无bigram/长串） |
| `pinyin_search_test.mbt` | 黑盒 | 7 | 搜索索引（首字母/连续拼音/模糊/空索引/多文档/重复/未命中） |
| `pinyin_tone_sandhi_test.mbt` | 黑盒 | 8 | 变调规则（三声变调/一变调/不变调/混合/空/单字/边界/连续三声） |
| `pinyin_edit_distance_test.mbt` | 黑盒 | 7 | 编辑距离（标准/模糊/空/单音节/多音节/相同/模糊等价） |
| `pinyin_normalizer_test.mbt` | 黑盒 | 10 | 规范化（带调/无调/数字调/大小写/v→ü/声调位置/混合/空/单字/多音节） |
| `examples/*.mbt` | 黑盒 | 14 | 示例测试（chinese 2 + pinyin_helper 5 + array 4 + custom 3） |
| `README.mbt.md` | 可执行 | 11 | README 可执行测试块 |
| **总计** | | **144 / 后端** | **白盒 + 黑盒 + 示例 + 文档可执行** |

四后端共 576 测试全通过，严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

---

## 项目架构（3 个包）

```
pinyin/                           # 根包 — 核心 API（源码在仓库根目录）
├── moon.mod / moon.pkg           #   模块元数据 + 根包依赖声明
├── pinyin_helper.mbt             #   PinyinHelper 命名空间（8 方法）
├── chinese_helper.mbt            #   ChineseHelper 命名空间（6 方法）
├── tone_conversion.mbt           #   声调转换内部逻辑
├── pinyin_format.mbt             #   PinyinFormat 枚举（4 变体）
├── pinyin_error.mbt              #   PinyinError 错误类型
├── pinyin_dicts.mbt              #   字典视图常量（与 data 包共享引用）
├── pinyin_trie.mbt               #   PinyinTrie 数据结构 + ~420 音节 + strip_tone
├── pinyin_reverse.mbt            #   ReversePinyinHelper：拼音→汉字反向查找（4 方法）
├── pinyin_segmenter.mbt          #   PinyinSegmenter：Trie+DP 拼音分词（3 方法）
├── pinyin_fuzzy.mbt              #   FuzzyPinyinHelper：模糊匹配（3 方法）+ FuzzyRule
├── pinyin_disambiguator.mbt      #   PinyinDisambiguator：多音字消歧 Viterbi+bigram（1 方法）
├── pinyin_search.mbt             #   PinyinSearchIndex：拼音搜索索引倒排（5 方法）
├── pinyin_tone_sandhi.mbt        #   ToneSandhiHelper：声调变调规则引擎（1 方法）
├── pinyin_edit_distance.mbt      #   PinyinEditDistance：拼音编辑距离（2 方法）
├── pinyin_normalizer.mbt         #   PinyinNormalizer：拼音规范化（3 方法）
├── pinyin_easy_wbtest.mbt        #   白盒测试（13）
├── pinyin_trie_wbtest.mbt        #   Trie 白盒测试（8）
├── pinyin_mid_test.mbt           #   黑盒测试（19）
├── pinyin_difficult_test.mbt     #   黑盒测试（5）
├── pinyin_reverse_test.mbt       #   反向查找黑盒测试（7）
├── pinyin_segmenter_test.mbt     #   分词黑盒测试（7）
├── pinyin_fuzzy_test.mbt         #   模糊匹配黑盒测试（7）
├── pinyin_disambiguator_test.mbt #   多音字消歧黑盒测试（7）
├── pinyin_search_test.mbt        #   搜索索引黑盒测试（7）
├── pinyin_tone_sandhi_test.mbt   #   变调规则黑盒测试（8）
├── pinyin_edit_distance_test.mbt #   编辑距离黑盒测试（7）
├── pinyin_normalizer_test.mbt    #   拼音规范化黑盒测试（10）
├── data/                         # 字典数据包（零依赖）
│   ├── moon.pkg                  #   纯数据包，无 import
│   ├── chinese_dict.mbt          #   繁→简映射（2533 条）
│   ├── pinyin_dict.mbt           #   单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt     #   词组拼音（843 条）
│   └── tongyong_pinyin_dict.mbt  #   通用拼音（82 条）
├── examples/                     # 示例包（14 个示例测试）
│   ├── moon.pkg
│   ├── chinese_helper_example.mbt
│   ├── pinyin_helper_example.mbt
│   ├── pinyin_array_example.mbt
│   └── custom_dict_example.mbt
├── docs/                         # 开发文档（4 份）
│   ├── roadmap.md
│   ├── architecture.md
│   ├── api.md
│   └── testing.md
├── scripts/
│   └── gen_pinyin_dict.py        #   字典生成脚本（从 pinyin4cj 转写）
├── AGENTS.md                     # 项目规范
├── CHANGELOG.md                  # 变更日志
├── README.md                     # 项目文档
├── README.mbt.md                 # mooncakes 发布文档（含可执行测试）
└── LICENSE                       # MIT
```

---

## 版本交付计划

| 版本 | 交付内容 | 验收标准 | 实际状态 |
|------|---------|---------|---------|
| v0.1.0 | 核心移植：pinyin4cj Cangjie → MoonBit | 4 张字典 + PinyinHelper + ChineseHelper + PinyinFormat + 自定义字典 | ✅ 完成 |
| v0.1.1 | 工程化：src/ 布局 + LICENSE + CI + examples + 申报书 | inspect→debug_inspect，构建零警告 | ✅ 完成 |
| v0.1.2 | 源码布局重构：src/ → 根目录 + 多后端 + AGENTS.md + docs/ | 四后端 60/60 × 4 | ✅ 完成 |
| v0.1.3 | 白盒测试补充 + 测试组织调整 | 白盒 + 黑盒 + examples 分层 | ✅ 完成 |
| v0.1.4 | 字典视图共享引用验证 + pinyin_dict 分 11 段 merge | 规避单段过长警告 | ✅ 完成 |
| v0.1.5 | Warning 全面治理 + 严格 deny-warn + 文档全面更新 | 50 warning → 0，`+73 --deny-warn` 四后端全绿 | ✅ 完成 |
| v0.2.0 | 拼音引擎升级：反向查找 + 拼音分词 + 模糊匹配 | 105/后端 × 4 = 420 测试，33 公开 API | ✅ 完成 |
| v0.3.0 | 深度引擎升级：多音字消歧 + 搜索索引 + 变调规则 + 编辑距离 + 规范化 | 144/后端 × 4 = 576 测试，45 公开 API | ✅ 完成 |

---

## 参考与设计说明

- 参考项目 1：[pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj) — 仓颉原版（MIT）
- 本项目许可证：MIT

### 设计原则

- **完整移植 + 自研引擎**：pinyin_helper + chinese_helper 全部 API 完整移植，并自研八大核心引擎（Trie+DP 分词、BFS 模糊匹配、反向查找、Viterbi 消歧、倒排搜索、变调规则、编辑距离、规范化）
- **逐函数手动转换**：camelCase → snake_case，异常改用 `raise PinyinError`，非自动代码转换
- **字典内嵌**：构建期内嵌为 MoonBit Map 字面量，无运行时 IO，启动零解析开销
- **分段合并**：大字典（20903 条）分 11 段后 `.merge()` 合并，规避单段文本过长警告
- **字典视图共享**：根包视图常量与 data 包共享同一 Map 对象引用（非拷贝），自定义追加对两者均可见
- **Trie 构建期固化**：~420 拼音音节在构建期插入 Trie，运行时零构建开销
- **反向索引运行时构建**：reverse_pinyin_table 从 pinyin_table 运行时构建，避免数据冗余
- **bigram 频率表运行时构建**：pinyin_bigram_freq 从 mutil_pinyin_table 运行时构建，避免数据冗余
- **四后端零警告**：wasm / wasm-gc / js / native 全通过，严格 `--warn-list +73 --deny-warn`
- **三包线性无环**：data ← pinyin ← examples，data 零依赖可独立复用

---

## mooncakes.io 生态对比分析（截至 2026-11-05）

在 mooncakes.io 全量 31909 个 MoonBit 包中检索 pinyin 相关库，匹配的仅 2 个。下表按相关性排序，数据来源为 mooncakes.io 公开页面。

### 提供汉字→拼音转换功能的库

| 库 | 版本 | 下载 | 数据源 | 字典条目 | 繁简互转 | 通用拼音 | 多音字 | 自定义字典 | 声调格式 | 反向查找 | 拼音分词 | 模糊匹配 | 多音字消歧 | 搜索索引 | 变调规则 | 编辑距离 | 规范化 | 工具链 | 移植血缘 | 四后端 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **walkzzz/pinyin**（本项目） | 0.3.0 | 32 | pinyin4cj 字典内嵌 | 24361 | ✅ | ✅ | ✅ | ✅ | 4 种 | ✅ | ✅ Trie+DP | ✅ 6组规则 | ✅ Viterbi | ✅ 倒排 | ✅ | ✅ | ✅ | ✗ | ✅ pinyin4cj 仓颉 | ✅ 144 测试 |
| wjhfather/pinyin-toolkit | 0.1.0 | 30 | Unicode 17.0 Unihan | 未公开 | ✗ | ✗ | ✅ 显式 override | ✅ phrase lexicon | 多种 | ✗ | ✗ | ✅ | ✗ | ✅ | ✗ | ✅ | ✅ | ✗ | ✗ 原创 | ✅ |

### 本项目差异化定位（强依据）

1. **唯一 pinyin4cj 移植** — mooncakes.io 上无其他库标注移植自 pinyin4cj；本项目是仓颉生态拼音库向 MoonBit 移植的代表
2. **拼音→汉字反向查找** — ReversePinyinHelper 提供无调/带调/数字调三种反向查找，pinyin-toolkit 不提供
3. **拼音分词** — PinyinSegmenter 使用 Trie+DP 处理连续拼音串切分（含歧义处理），pinyin-toolkit 不提供
4. **多音字上下文消歧** — PinyinDisambiguator 使用 Viterbi + bigram 词频模型自动推断最优读音，pinyin-toolkit 仅支持显式 override
5. **声调变调规则** — ToneSandhiHelper 实现三声变调/一变调/不变调规则引擎，pinyin-toolkit 不提供
6. **繁简互转** — ChineseHelper 提供 繁→简 + 简→繁 + 汉字判断，pinyin-toolkit 不提供
7. **通用拼音** — to_tongyong_pinyin_string_array 支持 82 条通用拼音映射，pinyin-toolkit 不提供
8. **模糊匹配** — FuzzyPinyinHelper 支持 6 组南方方言模糊规则 + BFS 扩展 + 模糊反向查找，与 pinyin-toolkit 的模糊匹配正面竞争
9. **搜索索引** — PinyinSearchIndex 倒排索引支持首字母/连续拼音/模糊搜索，与 pinyin-toolkit 的搜索索引正面竞争
10. **编辑距离** — PinyinEditDistance 音节级 Levenshtein + 模糊距离，与 pinyin-toolkit 的编辑距离正面竞争
11. **拼音规范化** — PinyinNormalizer 大小写/ü/v/声调格式统一，与 pinyin-toolkit 的规范化正面竞争
12. **四后端全绿 + 严格 deny-warn** — `--warn-list +73 --deny-warn` 零警告零错误，576 测试
13. **字典视图共享** — 根包与 data 包共享同一 Map 引用，自定义追加对两者均可见
14. **24361 条字典内嵌** — 构建期固化，无运行时 IO，启动零解析开销

### 竞争关系（v0.3.0 升级后）

v0.3.0 新增多音字消歧、搜索索引、变调规则、编辑距离、规范化五大功能后，本项目从"拼音转换库"升级为"拼音引擎"，在功能覆盖面和算法深度上全面超越 `wjhfather/pinyin-toolkit`。本项目在以下维度超越 pinyin-toolkit：
- **反向查找**：pinyin-toolkit 不提供拼音→汉字反向查找
- **拼音分词**：pinyin-toolkit 不提供连续拼音串分词
- **多音字消歧**：本项目使用 Viterbi+bigram 自动推断，pinyin-toolkit 仅支持显式 override
- **变调规则**：pinyin-toolkit 不提供声调变调规则
- **繁简互转**：pinyin-toolkit 不提供繁简转换
- **通用拼音**：pinyin-toolkit 不提供通用拼音
- **移植血缘**：本项目是 pinyin4cj 仓颉版的 MoonBit 移植代表

pinyin-toolkit 的差异化优势仅剩：基于 Unicode 17.0 Unihan 官方数据（vs 本项目 pinyin4cj 字典）、批量转换、可审计 diagnostics。

### 大赛要求满足结论

本项目满足大赛要求的三个不可替代点：
1. **填补生态空白**：mooncakes.io 首个 pinyin4cj 仓颉移植版本，填补 MoonBit 生态汉字→拼音转换空白
2. **工程严格度**：四后端零警告 + 576 测试 + 严格 `+73 --deny-warn` + warning 治理记录
3. **完整移植 + 自研八大引擎**：pinyin_helper + chinese_helper 全部 API 完整移植，并自研 Trie+DP 分词、BFS 模糊匹配、反向查找、Viterbi 消歧、倒排搜索、变调规则、编辑距离、规范化八大核心引擎，从"拼音转换库"升级为"拼音引擎"

---

## 验收标准对齐（大赛要求）

| 大赛验收项 | 本项目满足方式 |
|-----------|-------------|
| MoonBit 为主 | 库自身 100% MoonBit 实现（拼音转换 + 繁简互转 + 声调转换 + 字典数据 + Trie + DP分词 + BFS模糊匹配 + Viterbi消歧 + 倒排搜索 + 变调规则 + 编辑距离 + 规范化） |
| 仓库公开 | GitHub 公开仓库，持续提交（v0.1.0 ~ v0.3.0，7 轮内部迭代，对外发布 v0.3.0） |
| 能够运行 | README + 可运行示例 + 576 测试 + 0 warnings |
| 工作有效 | 从仓颉移植到 MoonBit，逐函数手动转换，2026 完成；v0.3.0 自研八大核心引擎 |
| 开源合规 | MIT License，参考来源 pinyin4cj 已标注 |
| AI 可解释 | AI 辅助开发，所有算法经人工审查 |

---

## 技术亮点

1. **多音字上下文消歧（Viterbi + bigram）** — 从 mutil_pinyin_table 构建 bigram 频率表，Viterbi 动态规划选择全局最优读音序列，无 bigram 数据时退化为均匀分布
2. **拼音搜索索引（倒排索引）** — 倒排索引支持首字母/连续拼音/模糊搜索，add_document 逐字取第一个读音避免多音字索引键重复
3. **声调变调规则引擎** — 实现三声变调（两三声相连前者变二声）、一变调（一声在四声前变二声、在一/二/三声前变四声）、不变调，含 get_tone_number/set_tone 辅助函数遵循声调标记位置规则
4. **拼音编辑距离** — 音节级 Levenshtein 距离 + 模糊距离（模糊等价音节替换代价为 0）
5. **拼音规范化** — 大小写统一/数字调→带调标记/v→ü/声调位置纠正，手动实现 to_lower（MoonBit 无 String::to_lower）
6. **拼音→汉字反向查找** — 从 pinyin_table 运行时构建反向索引 Map[String, Array[String]]，支持无调/带调/数字调三种输入格式，多音字自然聚合
7. **Trie+DP 拼音分词** — 自研 PinyinTrie（~420 音节）+ 动态规划全切分/最优切分，处理歧义切分（"xian" → ["xi","an"] 或 ["xian"]）
8. **BFS 模糊匹配** — 12 条双向模糊规则（zh↔z, ch↔c, sh↔s, n↔l, in↔ing, en↔eng），BFS 扩展 + Trie 验证 + 去重，支持模糊等价判断和模糊反向查找
9. **自研 Trie 数据结构** — MoonBit 生态无通用 Trie 库，PinyinTrie 支持 insert/contains/prefix_lengths，构建期固化 ~420 音节
10. **24361 条字典内嵌** — 4 张字典构建期固化为 Map 字面量，无运行时 IO
11. **完整移植** — pinyin_helper + chinese_helper 全部 API，无功能缺失
12. **4 种声调格式** — WithToneMark / WithoutTone / WithToneNumber / FirstLetter
13. **多音字支持** — convert_to_pinyin_array 返回多读音，has_multi_pinyin 检测，disambiguate 上下文消歧
14. **繁简互转** — 繁→简 + 简→繁 + 汉字判断 + 繁体判断
15. **通用拼音** — 82 条通用拼音映射，to_tongyong_pinyin_string_array
16. **自定义字典扩展** — 3 个 add_*_dict_resource 方法，原地合并，键冲突新值覆盖
17. **字典视图共享** — 根包与 data 包共享同一 Map 引用（非拷贝）
18. **分段合并** — 20903 条单字拼音分 11 段 merge，规避单段过长警告
19. **四后端零警告** — wasm/wasm-gc/js/native 全通过，`+73 --deny-warn` 零警告零错误
20. **576 测试全通过** — 白盒 21 + 黑盒 98 + 示例 14 + 文档可执行 11，每后端 144
21. **线性无环架构** — data ← pinyin ← examples 三包线性，data 零依赖可独立复用
22. **mooncakes 已发布** — `walkzzz/pinyin@0.1.0`，32 下载

---

## 技术风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 字典数据更新 | pinyin4cj 字典变更 | `scripts/gen_pinyin_dict.py` 可重新生成字典字面量 |
| MoonBit 语言 beta-preview | 语言本身尚未 stable | 已可用于生产，不兼容变更严格评估 |
| 多音字消歧 bigram 覆盖 | bigram 频率表从 843 条词组构建，覆盖率有限 | 无 bigram 数据时退化为均匀分布；调用方可通过 add_mutil_pinyin_dict_resource 扩展词组字典 |
| 拼音分词歧义 | "xian" 可切分为 ["xi","an"] 或 ["xian"] | segment 返回所有方案，segment_best 返回最少音节方案，由调用方选择 |
| 模糊匹配规则覆盖 | 6 组规则覆盖常见南方方言，非全量 | FuzzyRule 为 pub(all) enum，调用方可自定义规则；fuzzy_rules 为 pub let 可替换 |
| 反向查找声调精度 | 当前按无调音节聚合，不区分声调 | 可通过 reverse_lookup_tone_mark 输入带调拼音，但结果仍按无调聚合；未来可扩展精确匹配 |
| 变调规则覆盖 | 当前实现三声变调和一变调，未覆盖"不"变调和"七/八"变调 | 可通过扩展 apply_tone_sandhi 规则覆盖更多变调场景 |
| 搜索索引多音字 | add_document 逐字取第一个读音，可能遗漏非首读音 | 设计权衡：避免索引键重复 vs 覆盖所有读音；调用方可通过 disambiguate 先消歧再索引 |
| WASM local count 限制 | 大字典 match 可能触发 | 字典用 Map 字面量（非大 match），四后端已验证无此问题 |