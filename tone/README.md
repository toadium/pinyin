# tone

变调规则：三声连读、一 / 不 / 七 / 八 五类变调，含同音字守卫。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/tone" as @tone
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `ToneSandhiHelper::apply_tone_sandhi(syllables)` | 就地应用变调，返回新数组 |

## 示例

```moonbit
let third = @tone.ToneSandhiHelper::apply_tone_sandhi(["nǐ", "hǎo"])
// ["ní", "hǎo"]（三声连读，前字变二声）

let bu = @tone.ToneSandhiHelper::apply_tone_sandhi(["bù", "shì"])
// ["bú", "shì"]

let yi = @tone.ToneSandhiHelper::apply_tone_sandhi(["yī", "tiān"])
// 一声后保持原调；去声前变二声
```

## 行为说明

- 规则覆盖：三声连读、一、不、七、八，配合前瞻与同音字守卫，避免把「qǐ」误判为「七」。
- 输入为带调音节数组，输出同长度数组；不修改原数组。
- 大词库与 `common_phrases` 中的「一/不」已存原调，进入本包后再变调。

## 相关

- [API 文档](../docs/api.md#tone-包)
- [多音字消歧](../disambiguate/README.md)
- [测试策略](../docs/testing.md)