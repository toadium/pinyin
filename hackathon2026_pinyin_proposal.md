# pinyin 项目申报书

> 2026 MoonBit 国产基础软件开源大赛 | 方向：开发者工具 | 申报日期：2026-11-05 | 更新日期：2026-11-17 | 当前版本：v0.6.0

---

## 组委会关切回复

### 关切一："纯移植项目，缺乏独创性"

**事实**：pinyin4cj（仓颉）仅提供了 `PinyinHelper` + `ChineseHelper` 两个命名空间共 14 个方法——本质是"汉字→拼音"和"繁→简"两张字典的查表封装。本项目的 **10 个自研包** 均为从零设计与实现，pinyin4cj 完全不具备对应能力：

| 自研包 | 自研引擎 | pinyin4cj 是否有 | 核心算法 |
|--------|---------|:---:|---------|
| `core` | PinyinTrie + PinyinInitialsFinals | ✗ | 自研 Trie（~420 音节）+ 声母韵母分解 |
| `segment` | PinyinSegmenter | ✗ | Trie+DP 动态规划全切分 |
| `fuzzy` | FuzzyPinyinHelper | ✗ | BFS 模糊扩展 + Trie 验证 + 自定义规则扩展 |
| `disambiguate` | PinyinDisambiguator | ✗ | Viterbi + bigram 动态规划消歧 |
| `search` | PinyinSearchIndex | ✗ | 倒排索引搜索 |
| `tone` | ToneSandhiHelper | ✗ | 5 类变调规则引擎 |
| `normalize` | PinyinNormalizer + PinyinEditDistance | ✗ | 规范化 + 音节级 Levenshtein |
| `lm` | PinyinLM | ✗ | N-gram LM + Laplace + Katz + Interpolation |
| `input` | PinyinInputEngine | ✗ | Beam Search + LM 评分 + 可配置评分策略 |
| `convert` | PinyinStreamProcessor | ✗ | 流式增量处理 |

移植部分仅占 2/12 包（`convert` 中的 PinyinHelper + ChineseHelper），自研部分占 **10/12 包、65/82 个公开函数**。

### 关切二："缺少独创性"

**事实**：mooncakes.io 31909 个包中匹配 pinyin 的仅 2 个。与竞品 `wjhfather/pinyin-toolkit`（基于 Unicode 17.0 Unihan 的异构方案）对比，本项目有 **8 项独有能力**：

| 能力 | walkzzz/pinyin | wjhfather/pinyin-toolkit |
|------|:---:|:---:|
| 拼音→汉字反向查找 | ✅ | ✗ |
| Trie+DP 拼音分词 | ✅ | ✗ |
| Viterbi+bigram 多音字消歧 | ✅ | ✗ |
| N-gram 语言模型（Laplace+Katz+Interpolation） | ✅ | ✗ |
| 拼音输入法引擎（Beam Search） | ✅ | ✗ |
| 声调变调规则（5 类） | ✅ | ✗ |
| 音节级编辑距离 + 模糊距离 | ✅ | ✗ |
| 自定义模糊规则扩展 | ✅ | ✗ |
| 可配置评分策略 | ✅ | ✗ |
| 繁简互转 | ✅ | ✅ |

**差异化定位**：本项目是 mooncakes.io 唯一提供拼音→汉字反向查找、拼音分词、N-gram 语言模型、拼音输入法引擎、声调变调和自定义模糊规则扩展的库。

### 关切三："技术深度不足"

**事实**：本项目包含 7 类非平凡算法，每类均有对应的算法复杂度和工程约束：

| 引擎 | 核心算法 | 时间复杂度 | 关键技术点 |
|------|---------|-----------|-----------|
| PinyinSegmenter | Trie+DP 全切分 | O(n²×L) | n=串长, L=最大前缀长度, 处理歧义切分 |
| PinyinDisambiguator | Viterbi 动态规划 | O(n×k²) | n=字数, k=每字最多读音数, bigram 打分 |
| FuzzyPinyinHelper | BFS 模糊扩展 | O(V+E) | 9 组双向规则 + 自定义规则, Trie 验证合法性 |
| PinyinLM | N-gram + Laplace + Katz + Interpolation | O(1) 查表 | 三级回退: trigram→bigram→unigram, 插值平滑, 负λ校验 |
| PinyinInputEngine | Beam Search 解码 | O(S×B×C) | S=音节数, B=beam宽度, C=每音节候选数, LM打分+可配置评分 |
| PinyinEditDistance | 音节级 Levenshtein | O(m×n) | 模糊等价音节距离为0, 结合 FuzzyRule |
| ToneSandhiHelper | 5 类变调规则 | O(n) | 三声变调/一变调/不变调/七变调/八变调, 前瞻+回溯 |

