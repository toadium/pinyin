# pinyin 申报附件：技术细节与关切回复

## 1. 组委会关切逐条回复

### 1.1 “纯移植项目，缺乏独创性”

pinyin4cj 提供 PinyinHelper + ChineseHelper 共 14 个方法（查表 + 繁简转换）。本项目保留这段移植边界（convert + data），其余 10 个包为自研：

| 包 | 引擎 | 算法 | pinyin4cj |
|---|---|---|---|
| core | PinyinTrie + 声母/韵母 | 前缀树 + 分解 | ✗ |
| segment | PinyinSegmenter | Trie + DP 全切分/最优切分 | ✗ |
| fuzzy | FuzzyPinyinHelper | BFS 模糊扩展 + 自定义规则 | ✗ |
| disambiguate | PinyinDisambiguator | 词级优先 + Viterbi + 带调 bigram | ✗ |
| search | PinyinSearchIndex | 倒排索引（首字母/全拼/模糊） | ✗ |
| tone | ToneSandhiHelper | 5 类变调（三声/一/不/七/八） | ✗ |
| normalize | PinyinNormalizer + EditDistance | 规范化 + 音节级 Levenshtein | ✗ |
| lm | PinyinLM | N-gram + Laplace + Katz + Interpolation | ✗ |
| input | PinyinInputEngine | Beam Search + 词表/简拼/双拼/学习 | ✗ |
| shuangpin | ShuangpinScheme | 小鹤/自然码双向键位映射 | ✗ |

### 1.2 “核心算法与工程复杂度较低”

| 引擎 | 算法 | 复杂度 | 可复核证据 |
|---|---|---|---|
| PinyinDisambiguator | 词级覆盖 + Viterbi + 带调 bigram | O(nk²) | 66 条 gold：96.1% vs 基线 68.0% |
| PinyinInputEngine | Beam Search + N-gram + 词组/学习重排 | O(S×B×C) | `nihao`→你好、`nihao`(双拼)→你好、`zg`→中国 |
| PinyinSegmenter | Trie + DP 全切分/最优 | O(n²L) | `xian` 多切分、`nihao` 最优 |
| ShuangpinScheme | 声母/韵母双向映射 | O(n) | 小鹤/自然码 10 组往返测试 |
| PinyinLM | Laplace / Katz / Interpolation | O(1) 查询 | 概率/句子/困惑度测试 |
| ToneSandhiHelper | 5 类规则 + 同音原调守卫 | O(n) | 三声/一/不/七/八回归 |

### 1.3 “功能范围较窄、竞品已有相关能力”

pinyin-toolkit 的真实强项（它做得比我们好，不回避）：

- Unicode 17.0 Unihan 数据、数据版本/SHA256/许可证审计
- 可审计 token/span/diagnostic、ConversionIntegrity、PinyinAlignment
- 批量转换 + JSON 报告
- SearchKey（Exact/Full/Initials/Compact）+ 匹配解释 + 加权编辑距离

它明确不做的（本项目差异）：

- 多音字上下文推断：竞品要求调用方显式 phrase override，本项目做词级 + 统计消歧
- 输入法解码：候选生成、Beam、LM、简拼、双拼、用户学习
- 连续拼音串 Trie+DP 分词
- 变调规则
- 中文拼音输入法闭环

## 2. 本轮新增（v0.8.0）

### 2.1 双拼（`shuangpin` 包）

- 小鹤双拼、自然码双拼 ↔ 全拼双向转换
- 键位映射参考 Rime `double_pinyin_flypy` / `double_pinyin` schema
- `input_shuangpin`：`nihc` → 你好，`nihk`（自然码）→ 你好
- 覆盖声母 zh/ch/sh、零声母、ü/ün 归一化

### 2.2 输入法

- 简拼：`input_initial("zg")` → 中国，`srf` → 输入法
- 常用词表：`data/common_phrases` 128 词，词组候选优先
- 用户学习：`learn(text)` 后该候选优先重排
- 候选去重、常用字优先、词表同音覆盖

### 2.3 消歧

- 词级优先：常用词表 / 词组表命中直接采用逐字读音（含轻声）
- 未命中回退：带调 bigram Viterbi（保留声调，区分 chǔ/chù）
- gold 语料：37 个多音词 + 29 个短句，共 66 条；准确率 96.1%，首读音基线 68.0%

## 3. 工程与质量

- 四后端 wasm / wasm-gc / js / native：326 测试/后端，共 1304
- 严格模式 `--warn-list +73 --deny-warn`：四后端 check/build/test 零警告
- 覆盖率门禁：核心包 ≥92%、每包 ≥85%
- 变异门禁：14 个单点变异，要求相关包测试失败（KILLED）
- CI：quality（fmt/check/build/mbti/docs）+ test×4 + coverage；mutation 手动/每周
- 可运行演示：`moon run demo --target native`
- 文档一致性：版本、测试数、包数、工具链、相对链接自动校验

## 4. 数据与许可证

- 字典：pinyin4cj（Cangjie，MIT），仅 convert/data 的字典与接口设计
- 新增 `common_phrases`、`common_chars`：手工整理，随项目 MIT 发布
- 双拼键位：参考 Rime 开源 schema（键位事实，代码独立实现）
- 根 LICENSE：MIT，含 `Copyright (c) 2026 walkzzz` 与上游 `2017 sbiger` 声明

## 5. 复现命令

```bash
moon check --target all --warn-list +73 --deny-warn
moon test  --target all --warn-list +73 --deny-warn
node scripts/check_coverage.mjs
node scripts/mutation_test.mjs
node scripts/check_docs.mjs
node scripts/check_pages.mjs
moon run demo --target native
```