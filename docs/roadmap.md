# 路线图

## 版本 0.3.0（当前）

- ✅ 多音字上下文消歧（PinyinDisambiguator：Viterbi + bigram 词频模型，从 mutil_pinyin_table 构建 bigram 频率表）
- ✅ 拼音搜索索引（PinyinSearchIndex：倒排索引，首字母搜索/连续拼音搜索/模糊拼音搜索）
- ✅ 声调变调规则（ToneSandhiHelper：三声变调/一变调/不变调，含 get_tone_number/set_tone 辅助函数）
- ✅ 拼音编辑距离（PinyinEditDistance：音节级 Levenshtein 距离 + 模糊距离）
- ✅ 拼音规范化（PinyinNormalizer：大小写统一/数字调→带调标记/v→ü/声调位置纠正）
- ✅ 测试数 105→144/后端（新增消歧7+搜索7+变调8+编辑距离7+规范化10），四后端共 576 测试
- ✅ 四后端严格 `--warn-list +73 --deny-warn` 零警告零错误
- ✅ 公开 API 33→45（新增 PinyinDisambiguator 1 + PinyinSearchIndex 5 + ToneSandhiHelper 1 + PinyinEditDistance 2 + PinyinNormalizer 3）

## 版本 0.2.0

- ✅ 拼音→汉字反向查找（ReversePinyinHelper：reverse_lookup / reverse_lookup_tone_mark / reverse_lookup_tone_number / is_valid_pinyin）
- ✅ 拼音分词（PinyinSegmenter：Trie + DP，segment 全切分 / segment_best 最优切分 / can_segment）
- ✅ 模糊匹配（FuzzyPinyinHelper：fuzzy_expand / fuzzy_match / fuzzy_reverse_lookup，6 组模糊规则）
- ✅ PinyinTrie 数据结构（~420 拼音音节，自研 Trie，MoonBit 生态无通用 Trie 库）
- ✅ FuzzyRule 枚举（Prefix / Suffix 两类模糊规则）
- ✅ 测试数 60→105/后端（新增 Trie 白盒 + 反向查找 + 分词 + 模糊匹配黑盒测试），四后端共 420 测试
- ✅ 四后端严格 `--warn-list +73 --deny-warn` 零警告零错误

## 版本 0.1.1

- ✅ 源码布局重构：`src/` → 根目录（对齐 chrono_tz-mbt 约定）
- ✅ 多后端支持：wasm / wasm-gc / js / native（60/60 × 4 = 240 测试）
- ✅ 严格模式 `--warn-list +73 --deny-warn` 四后端全绿，零警告零错误
- ✅ Warning 全面治理：[0025] test_unqualified_package + [0020] deprecated to_repr + [0073] unnecessary_annotation
- ✅ AGENTS.md 创建，docs/ 开发文档补充（roadmap / architecture / api / testing）
- ✅ 白盒测试补充（pinyin_easy_wbtest.mbt，内部逻辑覆盖）
- ✅ 字典视图常量与 data 包共享引用验证

## 版本 0.1.0（初始）

- ✅ 核心移植：pinyin4cj Cangjie → MoonBit
- ✅ 4 张字典：chinese(2533) + pinyin(20903) + mutil(843) + tongyong(82)
- ✅ PinyinHelper API：convert_to_pinyin_string / convert_to_pinyin_array / get_short_pinyin / has_multi_pinyin / to_tongyong_pinyin_string_array
- ✅ ChineseHelper API：繁简转换 + 汉字判断
- ✅ PinyinFormat：WithToneMark / WithoutTone / WithToneNumber / FirstLetter
- ✅ 自定义字典扩展：add_pinyin_dict_resource / add_mutil_pinyin_dict_resource / add_chinese_dict_resource
- ✅ CI：check --target all + test + fmt --check

## 未来计划

- 白盒测试进一步拆分（tone_conversion 内部逻辑覆盖）
- 基准测试（bench）
- 更多字典格式支持
- 拼音→汉字反向查找的声调精确匹配（当前按无调音节聚合）