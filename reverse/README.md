# reverse

拼音 → 汉字反向查找，支持无调、带调与数字调三种输入格式。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/reverse" as @reverse
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `ReversePinyinHelper::reverse_lookup(pinyin)` | 按输入格式自动识别并查找 |
| `ReversePinyinHelper::reverse_lookup_tone_mark(pinyin)` | 带调输入，如 `"zhōng"` |
| `ReversePinyinHelper::reverse_lookup_tone_number(pinyin)` | 数字调输入，如 `"zhong1"` |
| `ReversePinyinHelper::is_valid_pinyin(pinyin)` | 是否为合法音节 |

## 示例

```moonbit
let hanzi = @reverse.ReversePinyinHelper::reverse_lookup("zhong")
// ["中", "钟", "忠", ...]

let marked = @reverse.ReversePinyinHelper::reverse_lookup_tone_mark("zhōng")
// ["中", "钟", "忠", ...]

let numbered = @reverse.ReversePinyinHelper::reverse_lookup_tone_number("zhong1")
// ["中", "钟", "忠", ...]
```

## 行为说明

- 反向表覆盖 20,903 条单字读音与 843 条词组读音。
- 非法拼音抛 `PinyinError`；需要「是否合法但不抛错」时先用 `is_valid_pinyin`。
- 候选顺序为字典顺序，不保证常用度；输入法候选请用 `input` 包。

## 相关

- [API 文档](../docs/api.md#reverse-包)
- [测试策略](../docs/testing.md)