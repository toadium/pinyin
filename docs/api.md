# API 文档

> 黑盒位置调用需通过 `@pinyin.` 限定访问宿主包类型与方法。枚举变体在类型可推断位置（如 `format=` 参数）可裸用。

## PinyinHelper

拼音转换主入口。

### convert_to_pinyin_string

```moonbit
pub fn PinyinHelper::convert_to_pinyin_string(
  str : String,
  separator : String,
  format : PinyinFormat~ = PinyinFormat::WithToneMark
) -> String raise PinyinError
```

词句转拼音字符串。默认带声调标记。

### convert_to_pinyin_string_traditional

```moonbit
pub fn PinyinHelper::convert_to_pinyin_string_traditional(
  str : String,
  separator : String,
  format : PinyinFormat~ = PinyinFormat::WithToneMark
) -> String raise PinyinError
```

先繁→简再转拼音。

### convert_to_pinyin_array

```moonbit
pub fn PinyinHelper::convert_to_pinyin_array(
  c : Char,
  format : PinyinFormat~ = PinyinFormat::WithToneMark
) -> Array[String]
```

单字所有读音数组。非汉字返回 `[]`。

### get_short_pinyin

```moonbit
pub fn PinyinHelper::get_short_pinyin(str : String) -> String raise PinyinError
```

首字母格式。空串抛 `PinyinError`。

### has_multi_pinyin

```moonbit
pub fn PinyinHelper::has_multi_pinyin(c : Char) -> Bool raise PinyinError
```

多音字检测。非汉字抛 `PinyinError`。

### to_tongyong_pinyin_string_array

```moonbit
pub fn PinyinHelper::to_tongyong_pinyin_string_array(char : Char) -> Array[String]
```

通用拼音数组。非汉字返回 `[]`。

### add_pinyin_dict_resource

```moonbit
pub fn PinyinHelper::add_pinyin_dict_resource(dict : Map[String, String]) -> Unit
```

追加自定义单字拼音字典（原地合并，键冲突新值覆盖）。

### add_mutil_pinyin_dict_resource

```moonbit
pub fn PinyinHelper::add_mutil_pinyin_dict_resource(dict : Map[String, String]) -> Unit
```

追加自定义词组拼音字典（原地合并）。

## ChineseHelper

繁简转换 + 汉字判断。

### is_chinese

```moonbit
pub fn ChineseHelper::is_chinese(c : Char) -> Bool
```

判断字符是否为汉字（CJK 统一表意文字 U+4E00-U+9FFF 或汉字零 U+3007）。

### is_traditional_chinese

```moonbit
pub fn ChineseHelper::is_traditional_chinese(c : Char) -> Bool
```

判断字符是否为繁体汉字（在 `chinese_map` 中存在映射）。

### contains_chinese

```moonbit
pub fn ChineseHelper::contains_chinese(str : String) -> Bool
```

判断字符串是否包含汉字。

### convert_to_simplified_chinese

```moonbit
pub fn ChineseHelper::convert_to_simplified_chinese(str : String) -> String
```

繁→简转换：逐字符查 `chinese_map`，命中替换为简体码点，未命中原样。

### convert_to_traditional_chinese

```moonbit
pub fn ChineseHelper::convert_to_traditional_chinese(str : String) -> String
```

简→繁转换：逐字符遍历 `chinese_map` 反查，命中替换为键，未命中原样。

### add_chinese_dict_resource

```moonbit
pub fn ChineseHelper::add_chinese_dict_resource(dict : Map[Int, Int]) -> Unit
```

追加自定义繁简映射（原地合并）。

## PinyinFormat

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark      // lǚ
  WithoutTone       // lü
  WithToneNumber    // lü3
  FirstLetter       // l
}
```

输出格式枚举，4 个变体分别对应：带声调标记 / 不带声调 / 带声调数字 / 首字母。

### name

```moonbit
pub fn PinyinFormat::name(self : PinyinFormat) -> String
```

返回格式名称字符串（大写下划线形式）。

## PinyinError

```moonbit
pub(all) suberror PinyinError {
  PinyinError(String)
}
```

统一错误类型，自动提升 `Error`。用 `raise PinyinError("msg")` 抛错，`try expr catch { PinyinError::PinyinError(msg) => ... }` 捕获。