---

## 基本信息

- **项目名称**：pinyin：MoonBit 拼音引擎
- **参赛者**：walkzzz
- **联系方式**：13689047817 745244185@qq.com
- **GitHub 仓库**：https://github.com/toadium/pinyin.git
- **mooncakes 包名**：`walkzzz/pinyin`
- **项目性质**：自研拼音引擎（数据来源参考 pinyin4cj，10/12 包为自研引擎）

---

## 项目简介

pinyin 是一个自研 MoonBit 拼音引擎，提供双向拼音转换、智能分词、上下文消歧、N-gram 语言模型、拼音输入法引擎、搜索索引、变调规则、编辑距离与规范化能力。库以 Map 字面量内嵌 4 张字典（24361 条），构建期固化，无运行时 IO，四后端全通过。

**自研十大核心引擎**：PinyinTrie（~420 音节）、Trie+DP 分词、BFS 模糊匹配（9 组 + 自定义规则扩展）、Viterbi+bigram 消歧、倒排索引搜索、声调变调规则（5 类）、音节级编辑距离、拼音规范化、N-gram 语言模型（Laplace+Katz 回退+Interpolation 平滑）、拼音输入法引擎（Beam Search+LM 评分+可配置评分策略）。

**mooncakes 调研**：31909 个包中匹配 pinyin 的仅 2 个——本项目与 `wjhfather/pinyin-toolkit`（异构方案，基于 Unicode 17.0 Unihan）。本项目独有反向查找、拼音分词、N-gram LM、输入法引擎、变调规则、编辑距离、自定义模糊规则扩展、可配置评分策略 8 项能力。

---

## 当前完成状态（v0.6.0）

| 指标 | 数值 |
|------|------|
| 包数 | **12**（core/data/convert/reverse/segment/fuzzy/disambiguate/search/tone/normalize/lm/input） |
| 公开函数 | **82** |
| 公开类型 | **15**（struct/enum/suberror） |
| 公开常量 | **19** |
| 测试数 | **225/后端**（四后端共 900 全通过） |
| 工程严格度 | ✅ `--warn-list +73 --deny-warn` 零警告零错误 |
| 字典条目 | **24361**（chinese 2533 + pinyin 20903 + mutil 843 + tongyong 82） |
| LM 统计 | vocab_size=411, bigram_types=1088, unigram_total=20903+ |
| 示例测试 | **37**（14 个子包全覆盖示例） |
| mooncakes | ✅ `walkzzz/pinyin@0.6.0` 已发布 |
| 错误路径测试 | ✅ 所有公开 `raise` 函数均有非法输入→PinyinError 测试覆盖 |
| CI | ✅ GitHub Actions：fmt/check/build/test 四后端严格门禁 |

---

## 技术方案

### 12 包扁平多根架构

```
core（零依赖）    data（零依赖）
  ↑                  ↑
convert（core+data）
  ↑
┌───┴───┬──────────┬──────────┐
reverse segment  fuzzy    disambiguate
    ↑         ↑         ↑
  search    normalize    tone
    ↑
lm（core+data+math）
  ↑
input（core+segment+reverse+lm+math+data+fuzzy）
```

参照 owl-mbt 项目理念，线性无环依赖，core/data 零依赖，各子包职责单一。根包为文档入口（不导入子包），用户直接导入子包。

### 十大自研核心引擎

