# pinyin

MoonBit port of pinyin4cj: Chinese-to-pinyin conversion.

## 介绍

pinyin 是一个支持将汉字转换成拼音的库，输出的拼音格式可以自定义设置。移植自 Cangjie 库 `pinyin4cj`。

### 特性

- 支持词、句转换成拼音
- 支持常用简体/繁体中文字符转换成拼音
- 支持常见多音字符转换成拼音
- 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 支持常用简体、繁体中文字符互转
- 支持添加自定义字典
- 支持常用简体/繁体中文字符转换成通用拼音

## 软件架构

### 源码目录

```
.
├── src
│   ├── data
│   │   ├── chinese_dict.mbt
│   │   ├── mutil_pinyin_dict.mbt
│   │   ├── pinyin_dict.mbt
│   │   └── tongyong_pinyin_dict.mbt
│   ├── chinese_helper.mbt
│   ├── pinyin_dicts.mbt
│   ├── pinyin_error.mbt
│   ├── pinyin_format.mbt
│   ├── pinyin_helper.mbt
│   └── tone_conversion.mbt
├── doc
│   └── feature_api.md
├── scripts
│   └── gen_pinyin_dict.py
├── moon.mod
├── CHANGELOG.md
├── LICENSE
└── README.md
```

- `src/data` 存放字典字面量（由生成脚本从源库 `resource/pinyin.dict.txt` 转写）
- `src` 是库源码目录
- `doc` 存放库的特性文档
- `scripts` 存放字典生成脚本

## 使用说明

### 编译构建

```bash
moon check
moon test
```

### 功能示例

#### 繁体转简体

```mbt check
///|
test "readme_convert_to_simplified" {
  inspect(
    ChineseHelper::convert_to_simplified_chinese("臺，喪，麗"),
    content="台，丧，丽",
  )
}
```

#### 简体转繁体

```mbt check
///|
test "readme_convert_to_traditional" {
  inspect(
    ChineseHelper::convert_to_traditional_chinese("我是中国人"),
    content="我是中國人",
  )
}
```

#### 词、句转换成拼音

```mbt check
///|
test "readme_convert_to_pinyin_string" {
  inspect(
    PinyinHelper::convert_to_pinyin_string("我是中国人", " "),
    content="wǒ shì zhōng zhòng guó rén",
  )
}
```

#### 自定义输出格式

```mbt check
///|
test "readme_with_tone_number" {
  inspect(
    PinyinHelper::convert_to_pinyin_string(
      "中国",
      " ",
      format=PinyinFormat::WithToneNumber,
    ),
    content="zhong1 zhong4 guo2",
  )
}
```

#### 多音字转拼音集合

```mbt check
///|
test "readme_convert_to_pinyin_array" {
  debug_inspect(
    PinyinHelper::convert_to_pinyin_array('长'),
    content="[\"cháng\", \"zhǎng\"]",
  )
}
```

#### 繁简体转通用拼音

```mbt check
///|
test "readme_tongyong_pinyin" {
  debug_inspect(
    PinyinHelper::to_tongyong_pinyin_string_array('传'),
    content="[\"chuan2\", \"jhuan4\"]",
  )
}
```

#### 首字母格式

```mbt check
///|
test "readme_get_short_pinyin" {
  inspect(PinyinHelper::get_short_pinyin("中国"), content="z z g")
}
```

#### 多音字检测

```mbt check
///|
test "readme_has_multi_pinyin" {
  inspect(PinyinHelper::has_multi_pinyin('中'), content="true")
}
```

#### 汉字判断

```mbt check
///|
test "readme_is_chinese" {
  inspect(ChineseHelper::is_chinese('中'), content="true")
  inspect(ChineseHelper::contains_chinese("abc中"), content="true")
}
```

## 字典条目数

| 字典 | 条目数 | 类型 | 源库对应 |
|------|--------|------|----------|
| `chinese_map` | 2533 | `Map[Int, Int]` | `CHINESE_MAP` |
| `pinyin_table` | 20903 | `Map[String, String]` | `PINYIN_TABLE` |
| `mutil_pinyin_table` | 843 | `Map[String, String]` | `MUTIL_PINYIN_TABLE` |
| `tongyong_pinyin_table` | 82 | `Map[String, String]` | `TONGYONG_PINYIN_TABLE` |

## 字典生成

字典字面量由 `scripts/gen_pinyin_dict.py` 从源库 `pinyin4cj` 生成：

```bash
python scripts/gen_pinyin_dict.py
```

## 约束与限制

在下述版本验证通过：

| 编号 | 依赖构建工具 | 版本号 |
| ---- | ------------ | ------ |
| 1    | **moon**     | 0.1.20260713 |

## 开源协议

本项目基于 [MIT License](./LICENSE)，请自由的享受和参与开源。
