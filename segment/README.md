# segment

连续拼音串分词：Trie + 动态规划枚举全切分并取最优路径。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/segment" as @segment
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinSegmenter::segment_best(pinyin)` | 返回最优切分（音节数组） |
| `PinyinSegmenter::segment(pinyin)` | 返回全部可行切分 |
| `PinyinSegmenter::can_segment(pinyin)` | 是否能完整切分 |

## 示例

```moonbit
let best = @segment.PinyinSegmenter::segment_best("nihao")
// ["ni", "hao"]

let all = @segment.PinyinSegmenter::segment("xian")
// 全部可行切分，如 ["xian"] / ["xi", "an"]

let ok = @segment.PinyinSegmenter::can_segment("xian")
// true
```

## 行为说明

- 切分基于 `core` 的音节 Trie，非法串返回空结果或抛 `PinyinError`（取决于接口）。
- 复杂度 O(n²L)，面向输入法解码前的音节切分。
- 不负责把音节转成汉字；候选生成见 `input` 包。

## 相关

- [API 文档](../docs/api.md#segment-包)
- [输入法引擎](../input/README.md)
- [测试策略](../docs/testing.md)