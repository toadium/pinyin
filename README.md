<div align="center">
<h1>pinyin</h1>
</div>

<p align="center">
<img alt="" src="https://img.shields.io/badge/release-v0.1.0-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/build-pass-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/moon-0.1.20260713-brightgreen" style="display: inline-block;" />
<img alt="" src="https://img.shields.io/badge/license-MIT-brightgreen" style="display: inline-block;" />
</p>

## 介绍

pinyin 是一个支持将汉字转换成拼音的 MoonBit 三方库，输出的拼音格式可以自定义设置。移植自 Cangjie 库 [`pinyin4cj`](https://gitcode.com/pinyin4cj/pinyin4cj)。

### 特性

- 🚀 支持词、句转换成拼音

- 💪 支持常用简体/繁体中文字符转换成拼音

- 🛠️ 支持常见多音字符转换成拼音

- 🌍 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式

- 💪 支持常用简体、繁体中文字符互转

- 🚀 支持添加自定义字典

- 🛠️ 支持常用简体/繁体中文字符转换成通用拼音

## 软件架构

### 源码目录

```
.
├── src
│   ├── data
│   │   ├── chinese_dict.mbt           # 繁→简码点映射（2533 条）
│   │   ├── mutil_pinyin_dict.mbt      # 词组拼音（843 条）
│   │   ├── pinyin_dict.mbt            # 单字拼音（20903 条）
│   │   └── tongyong_pinyin_dict.mbt  # 通用拼音（82 条）
│   ├── chinese_helper.mbt             # ChineseHelper：繁简转换、汉字判断
│   ├── pinyin_dicts.mbt              # 四张字典视图常量
│   ├── pinyin_error.mbt              # PinyinError 错误类型
│   ├── pinyin_format.mbt             # PinyinFormat 格式枚举
│   ├── pinyin_helper.mbt             # PinyinHelper：拼音转换核心 API
│   └── tone_conversion.mbt           # 声调转换内部逻辑
├── doc
│   └── feature_api.md                # API 文档
├── scripts
│   └── gen_pinyin_dict.py            # 字典生成脚本
├── moon.mod                           # 模块元数据
├── CHANGELOG.md                       # 变更日志
├── LICENSE                            # MIT 协议
└── README.md
```

- `src/data` 存放字典字面量（由生成脚本从源库转写）
- `src` 是库源码目录
- `doc` 存放库的特性文档
- `scripts` 存放字典生成脚本

### 接口说明

| 类 | 方法 | 说明 |
| --- | --- | --- |
| `PinyinHelper` | `convert_to_pinyin_string` | 词句转拼音字符串 |
| `PinyinHelper` | `convert_to_pinyin_string_traditional` | 繁体词句转拼音 |
| `PinyinHelper` | `convert_to_pinyin_array` | 单字转拼音数组 |
| `PinyinHelper` | `get_short_pinyin` | 首字母格式拼音 |
| `PinyinHelper` | `has_multi_pinyin` | 多音字检测 |
| `PinyinHelper` | `to_tongyong_pinyin_string_array` | 通用拼音数组 |
| `PinyinHelper` | `add_pinyin_dict_resource` | 添加自定义拼音字典 |
| `PinyinHelper` | `add_mutil_pinyin_dict_resource` | 添加自定义词组字典 |
| `ChineseHelper` | `convert_to_simplified_chinese` | 繁体转简体 |
| `ChineseHelper` | `convert_to_traditional_chinese` | 简体转繁体 |
| `ChineseHelper` | `is_chinese` | 汉字判断 |
| `ChineseHelper` | `is_traditional_chinese` | 繁体汉字判断 |
| `ChineseHelper` | `contains_chinese` | 包含汉字判断 |
| `ChineseHelper` | `add_chinese_dict_resource` | 添加自定义中文字典 |

## 使用说明

### 编译构建

```bash
moon check     # 类型检查
moon test      # 运行测试
moon fmt       # 格式化
moon info      # 生成接口文件
```

### 功能示例

#### 繁体转简体

```moonbit
let pinyin = ChineseHelper::convert_to_simplified_chinese("臺，喪，麗")
println(pinyin)
// 输出: 台，丧，丽
```

#### 简体转繁体

```moonbit
let pinyin = ChineseHelper::convert_to_traditional_chinese("我是中国人")
println(pinyin)
// 输出: 我是中國人
```

#### 词、句转换成拼音

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_string("我是中国人", " ")
println(pinyin)
// 输出: wǒ shì zhōng zhòng guó rén
```

#### 自定义输出格式

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_string("中国", " ", format=PinyinFormat::WithToneNumber)
println(pinyin)
// 输出: zhong1 zhong4 guo2
```

#### 添加自定义拼音字典

```moonbit
let map : Map[String, String] = { "上": "shǎng" }
PinyinHelper::add_pinyin_dict_resource(map)
let pinyin = PinyinHelper::convert_to_pinyin_string("上午", " ")
println(pinyin)
// 输出: shǎng wǔ
```

#### 添加自定义拼音组合字典

```moonbit
let map : Map[String, String] = { "阿弥陀佛": "ā,mí,tuó,fó" }
PinyinHelper::add_mutil_pinyin_dict_resource(map)
let pinyin = PinyinHelper::convert_to_pinyin_string("阿弥陀佛", " ")
println(pinyin)
// 输出: ā mí tuó fó
```

#### 添加自定义中文字典

```moonbit
let map : Map[Int, Int] = { 0x7691: 0x75C7 }  // 癥 → 症
ChineseHelper::add_chinese_dict_resource(map)
let pinyin = ChineseHelper::convert_to_simplified_chinese("癥")
println(pinyin)
// 输出: 症
```

#### 多音字转拼音集合

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_array('长')
println(pinyin)
// 输出: ["cháng", "zhǎng"]
```

#### 繁简体转拼音

```moonbit
let pinyin = PinyinHelper::convert_to_pinyin_array('嚴')
println(pinyin)
// 输出: ["yán"]
```

#### 繁简体转通用拼音

```moonbit
let simplePinyin = PinyinHelper::to_tongyong_pinyin_string_array('傳')
let traditionalPinyin = PinyinHelper::to_tongyong_pinyin_string_array('传')
println(simplePinyin)
println(traditionalPinyin)
// 输出: ["chuan2", "jhuan4"]
//       ["chuan2", "jhuan4"]
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

## 参与贡献

欢迎给我们提交PR，欢迎给我们提交Issue，欢迎参与任何形式的贡献。