1. **PinyinTrie**：自研 Trie，~420 音节构建期固化，O(L) 查询
2. **Trie+DP 分词**：全切分 + 最优切分，处理歧义（"xian" → ["xi","an"] 或 ["xian"]），O(n²×L)
3. **BFS 模糊匹配**：9 组双向规则（18 条，zh↔z/ch↔c/sh↔s/n↔l/f↔h/in↔ing/en↔eng/an↔ang/ong↔eng），扩展 + Trie 验证 + 去重 + **自定义规则扩展**（`add_fuzzy_rules`）
4. **Viterbi+bigram 消歧**：从 843 条词组构建 bigram 频率表，动态规划选最优读音序列，O(n×k²)
5. **倒排索引搜索**：首字母/连续拼音/模糊拼音搜索
6. **声调变调引擎**：三声变调/一变调/不变调/七变调/八变调（5 类变调规则）
7. **音节级编辑距离**：Levenshtein + 模糊距离（等价音节代价为 0），O(m×n)
8. **拼音规范化**：大小写/数字调→带调标记/v→ü/声调位置纠正
9. **N-gram 语言模型**：unigram/bigram/trigram 频率表 + Laplace 平滑 + Katz 回退 + Interpolation 平滑，O(1) 概率查询；vocab_size=411, bigram_types=1088
10. **拼音输入法引擎**：Beam Search 解码 + LM 评分 + 词组优先 + 用户词库 + 模糊输入 + **可配置评分策略**（`InputScoringConfig`），O(S×B×C)，可配置 beam 宽度

**PinyinStreamProcessor**：流式拼音处理器，逐字符输入汉字实时输出增量拼音（new/feed/flush/reset），适用于输入法等实时场景。

**PinyinInitialsFinals**：声母/韵母提取引擎，`get_initial`/`get_final` 分解声母韵母，`initials_list` 声母表。

### N-gram 语言模型设计

- **频率表构建**：unigram 从 `pinyin_dict`（20903 条）构建，bigram/trigram 从 `mutil_pinyin_dict`（843 条词组）构建
- **Laplace 平滑**：P(w) = (count(w) + 1) / (N + V)，保证零概率问题
- **Katz 回退**：trigram 未见→回退 bigram→回退 unigram，三级概率衰减
- **Interpolation 平滑**：P(w|c1,c2) = λ₁P(w|c1,c2) + λ₂P(w|c2) + λ₃P(w)，可配置插值权重（负λ抛 PinyinError）
- **评估指标**：句子对数概率、困惑度（Perplexity），支持 bigram/trigram/interpolation 三种模型

### 拼音输入法引擎设计

- **算法流程**：拼音串 → PinyinSegmenter 分词 → ReversePinyinHelper 反查候选 → Beam Search + LM 打分 → 排序去重
- **Beam Search**：每步保留 top-k 路径（k=beam_width），避免组合爆炸
- **可配置评分策略**（`InputScoringConfig`）：
  - `user_dict_bonus`：用户词库加分（默认 10.0）
  - `phrase_bonus`：内置词组表加分（默认 5.0）
  - `candidate_limit`：每音节最大候选数（默认 20）
- **用户词库**：`add_user_dict` 动态添加自定义词组映射
- **模糊输入**：`input_fuzzy` 支持模糊拼音输入（zh↔z 等自动扩展）
- **候选去重**：相同文本只保留最高得分，合并多种分词路径
- **可配置性**：beam 宽度 + 评分策略均可运行时调整，支持单条/全切分/限量三种模式

### PinyinError 跨包设计与输入校验

`pub(all) suberror PinyinError { InvalidInput(String) }`。由于 MoonBit [0073] 跨包 bug，提供 `pub fn raise_invalid_input(msg) -> Unit raise PinyinError` 包装函数。

**v0.6.0 全面输入校验**：28 个函数从静默失败改为 `raise PinyinError`，杜绝静默吞掉异常：

| 包 | 改造函数 | 原行为 | 新行为 |
|---|---------|--------|--------|
| segment | `segment` / `segment_best` | 空串返回 `[]` | 空串抛 PinyinError |
| fuzzy | `fuzzy_expand` / `fuzzy_match` | 空串静默处理 | 空串抛 PinyinError |
| core | `get_initial` / `get_final` | 空串返回空字符串 | 空串抛 PinyinError |
| normalize | `distance` / `fuzzy_distance` | 空串返回 0 | 空串抛 PinyinError |
| lm | `perplexity` / `perplexity_trigram` / `perplexity_interpolation` | 空句返回 ∞ | 空句抛 PinyinError |
| lm | `interpolation_prob` | 负λ静默计算 | 负λ抛 PinyinError |
| input | `input_from_segments` / `input_with_limit` | 空segments/limit<1 返回空/越界 | 抛 PinyinError |
| search | `search_fuzzy` | 级联静默 | 级联 raise |
| convert | `convert_to_pinyin_string` / `get_short_pinyin` / `has_multi_pinyin` | 空串/非汉字静默 | 抛 PinyinError |

