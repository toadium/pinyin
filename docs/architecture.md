# 架构设计

## 包依赖关系

```
examples ──> pinyin (根包) ──> data
```

线性无环，三层结构。

## 根包（pinyin）

核心 API 包，包含拼音转换的所有公开接口。

### 模块划分

| 文件 | 职责 | 行数 |
|------|------|------|
| `pinyin_helper.mbt` | 拼音转换主入口（PinyinHelper 命名空间） | 190 |
| `chinese_helper.mbt` | 繁简转换 + 汉字判断（ChineseHelper 命名空间） | 88 |
| `tone_conversion.mbt` | 声调转换内部逻辑 | 104 |
| `pinyin_format.mbt` | 输出格式枚举 | 20 |
| `pinyin_error.mbt` | 统一错误类型 | 7 |
| `pinyin_dicts.mbt` | 字典视图常量 | 20 |

### 公开 API

- `PinyinHelper`：convert_to_pinyin_string / convert_to_pinyin_array / get_short_pinyin / has_multi_pinyin / add_*_dict_resource
- `ChineseHelper`：is_chinese / is_traditional_chinese / contains_chinese / convert_to_simplified/traditional_chinese / add_chinese_dict_resource
- `PinyinFormat`：WithToneMark / WithoutTone / WithToneNumber / FirstLetter
- `PinyinError`：统一错误类型

## data 包

纯数据包，零依赖。包含 4 张字典：

| 字典 | 类型 | 条目数 | 说明 |
|------|------|--------|------|
| `chinese_dict` | Map[Int, Int] | 2533 | 繁→简码点映射 |
| `pinyin_dict` | Map[String, String] | 20903 | 单字拼音（分 11 段 merge） |
| `mutil_pinyin_dict` | Map[String, String] | 843 | 词组拼音 |
| `tongyong_pinyin_dict` | Map[String, String] | 82 | 通用拼音 |

### pinyin_dict 分段设计

`pinyin_dict.mbt`（20962 行）分 11 段（seg0..seg10）后 `.merge()` 合并，规避单段文本过长警告。

## examples 包

示例包，依赖根包。14 个示例测试覆盖所有公开 API。

## 多后端

- `supported_targets = "+wasm+wasm-gc+js+native"`
- 四后端 60/60 全通过
- 无 WASM local count 问题（字典用 Map 字面量，非大 match）