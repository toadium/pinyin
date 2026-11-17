# pinyin 项目申报书

> 2026 MoonBit 国产基础软件开源大赛 | 方向：开发者工具 | 申报日期：2026-11-05 | 更新日期：2026-11-17 | 版本：v0.6.0
>
> walkzzz | 13689047817 | 745244185@qq.com | https://github.com/toadium/pinyin | mooncakes: `walkzzz/pinyin`

---

## 组委会关切回复

### 关切一："纯移植项目，缺乏独创性"

pinyin4cj 仅提供 PinyinHelper + ChineseHelper 共 14 个方法——本质是两张字典的查表封装。本项目自研 10 包 pinyin4cj **完全不具备**，不存在功能重叠：

| 自研包 | 引擎 | pinyin4cj | 算法 |
|--------|------|:---------:|------|
| core | PinyinTrie + PinyinInitialsFinals | ✗ | 前缀树（~420音节）+ 声母韵母分解 |
| segment | PinyinSegmenter | ✗ | Trie+DP 动态规划全切分 |
| fuzzy | FuzzyPinyinHelper | ✗ | BFS 模糊扩展 + 自定义规则 |
| disambiguate | PinyinDisambiguator | ✗ | Viterbi+bigram 消歧 |
| search | PinyinSearchIndex | ✗ | 倒排索引 |
| tone | ToneSandhiHelper | ✗ | 5类变调规则引擎 |
| normalize | PinyinNormalizer + PinyinEditDistance | ✗ | 规范化 + 音节级Levenshtein |
| lm | PinyinLM | ✗ | N-gram + Laplace + Katz + Interpolation |
| input | PinyinInputEngine | ✗ | Beam Search + 可配评分策略 |
| convert | PinyinStreamProcessor | ✗ | 流式增量处理 |

**自研 10/12 包、65/82 函数（79%）；移植 2/12 包、零算法纯查表。**

### 关切二："缺少独创性"（与竞品无差异）

mooncakes.io 31909 包中匹配 pinyin 仅 2 个。与竞品 `wjhfather/pinyin-toolkit` 对比：

| 能力 | 本项目 | 竞品 |
|------|:---:|:---:|
| 反向查找 / Trie+DP分词 / Viterbi消歧 / N-gram LM / 输入法引擎 / 变调规则 / 编辑距离 / 自定义规则扩展 / 可配评分 | ✅ | ✗ |
| 繁简互转 / 搜索 | ✅ | ✅ |

**8:0 独有能力，功能维度完全不重叠。**

### 关切三："技术深度不足"

7 类非平凡算法 + 900 测试 + 上游库规范对齐：

| 引擎 | 算法 | 复杂度 |
|------|------|--------|
| PinyinSegmenter | Trie+DP 全切分 | O(n²×L) |
| PinyinDisambiguator | Viterbi 动态规划 | O(n×k²) |
| FuzzyPinyinHelper | BFS 模糊扩展 | O(V+E) |
| PinyinLM | N-gram + Laplace + Katz + Interpolation | O(1) |
| PinyinInputEngine | Beam Search + 可配评分 | O(S×B×C) |
| PinyinEditDistance | 音节级 Levenshtein | O(m×n) |
| ToneSandhiHelper | 5类变调规则 | O(n) |

v0.6.0 新增：28 函数静默失败→raise PinyinError / add_fuzzy_rules 自定义规则 / InputScoringConfig 可配评分 / 上游库规范 9 维度合规

---

## 项目简介

自研 MoonBit 拼音引擎：双向转换 + 智能分词 + 上下文消歧 + N-gram LM + 输入法引擎 + 搜索索引 + 变调 + 编辑距离 + 规范化。4 张内嵌字典（24361 条），构建期固化，零运行时 IO，四后端全通过。

---

## 完成状态

| 指标 | 数值 |
|------|------|
| 包 / 函数 / 类型 | 12 / 82 / 15 |
| 测试 | 225/后端 × 4 = **900**（含 21 错误路径测试） |
| 严格度 | `--warn-list +73 --deny-warn` 零警告零错误 |
| 字典 | 24361（chinese 2533 + pinyin 20903 + mutil 843 + tongyong 82） |
| LM | vocab=411, bigram_types=1088 |
| 示例 | 37（14 子包全覆盖） |
| mooncakes | `walkzzz/pinyin@0.6.0` 已发布 |

