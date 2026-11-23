# convert

汉字 ↔ 拼音转换：多格式输出、自定义字典、繁简转换与流式处理。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/convert" as @convert
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinHelper::convert_to_pinyin_string(text, sep, format?)` | 词句转拼音，`format` 默认带调 |
| `PinyinHelper::convert_to_pinyin_array(char, format?)` | 单字全部读音 |
| `PinyinHelper::get_short_pinyin(text)` | 首字母串 |
| `PinyinHelper::has_multi_pinyin(char)` | 是否多音字 |
| `PinyinHelper::convert_to_pinyin_string_traditional(text, sep, format?)` | 先繁转简再转拼音 |
| `PinyinHelper::add_pinyin_dict_resource(dict)` | 追加自定义单字读音 |
| `PinyinHelper::add_mutil_pinyin_dict_resource(dict)` | 追加自定义词组读音 |
| `ChineseHelper::convert_to_simplified_chinese(text)` | 繁 → 简 |
| `PinyinStreamProcessor` | `feed` / `flush` / `reset` 增量输出 |

## 示例

```moonbit
let py = @convert.PinyinHelper::convert_to_pinyin_string("我是中国人", " ")
// wǒ shì zhōng guó rén

let initial = @convert.PinyinHelper::get_short_pinyin("我是中国人")
// "w s z g r"

let all = @convert.PinyinHelper::convert_to_pinyin_array('中')
// ["zhōng", "zhòng"]
```

流式处理：

```moonbit
let processor = @convert.PinyinStreamProcessor::new(" ", format=WithToneMark)
let first = processor.feed("我")
let rest = processor.flush()
```

## 行为说明

- 单字默认展开全部读音（如「中」→ `zhōng` / `zhòng`）；需要上下文定音请用 `disambiguate`。
- 词组读音来自 `mutil_pinyin_dict`（843 条），采用**最短前缀优先**的匹配策略，保持与源库一致。
- 大词库（47,110 条）只服务消歧与输入法，不改变本包「字级全展开」的契约。

## 相关

- [API 文档](../docs/api.md#convert-包)
- [架构设计](../docs/architecture.md)
- [测试策略](../docs/testing.md)