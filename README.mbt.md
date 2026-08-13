# pinyin

MoonBit port of [pinyin4cj](https://github.com/sbigger/pinyin4cj): Chinese-to-pinyin conversion library.

支持词/句转拼音、简繁互转、多音字、通用拼音、自定义字典，跨 wasm/js/native 三后端。

## 快速开始

```mbt check
///|
test "quick_start" {
  // 词句转拼音（带声调标记）
  inspect(
    PinyinHelper::convert_to_pinyin_string("我是中国人", " "),
    content="wǒ shì zhōng guó rén",
  )
  // 带声调数字
  inspect(
    PinyinHelper::convert_to_pinyin_string(
      "我是中国人",
      " ",
      format=PinyinFormat::WithToneNumber,
    ),
    content="wo3 shi4 zhong1 guo2 ren2",
  )
  // 首字母
  inspect(PinyinHelper::get_short_pinyin("我是中国人"), content="wszgr")
  // 繁体转简体
  inspect(
    ChineseHelper::convert_to_simplified_chinese("臺，喪，麗"),
    content="台，丧，丽",
  )
  // 简体转繁体
  inspect(
    ChineseHelper::convert_to_traditional_chinese("我是中国人"),
    content="我是中國人",
  )
}
```

## API 概览

### PinyinHelper

| 方法 | 签名 | 说明 |
|------|------|------|
| `convert_to_pinyin_string` | `(str, sep, format~=WithToneMark) -> String raise PinyinError` | 词句转拼音 |
| `convert_to_pinyin_string_traditional` | `(str, sep, format~=WithToneMark) -> String raise PinyinError` | 繁体词句转拼音（先繁→简） |
| `convert_to_pinyin_array` | `(c, format~=WithToneMark) -> Array[String]` | 单字所有读音 |
| `get_short_pinyin` | `(str) -> String raise PinyinError` | 首字母格式 |
| `has_multi_pinyin` | `(c) -> Bool raise PinyinError` | 是否多音字 |
| `to_tongyong_pinyin_string_array` | `(char) -> Array[String]` | 通用拼音 |
| `add_pinyin_dict_resource` | `(dict) -> Unit` | 追加单字拼音字典 |
| `add_mutil_pinyin_dict_resource` | `(dict) -> Unit` | 追加词组拼音字典 |

### ChineseHelper

| 方法 | 签名 | 说明 |
|------|------|------|
| `convert_to_simplified_chinese` | `(str) -> String` | 繁→简 |
| `convert_to_traditional_chinese` | `(str) -> String` | 简→繁（O(n) 反查） |
| `is_chinese` | `(c) -> Bool` | 是否汉字 |
| `is_traditional_chinese` | `(c) -> Bool` | 是否繁体字 |
| `contains_chinese` | `(str) -> Bool` | 是否含汉字 |
| `add_chinese_dict_resource` | `(dict) -> Unit` | 追加繁简字典 |

### PinyinFormat

`WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`

## 示例

### 自定义输出格式

```mbt check
///|
test "format_example" {
  inspect(
    PinyinHelper::convert_to_pinyin_string(
      "我是中国共产主义接班人。",
      " ",
      format=PinyinFormat::WithoutTone,
    ),
    content="wo shi zhong guo gong chan zhu yi jie ban ren 。",
  )
}
```

### 多音字

```mbt check
///|
test "multi_pinyin_example" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array(
      '长',
      format=PinyinFormat::WithToneMark,
    ),
    content="[\"cháng\", \"zhǎng\"]",
  )
  assert_true(PinyinHelper::has_multi_pinyin('长'))
}
```

### 通用拼音

```mbt check
///|
test "tongyong_example" {
  debug_inspect(
    PinyinHelper::to_tongyong_pinyin_string_array('傳'),
    content="[\"chuan2\", \"jhuan4\"]",
  )
}
```

### 自定义字典

```mbt check
///|
test "custom_dict_example" {
  let dict : Map[String, String] = Map([])
  dict["阿弥陀佛"] = "ā,mí,tuó,fó"
  PinyinHelper::add_mutil_pinyin_dict_resource(dict)
  inspect(
    PinyinHelper::convert_to_pinyin_string(
      "阿弥陀佛",
      " ",
      format=PinyinFormat::WithToneMark,
    ),
    content="ā mí tuó fó",
  )
  mutil_pinyin_table.remove("阿弥陀佛")
}
```

## 字典数据

内置四张字典（构建期内嵌为 MoonBit 字面量，无运行时 IO）：

| 字典 | 条目数 | 用途 |
|------|--------|------|
| `pinyin_table` | 20903 | 单字拼音 |
| `mutil_pinyin_table` | 843 | 词组拼音 |
| `chinese_map` | 2533 | 繁→简映射 |
| `tongyong_pinyin_table` | 82 | 通用拼音 |

## 错误处理

```mbt check
///|
test "error_handling" {
  try PinyinHelper::convert_to_pinyin_string("", " ") catch {
    PinyinError::PinyinError(msg) =>
      inspect(msg, content="Please enter a word or sentence")
  } noraise {
    _ => fail("expected error")
  }
}
```

## License

MIT (对齐源库 pinyin4cj)
