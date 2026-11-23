# data

纯数据包：单字/词组拼音、繁简映射、常用字序与 47k 大词库。

[← 返回总览](../README.md)

## 说明

`data` 是共享数据子包，本身不做拼音逻辑；`convert`、`reverse`、`disambiguate`、`input`、`lm` 都从这里取表。包间零业务依赖，便于四后端一致初始化。

## 词表清单

| 表 | 条目 | 用途 |
|---|---|---|
| `chinese_dict` | 2,533 | 繁体 → 简体码点映射 |
| `pinyin_dict` | 20,903 | 单字拼音（多音字逗号分隔） |
| `mutil_pinyin_dict` | 843 | 源库词组拼音 |
| `tongyong_pinyin_dict` | 82 | 通用拼音 |
| `common_phrases` | 147 | 项目校准常用词（消歧优先级最高） |
| `large_phrase_raw_01..06` | 47,110 | pypinyin 大词库（6 个字符串分片） |

## 主要接口

| 接口 | 说明 |
|---|---|
| `large_phrase_lookup(word)` | 查询大词库，未命中返回 `None` |
| `large_phrase_count` | 大词库条目数（47,110） |
| `large_phrase_max_chars` | 大词库最长词长（9） |
| `common_char_rank(char)` | 常用字序号，越小越常用；未收录返回 100000 |

## 示例

```moonbit
match @data.large_phrase_lookup("虚与委蛇") {
  Some(pinyin) => println(pinyin)  // "xū,yǔ,wēi,yí"
  None => println("未收录")
}

let rank = @data.common_char_rank("的")
```

## 大词库口径

- 来源：[`mozillazg/python-pinyin`](https://github.com/mozillazg/python-pinyin) 的 `pypinyin/phrases_dict.json`，
  SHA256 `a45ff140a6b631ca9c82127b280a2f414e0aba6bb2824a0e9d1e77fff359c665`。
- 生成：`python scripts/gen_large_phrases.py --src <phrases_dict.json>`；只保留全汉字、2–9 字、
  读音数等于字数的词组，每字取首读音。
- 「一 / 不」还原原调（`yí/yì → yī`，`bú → bù`），变调交由 `tone` 包。
- 存储：字符串分片而非 `Map` 字面量，规避 wasm 初始化 `local count too large`；
  `large_phrase_lookup` 首次访问时解析，四后端行为一致。

## 注意

- 不要把业务逻辑放进 `data`，也不要运行时修改这些全局表。
- 需要自定义词库时，用 `convert` 的 `add_pinyin_dict_resource` /
  `add_mutil_pinyin_dict_resource`，或 `input` 的 `add_user_dict`。

## 相关

- [API 文档](../docs/api.md#data-包)
- [架构设计](../docs/architecture.md)
- [测试策略](../docs/testing.md)