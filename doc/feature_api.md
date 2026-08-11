# pinyin 库

## 介绍

pinyin 是一个支持将汉字转换成拼音的 MoonBit 三方库，输出的拼音格式可以自定义设置。移植自 Cangjie 库 `pinyin4cj`。

## 1 中文转换到汉语拼音，支持多音字

前置条件：NA

场景：

1. 支持词、句转换成拼音
2. 支持常用简体/繁体中文字符转换成拼音
3. 支持常见多音字符转换成拼音
4. 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
5. 支持常用简体、繁体中文字符互转
6. 支持添加自定义字典
7. 支持通用拼音

约束：在词库中包含文字才能转换，字符 ü、声调符号、首字母只对汉语拼音有效

### 1.1 支持常用简体/繁体中文字符互转

可以将输入的繁体字符串(或简体字符串)转换成简体字符串(或繁体字符串)。

#### 1.1.1 主要接口

```moonbit
pub fn ChineseHelper::convert_to_simplified_chinese(String) -> String
pub fn ChineseHelper::convert_to_traditional_chinese(String) -> String
```

#### 1.1.2 示例

##### 繁体转简体

```moonbit
let pinyin = ChineseHelper::convert_to_simplified_chinese("臺，喪，麗")
println(pinyin)
// 输出: 台，丧，丽
```

##### 简体转繁体

```moonbit
let pinyin = ChineseHelper::convert_to_traditional_chinese("我是中国人")
println(pinyin)
// 输出: 我是中國人
```

### 1.2 支持词、句转换成拼音

可以将包含多音字或繁体字的词或句转成拼音

#### 1.2.1 主要接口

```moonbit
pub fn PinyinHelper::convert_to_pinyin_string(String, String, format~ : PinyinFormat = WithToneMark) -> String raise PinyinError
```

#### 1.2.2 示例

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_string("我是中国人", " ")
println(pinyin)
// 输出: wǒ shì zhōng zhòng guó rén
```

### 1.3 支持 Unicode 格式的字符ü、支持声调符号、支持拼音首字母的输出格式

可以将包含多音字或繁体字的词或句转成拼音，可以设置拼音输出格式

#### 1.3.1 主要接口

```moonbit
pub fn PinyinHelper::convert_to_pinyin_string(String, String, format~ : PinyinFormat = WithToneMark) -> String raise PinyinError
pub fn PinyinHelper::convert_to_pinyin_string_traditional(String, String, format~ : PinyinFormat = WithToneMark) -> String raise PinyinError
```

#### 1.3.2 包含简体中文字符转拼音示例

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_string("中国", " ", format=PinyinFormat::WithToneNumber)
println(pinyin)
// 输出: zhong1 zhong4 guo2
```

#### 1.3.3 包含繁体中文字符转拼音示例

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_string_traditional("中國", " ", format=PinyinFormat::WithToneNumber)
println(pinyin)
// 输出: zhong1 zhong4 guo2
```

### 1.4 支持添加自定义字典

若繁体字和简体字互转没有达到预期效果，用户可添加自定义中文字典

若词句转拼音结果没有达到预期效果，用户可添加自定义拼音字典和拼音组合字典

#### 1.4.1 主要接口

```moonbit
pub fn PinyinHelper::add_pinyin_dict_resource(Map[String, String]) -> Unit
pub fn PinyinHelper::add_mutil_pinyin_dict_resource(Map[String, String]) -> Unit
pub fn ChineseHelper::add_chinese_dict_resource(Map[Int, Int]) -> Unit
```

#### 1.4.2 示例

##### 自定义拼音字典

```moonbit
let map : Map[String, String] = { "上": "shǎng" }
PinyinHelper::add_pinyin_dict_resource(map)
let pinyin = PinyinHelper::convert_to_pinyin_string("上午", " ")
println(pinyin)
// 输出: shǎng wǔ
```

##### 自定义拼音组合字典

```moonbit
let map : Map[String, String] = { "阿弥陀佛": "ā,mí,tuó,fó" }
PinyinHelper::add_mutil_pinyin_dict_resource(map)
let pinyin = PinyinHelper::convert_to_pinyin_string("阿弥陀佛", " ")
println(pinyin)
// 输出: ā mí tuó fó
```

##### 自定义中文字典

```moonbit
let map : Map[Int, Int] = { 0x7691: 0x75C7 }  // 癥 → 症
ChineseHelper::add_chinese_dict_resource(map)
let pinyin = ChineseHelper::convert_to_simplified_chinese("癥")
println(pinyin)
// 输出: 症
```

### 1.5 支持常见多音字转换成拼音

将多音字的转换成拼音集合，集合中包含所有读音

#### 1.5.1 主要接口

```moonbit
pub fn PinyinHelper::convert_to_pinyin_array(Char, format~ : PinyinFormat = WithToneMark) -> Array[String]
```

#### 1.5.2 示例

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_array('长')
println(pinyin)
// 输出: ["cháng", "zhǎng"]
```

### 1.6 支持常用简体/繁体中文字符转换成拼音

获取单个汉字（简体和繁体）的所有指定格式的汉语拼音

#### 1.6.1 主要接口

```moonbit
pub fn PinyinHelper::convert_to_pinyin_array(Char, format~ : PinyinFormat = WithToneMark) -> Array[String]
```

#### 1.6.2 示例

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_array('嚴')
println(pinyin)
// 输出: ["yán"]
```

### 1.7 支持常用简体/繁体中文字符转换成通用拼音

获取单个汉字（简体和繁体）的数字音标的通用拼音

#### 1.7.1 主要接口

```moonbit
pub fn PinyinHelper::to_tongyong_pinyin_string_array(Char) -> Array[String]
```

#### 1.7.2 示例

```moonbit
let simplePinyin = PinyinHelper::to_tongyong_pinyin_string_array('傳')
let traditionalPinyin = PinyinHelper::to_tongyong_pinyin_string_array('传')
println(simplePinyin)
println(traditionalPinyin)
// 输出: ["chuan2", "jhuan4"]
//       ["chuan2", "jhuan4"]
```

## 2 其他接口

### 2.1 ChineseHelper

中文转换器

```moonbit
pub fn ChineseHelper::is_traditional_chinese(Char) -> Bool
pub fn ChineseHelper::is_chinese(Char) -> Bool
pub fn ChineseHelper::contains_chinese(String) -> Bool
```

### 2.2 PinyinFormat

定义输出汉语拼音格式

| 格式 | 结果 |
| --------- | -----|
|  WithToneMark   | lǚ   |
|  WithoutTone     | lü   |
|  WithToneNumber | lü3  |
|  FirstLetter     | l    |

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark
  WithoutTone
  WithToneNumber
  FirstLetter
}

pub fn PinyinFormat::name(Self) -> String
```

### 2.3 PinyinHelper

拼音转换器

```moonbit
pub fn PinyinHelper::get_short_pinyin(String) -> String raise PinyinError
pub fn PinyinHelper::has_multi_pinyin(Char) -> Bool raise PinyinError
```

### 2.4 PinyinError

pinyin 异常类型

```moonbit
pub(all) suberror PinyinError {
  PinyinError(String)
}
```