---

## 核心功能范围

| 包 | 类 | 方法数 | 核心功能 |
|---|---|---|---|
| convert | PinyinHelper | 8 | 词句转拼音、多音字数组、首字母、通用拼音、自定义字典 |
| convert | ChineseHelper | 6 | 繁简互转、汉字判断、自定义字典 |
| convert | PinyinStreamProcessor | 4 | 流式处理：new/feed/flush/reset |
| reverse | ReversePinyinHelper | 4 | 无调/带调/数字调反向查找、合法音节判断 |
| segment | PinyinSegmenter | 3 | 全切分/最优切分/可切分判断 |
| fuzzy | FuzzyPinyinHelper | 4 | 模糊扩展/等价判断/模糊反向查找/自定义规则扩展 |
| disambiguate | PinyinDisambiguator | 1 | Viterbi+bigram 上下文消歧 |
| search | PinyinSearchIndex | 5 | 倒排索引：首字母/连续/模糊搜索 |
| tone | ToneSandhiHelper | 1 | 三声变调/一变调/不变调/七变调/八变调 |
| normalize | PinyinEditDistance | 2 | Levenshtein + 模糊距离 |
| normalize | PinyinNormalizer | 3 | 带调标记/数字调/无调规范化 |
| core | PinyinTrie | 4 | Trie insert/contains/prefix_lengths |
| core | PinyinInitialsFinals | 3 | get_initial/get_final/initials_list |
| core | PinyinFormat | 4 变体 | WithToneMark/WithoutTone/WithToneNumber/FirstLetter |
| core | FuzzyRule | 2 变体 | Prefix/Suffix（可扩展） |
| core | PinyinError | 1 变体 | InvalidInput(String) |
| **lm** | **LMStats** | **7 字段** | **vocab_size/unigram_total/bigram_total/trigram_total/unigram_types/bigram_types/trigram_types** |
| **input** | **InputCandidate** | **3 字段** | **text/score/segments** |
| **input** | **InputScoringConfig** | **3 字段** | **user_dict_bonus/phrase_bonus/candidate_limit** |

---

## 质量与测试

| 包 | 白盒 | 黑盒 | 合计 | 错误路径测试 |
|---|---|---|---|---|
| core | 21 | 0 | 21 | — |
| convert | 8 | 37 | 45 | 3 |
| reverse | 0 | 10 | 10 | 1 |
| segment | 0 | 14 | 14 | 2 |
| fuzzy | 0 | 22 | 22 | 1 |
| disambiguate | 0 | 7 | 7 | 1 |
| search | 0 | 9 | 9 | 2 |
| tone | 0 | 14 | 14 | 2 |
| normalize | 0 | 22 | 22 | 2 |
| **lm** | **0** | **15** | **15** | **3** |
| **input** | **0** | **18** | **18** | **4** |
| examples | 0 | 37 | 37 | — |
| **总计** | **29** | **196** | **225/后端** | **21** |

四后端共 900 测试全通过，严格模式零警告零错误。含 21 个错误路径测试（非法输入→PinyinError）覆盖所有公开 raise 函数。

## mooncakes.io 生态对比

| 库 | 数据源 | 字典条目 | 繁简 | 反向查找 | 分词 | 消歧 | 搜索 | 变调 | 编辑距离 | 规范化 | N-gram LM | 输入法 | 自定义规则 | 可配评分 | 四后端 | 测试数 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **walkzzz/pinyin** | 内嵌字典 | 24361 | ✅ | ✅ | ✅ Trie+DP | ✅ Viterbi | ✅ | ✅ 5类 | ✅ | ✅ | ✅ Laplace+Katz+Interp | ✅ Beam Search | ✅ fuzzy+dict | ✅ InputScoringConfig | ✅ | 900 |
| wjhfather/pinyin-toolkit | Unicode 17.0 | 未公开 | ✗ | ✗ | ✗ | ✗ override | ✅ | ✗ | ✅ | ✅ | ✗ | ✗ | ✗ | ✗ | ✅ | 未公开 |

