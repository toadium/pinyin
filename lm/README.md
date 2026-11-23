# lm

N-gram 语言模型：Unigram / Bigram / Trigram，Laplace、Katz 回退与插值平滑。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/lm" as @lm
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinLM::unigram_prob(syllable)` | 单音节概率 |
| `PinyinLM::bigram_prob(prev, next)` | 二阶概率 |
| `PinyinLM::trigram_prob(a, b, c)` | 三阶概率 |
| `PinyinLM::sentence_log_prob(syllables)` | 句子对数概率 |
| `PinyinLM::sentence_log_prob_trigram(syllables)` | Trigram 句子对数概率 |
| `PinyinLM::interpolation_prob(a, b, c, λ1, λ2, λ3)` | 插值平滑 |
| `PinyinLM::perplexity(sentences)` / `perplexity_trigram` | 困惑度 |
| `PinyinLM::stats()` | 词表与 n-gram 规模统计 |
| `unigram_freq` / `bigram_freq` | 固化频率表 |

## 示例

```moonbit
let p = @lm.PinyinLM::unigram_prob("zhōng")
let bp = @lm.PinyinLM::bigram_prob("zhōng", "guó")

let logp = @lm.PinyinLM::sentence_log_prob(["wǒ", "shì", "zhōng", "guó", "rén"])
let ppl = @lm.PinyinLM::perplexity([["wǒ", "shì", "zhōng", "guó", "rén"]])

let stats = @lm.PinyinLM::stats()
// stats.unigram_types / bigram_types / trigram_types
```

## 行为说明

- 频率表由内置字典构建，构建期固化，不做运行时 IO。
- 未见 n-gram 走平滑/回退，避免概率为 0 导致解码失败。
- 插值权重必须非负，非法 λ 抛 `PinyinError`。
- 不提供外部语料训练接口。

## 相关

- [API 文档](../docs/api.md#lm-包)
- [输入法引擎](../input/README.md)
- [架构设计](../docs/architecture.md)