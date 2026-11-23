# core

拼音基础原语：声调转换、声母/韵母提取、格式转换与 Trie。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/core" as @core
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `set_tone(pinyin, tone)` | 给无调音节标调（1–4） |
| `strip_tone(pinyin)` | 去除声调符号 |
| `get_tone_number(pinyin)` | 返回声调数字（轻声 0/5） |
| `get_initial(pinyin)` / `get_final(pinyin)` | 声母 / 韵母，非法音节抛 `PinyinError` |
| `format_pinyin(pinyin, format)` | 按 `PinyinFormat` 输出（带调 / 数字调 / 无调 / 首字母） |
| `PinyinTrie` | 音节前缀树，供分词与查找使用 |
| `pinyin_separator` | 多读音分隔符（`,`） |

## 示例

```moonbit
let marked = @core.set_tone("zhong", 1)      // "zhōng"
let plain = @core.strip_tone("zhōng")        // "zhong"
let number = @core.get_tone_number("zhōng")  // 1

let initial = @core.get_initial("zhōng")     // "zh"
let final = @core.get_final("zhōng")         // "ong"
```

## 行为说明

- `PinyinError` 为统一错误类型，非法输入通过 `raise_invalid_input` 抛出。
- `Int` 与 `Int32` 在本项目中为同一类型别名。
- core 不依赖任何其他业务包，`data` 也不依赖 core。

## 相关

- [API 文档](../docs/api.md#core-包)
- [架构设计](../docs/architecture.md)
- [测试策略](../docs/testing.md)