---

## 核心功能

| 包 | 类 | 方法 | 功能 |
|---|---|---|---|
| convert | PinyinHelper / ChineseHelper / PinyinStreamProcessor | 8+6+4 | 词句转拼音、繁简互转、流式处理 |
| reverse | ReversePinyinHelper | 4 | 无调/带调/数字调反向查找 |
| segment | PinyinSegmenter | 3 | 全切分/最优切分 |
| fuzzy | FuzzyPinyinHelper | 4 | 模糊扩展/等价判断/模糊反查/自定义规则 |
| disambiguate | PinyinDisambiguator | 1 | Viterbi+bigram 消歧 |
| search | PinyinSearchIndex | 5 | 首字母/连续/模糊搜索 |
| tone | ToneSandhiHelper | 1 | 5类变调 |
| normalize | PinyinEditDistance / PinyinNormalizer | 2+3 | Levenshtein+模糊距离 / 规范化 |
| core | PinyinTrie / PinyinInitialsFinals | 4+3 | Trie / 声母韵母 |
| lm | PinyinLM / LMStats | 11 | N-gram + Laplace + Katz + Interpolation |
| input | PinyinInputEngine / InputCandidate / InputScoringConfig | 12 | Beam Search + LM + 可配评分 |

---

## 质量与测试

| 包 | 测试 | 错误路径 |
|---|---|---|
| core/convert/reverse/segment/fuzzy | 21+45+10+14+22 | —/3/1/2/1 |
| disambiguate/search/tone/normalize | 7+9+14+22 | 1/2/2/2 |
| lm/input/examples | 15+18+37 | 3/4/— |
| **总计** | **225/后端（900）** | **21** |

---

## mooncakes 生态对比

| 库 | 反向查找 | 分词 | 消歧 | LM | 输入法 | 变调 | 自定义规则 | 可配评分 | 测试 |
|---|---|---|---|---|---|---|---|---|---|
| **walkzzz/pinyin** | ✅ | ✅ Trie+DP | ✅ Viterbi | ✅ Laplace+Katz | ✅ Beam | ✅ 5类 | ✅ | ✅ | 900 |
| wjhfather/pinyin-toolkit | ✗ | ✗ | ✗ override | ✗ | ✗ | ✗ | ✗ | ✗ | 未公开 |

---

## 上游库规范合规性

| 维度（权重） | 自评 | 依据 |
|---|---|---|
| 契约稳定（20） | 良 | 严格 SemVer，0.x 允许破坏性变更，v1.0 冻结 |
| 单一职责（12） | 优 | 12 包扁平，线性无环依赖 |
| 依赖可控（10） | 优 | 仅标准库，零第三方 |
| 错误处理（10） | 优 | 28 函数→raise PinyinError，21 错误路径测试 |
| 性能资源（8） | 优 | 构建期固化，零 IO，WASM-GC ~10MB |
| 可扩展性（8） | 优 | 评分/模糊规则/用户词库均可运行时扩展 |
| 测试覆盖（12） | 优 | 900 测试 + CI 严格门禁 |
| 文档易用（10） | 优 | FAQ + CONTRIBUTING + 37 示例 + 全局状态副作用文档 |
| 维护生命周期（10） | 良 | 响应时效（高危7日/一般14日），7 版本持续迭代 |

---

## 验收标准

| 验收项 | 满足方式 |
|---|---|
| MoonBit 为主 | 100%，12 包，82 函数 |
| 仓库公开 | GitHub，7 版本持续迭代 |
| 结构清晰 | 12 包单一职责 + CONTRIBUTING.md |
| README 可复现 | 37 示例 + 900 测试 + 6 条 FAQ |
| CI | GitHub Actions: fmt/check/build/test `--target all --deny-warn` |
| 测试覆盖 | 225/后端 × 4 = 900 |
| OSI 许可证 | MIT，数据来源 pinyin4cj 已标注 |
| mooncakes | `walkzzz/pinyin@0.6.0` |

**数据参考**：[pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj)（仓颉，MIT）——仅参考字典数据格式，10/12 包自研，7 类算法原创。