**差异化定位**：本项目是 mooncakes.io 唯一提供 N-gram 语言模型、拼音输入法引擎、反向查找、拼音分词、声调变调、自定义模糊规则扩展和可配置评分策略的库；12 包扁平架构参照 owl-mbt；37 个示例覆盖 12 个子包。

## 版本交付计划

| 版本 | 交付内容 | 状态 |
|------|---------|------|
| v0.1.0 | 基础转换引擎（数据来源 pinyin4cj） | ✅ |
| v0.1.1 | 工程化 + warning 治理 + 严格 deny-warn | ✅ |
| v0.2.0 | 反向查找 + 拼音分词 + 模糊匹配 | ✅ |
| v0.3.0 | 消歧 + 搜索索引 + 变调 + 编辑距离 + 规范化 | ✅ |
| v0.4.0 | 10 包架构重构 + PinyinError 跨包 + 七/八变调 + 3组新模糊规则 + PinyinStreamProcessor | ✅ |
| v0.5.0 | N-gram 语言模型 + 拼音输入法引擎 + 12 包架构 + 声母韵母提取 | ✅ |
| **v0.6.0** | **输入校验强化（28 函数→raise PinyinError）+ 自定义模糊规则扩展 + 可配置评分策略（InputScoringConfig）+ 上游库规范对齐 + 900 测试** | ✅ |
| v1.0.0（计划） | API 冻结 + 完善文档站 + 性能基准测试 | 📋 |

---

## 验收标准对齐

| 大赛验收项 | 满足方式 |
|-----------|---------|
| MoonBit 为主 | 100% MoonBit，12 包扁平架构，82 个公开函数 |
| 仓库公开可访问 | GitHub，v0.1.0~v0.6.0 持续迭代 7 个版本 |
| 源代码结构清晰 | 12 包职责单一，线性无环依赖，贡献指南（CONTRIBUTING.md） |
| README 可复现 | README + 37 示例 + 900 测试 + 6 条 FAQ |
| CI 覆盖检查/构建/测试 | GitHub Actions：fmt/check/build/test `--target all --warn-list +73 --deny-warn` |
| 可运行示例 | examples 包 37 个示例测试（14 子包全覆盖） |
| 完整测试覆盖 | 225/后端 × 4 = 900，含 21 个错误路径测试 |
| OSI 许可证 | MIT，数据参考来源 pinyin4cj 已标注 |
| 发布到 mooncakes | `walkzzz/pinyin@0.6.0` 已发布 |

**数据参考来源**：[pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj) — 仓颉原版（MIT）。本项目仅参考其字典数据格式，10/12 包为自研引擎，核心算法（Trie+DP、Viterbi、BFS、N-gram LM、Beam Search 等）均为原创实现。

---

## 上游库规范合规性

对照《通用上游源码库开发规范、评判标准与开源评审体系》，逐维度自评：

| 评价维度 | 权重 | 自评 | 依据 |
|---------|------|------|------|
| 契约稳定与向后兼容 | 20 | 良 | 严格 SemVer，v0.6.0 破坏性变更（空串行为）仅在 0.x 允许；v1.0 后将冻结 API |
| 单一职责与边界清晰 | 12 | 优 | 12 包扁平布局，每包职责单一，线性无环依赖 |
| 依赖可控性 | 10 | 优 | 仅依赖 MoonBit 标准库（`@core/math`），零第三方依赖 |
| 错误处理与故障隔离 | 10 | 优 | v0.6.0 全面校验：28 个静默失败函数→raise PinyinError，21 个错误路径测试 |
| 性能与资源占用 | 8 | 优 | 构建期固化，零运行时 IO，无泄漏，WASM-GC ~10MB |
| 低侵入与可扩展性 | 8 | 优 | 字典共享为文档化特性（含全局状态副作用说明），用户词库/beam 宽度/评分配置/模糊规则均可运行时扩展 |
| 测试覆盖与质量保障 | 12 | 优 | 225/后端×4=900 测试，含 21 个错误路径测试，CI 严格门禁 |
| 文档完整性与易用性 | 10 | 优 | 适用/不适用场景 + 6 条 FAQ + 37 示例 + 完整 API 表 + CONTRIBUTING.md + 全局状态副作用文档 |
| 维护性与生命周期 | 10 | 良 | CONTRIBUTING.md 明确响应时效（高危7日/一般14日/功能30日），MIT 许可证，7 个版本持续迭代 |
