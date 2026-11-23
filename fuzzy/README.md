# fuzzy

模糊拼音：zh↔z、ch↔c、sh↔s、n↔l、in↔ing 等规则扩展与匹配。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/fuzzy" as @fuzzy
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `FuzzyPinyinHelper::fuzzy_expand(syllable)` | 扩展等价音节 |
| `FuzzyPinyinHelper::fuzzy_match(a, b)` | 两音节是否模糊等价 |
| `FuzzyPinyinHelper::fuzzy_reverse_lookup(pinyin)` | 模糊反向查找汉字 |
| `FuzzyPinyinHelper::add_fuzzy_rules(rules)` | 追加自定义规则（BFS 可传递） |
| `fuzzy_rules` | 内置 9 组双向规则 |

## 示例

```moonbit
let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand("zhong")
// ["zhong", "zong", ...]

let same = @fuzzy.FuzzyPinyinHelper::fuzzy_match("zhong", "zong")
// true

let hanzi = @fuzzy.FuzzyPinyinHelper::fuzzy_reverse_lookup("zong")
// 兼容「中/总」等
```

## 行为说明

- 规则支持双向与多跳扩展（BFS），自定义规则通过 `add_fuzzy_rules` 注入。
- 输入法的模糊候选请使用 `PinyinInputEngine::input_fuzzy`，它在切分后做扩展。
- 扩展结果可能包含非法音节，交由反向查找过滤。

## 相关

- [API 文档](../docs/api.md#fuzzy-包)
- [输入法引擎](../input/README.md)
- [测试策略](../docs/testing.md)