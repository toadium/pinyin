# API 文档

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

单字所有读音数组。

### get_short_pinyin

```moonbit
pub fn PinyinHelper::get_short_pinyin(str : String) -> String raise PinyinError
```

首字母格式。

### has_multi_pinyin

```moonbit
pub fn PinyinHelper::has_multi_pinyin(c : Char) -> Bool raise PinyinError
```

多音字检测（非汉字抛错）。

### add_*_dict_resource

```moonbit
pub fn PinyinHelper::add_pinyin_dict_resource(dict : Map[String, String]) -> Unit
pub fn PinyinHelper::add_mutil_pinyin_dict_resource(dict : Map[String, String]) -> Unit
```

追加自定义字典。

## ChineseHelper

繁简转换 + 汉字判断。

### is_chinese / is_traditional_chinese / contains_chinese

```moonbit
pub fn ChineseHelper::is_chinese(c : Char) -> Bool
pub fn ChineseHelper::is_traditional_chinese(c : Char) -> Bool
pub fn ChineseHelper::contains_chinese(str : String) -> Bool
```

### convert_to_simplified/traditional_chinese

```moonbit
pub fn ChineseHelper::convert_to_simplified_chinese(str : String) -> String
pub fn ChineseHelper::convert_to_traditional_chinese(str : String) -> String
```

### add_chinese_dict_resource

```moonbit
pub fn ChineseHelper::add_chinese_dict_resource(dict : Map[Int, Int]) -> Unit
```

## PinyinFormat

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark      // lǚ
  WithoutTone       // lü
  WithToneNumber    // lü3
  FirstLetter       // l
}
```

## PinyinError

```moonbit
pub(all) suberror PinyinError {
  PinyinError(String)
}
```