# disambiguate

多音字上下文消歧：词表最大匹配 + 带调 bigram Viterbi。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/disambiguate" as @disambiguate
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinDisambiguator::disambiguate(text)` | 返回逐字带调拼音数组，空串抛 `PinyinError` |

## 示例

```moonbit
let py = @disambiguate.PinyinDisambiguator::disambiguate("银行行长")
// ["yín", "háng", "háng", "zhǎng"]

let sentence = @disambiguate.PinyinDisambiguator::disambiguate("我明天还钱")
// ["wǒ", "míng", "tiān", "huán", "qián"]
```

## 行为说明

- 词级读音优先级：`common_phrases`（147）> pypinyin 大词库（47,110）> `mutil_pinyin_table`（843）。
- 句子内已知词组按最长匹配固定读音，未命中字符走带调 bigram Viterbi。
- 大词库「一/不」已还原原调，变调请配合 `tone` 包的 `apply_tone_sandhi`。
- 单字输入返回该字首读音；非法空串抛错。
- 66 条 gold 语料准确率 99.5%，首读音基线 68.0%。

## 相关

- [API 文档](../docs/api.md#disambiguate-包)
- [变调规则](../tone/README.md)
- [测试策略](../docs/testing.md)