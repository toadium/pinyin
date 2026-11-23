# normalize

拼音规范化与编辑距离：大小写、ü/v、声调格式，音节级 Levenshtein。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/normalize" as @normalize
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinNormalizer::normalize(input)` | 统一为带调小写形式 |
| `PinyinNormalizer::normalize_to_tone_number(input)` | 统一为数字调形式 |
| `PinyinNormalizer::normalize_to_without_tone(input)` | 统一为无调形式 |
| `PinyinEditDistance::distance(a, b)` | 音节级编辑距离 |
| `PinyinEditDistance::fuzzy_distance(a, b)` | 模糊等价音节距离为 0 |

## 示例

```moonbit
let marked = @normalize.PinyinNormalizer::normalize("ZHONG1")
// "zhōng"

let numbered = @normalize.PinyinNormalizer::normalize_to_tone_number("zhōng")
// "zhong1"

let plain = @normalize.PinyinNormalizer::normalize_to_without_tone("Zhōng")
// "zhong"

let d = @normalize.PinyinEditDistance::distance("zhong", "zong")
// 1
```

## 行为说明

- `ü` 与 `v` 视为同一韵母；轻声数字 `5` 会被去除。
- 空串规范化返回空串，不会产出残留数字。
- 编辑距离按音节计算，而非字符。

## 相关

- [API 文档](../docs/api.md#normalize-包)
- [模糊匹配](../fuzzy/README.md)
- [测试策略](../docs/testing.md)