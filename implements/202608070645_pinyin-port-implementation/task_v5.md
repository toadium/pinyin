# 任务指令（v5）

## 动作
NEW

## 任务描述

在主包根目录创建 `pinyin_dicts.mbt`，从 `@data` 子包读取四个字典字面量并绑定为运行时 `Map` 视图常量：

```moonbit
/// 字典视图常量集合，从 @data 子包读取构建期内嵌的字面量并绑定为运行时 Map 视图。
/// 四个常量均为 pub(self) 可见性，仅主包内部可访问，不暴露给外部消费者。
/// 对应源库 pinyin_resource.cj 的资源加载逻辑（构建期内嵌替代运行时 IO）。

/// 繁体→简体汉字码点映射，2533 条，对应源库 CHINESE_MAP。
pub(self) let chinese_map : Map[Int, Int] = @data.chinese_dict

/// 单字拼音映射，20903 条，对应源库 PINYIN_TABLE。
pub(self) let pinyin_table : Map[String, String] = @data.pinyin_dict

/// 词组拼音映射，843 条，对应源库 MUTIL_PINYIN_TABLE。
pub(self) let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict

/// 通用拼音映射，82 条，对应源库 TONGYONG_PINYIN_TABLE。
pub(self) let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
```

预期文件路径：`pinyin_dicts.mbt`（主包根目录）。

验证要求：
- `moon check` 通过（exit code 0），`unused_package` 警告消除（主包非 test 源文件 `pinyin_dicts.mbt` 引用 `@data.xxx`），`text_segment_excceed` 警告持续（`data/pinyin_dict.mbt` 超 16384 行，设计变更，本任务不处理）
- `moon test` 全部通过（现有 26 用例不受影响，本任务不新增测试）

## 选择理由

四张字典视图是全部算法实现（`tone_conversion.mbt` 声调转换 / `pinyin_helper.mbt` 拼音转换 / `chinese_helper.mbt` 繁简互转）的运行时数据入口。R3 v4 已生成 `@data` 子包字面量（`pub let`，跨包可引用），本任务在主包建立 `pub(self)` 视图层，消除 `unused_package` 警告并为后续算法任务（R5 声调转换 / R6 拼音转换 / R7 繁简互转）提供包内可访问的字典引用。

四个常量紧密相关（均为字典视图，同属"全局 let 常量集合"），合并为一个任务符合粒度约定（1-3 个紧密相关类型）。底层优先：字典视图是算法实现的直接依赖，须先于算法任务完成。

## 任务上下文

摘录技术方案 `tech_v1.md` 相关条款：

### §4.2 字典存储与加载策略

- **构建期内嵌为 MoonBit 字面量**：四张字典在构建期通过脚本转写为 `data/*.mbt` 中的 `Map` 字面量，运行时直接构造为 `Map` 对象。
- **全局 `let` 常量集合**（`pinyin_dicts.mbt`）：四张字典各自以 `let` 绑定于顶层，`pub(self)` 可见性仅包内可访问。全局 `let` 绑定不可重新赋值，但 `Map` 对象内容可变（支持 `add_*` 原地合并）。
- **不依赖运行时文件系统与环境变量**：跨 wasm/js/native 三后端一致，无运行时 IO。

### §5.3 字典视图构造（`pinyin_dicts.mbt`）

主包 `pinyin_dicts.mbt` 从 `@data` 子包读取字面量并构造为运行时 `Map` 视图：

```moonbit
// 伪代码示意（非最终实现）
let chinese_map : Map[Int, Int] = @data.chinese_dict
let pinyin_table : Map[String, String] = @data.pinyin_dict
let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict
let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
```

- `@data` 子包导出四个 `let` 常量，主包通过 `import "pinyin/pinyin/data"` 引用，别名 `@data`。
- 主包 `pinyin_dicts.mbt` 重新绑定为 `pub(self)` 可见性，仅包内可访问。

### §10.1 移植映射表

| 源库模块 | MoonBit 包/文件 | 移植方式 |
|---------|---------------|---------|
| `pinyin_resource.cj`（71行） | `pinyin/pinyin_dicts.mbt` | 资源加载改为构建期内嵌，运行时直接构造 Map |

### §4.1 字典数据结构

| 字典 | 源库类型 | MoonBit 类型 | 容量 | 用途 |
|------|---------|------------|------|------|
| `CHINESE_MAP` | `HashMap<Rune, Rune>` | `Map[Int, Int]` | 2556 条 | 繁→简映射（码点→码点） |
| `PINYIN_TABLE` | `HashMap<String, String>` | `Map[String, String]` | 20903 条 | 单字拼音（汉字→逗号分隔多音） |
| `MUTIL_PINYIN_TABLE` | `HashMap<String, String>` | `Map[String, String]` | 约 856 条 | 词组拼音（词→逗号分隔拼音） |
| `TONGYONG_PINYIN_TABLE` | `HashMap<String, String>` | `Map[String, String]` | 83 条 | 通用拼音映射 |

### 命名映射

| 源库常量 | MoonBit 常量 | 可见性 |
|---------|------------|--------|
| `CHINESE_MAP` | `chinese_map` | `pub(self) let` |
| `PINYIN_TABLE` | `pinyin_table` | `pub(self) let` |
| `MUTIL_PINYIN_TABLE` | `mutil_pinyin_table` | `pub(self) let` |
| `TONGYONG_PINYIN_TABLE` | `tongyong_pinyin_table` | `pub(self) let` |

## 已有代码上下文

### R1 产出（项目骨架）

- `moon.mod`：模块名 `pinyin/pinyin`，license=MIT，零外部依赖
- `moon.pkg`：`import { "pinyin/pinyin/data" }`（别名 `@data`，已配置）
- `data/moon.pkg`：纯数据包，无 import
- `README.mbt.md`：占位

### R2 产出（基础类型）

- `pinyin_format.mbt`：`pub(all) enum PinyinFormat` 4 变体 + `name` 方法
- `pinyin_error.mbt`：`pub(all) suberror PinyinError` 单变体
- 本任务不依赖 R2 产出（字典视图不涉及基础类型）

### R3 v4 产出（字典字面量）

数据子包 `data/` 下四个 `pub let` 字面量文件（跨包可引用）：
- `data/chinese_dict.mbt`：`pub let chinese_dict : Map[Int, Int]`，2533 条（去重后）
- `data/mutil_pinyin_dict.mbt`：`pub let mutil_pinyin_dict : Map[String, String]`，843 条（去重后）
- `data/tongyong_pinyin_dict.mbt`：`pub let tongyong_pinyin_dict : Map[String, String]`，82 条
- `data/pinyin_dict.mbt`：`pub let pinyin_dict : Map[String, String]`，20903 条

### 当前编译状态

- `moon check` exit code 0，2 warnings，0 errors：
  - `Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`（本任务消除）
  - `Warning (0033) (text_segment_excceed)`（`pinyin_dict.mbt` 超 16384 行，本任务不处理）
- `moon test` Total 26, passed 26, failed 0

### 源库对应代码

源库 `pinyin_helper.cj:10-12` + `chinese_helper.cj:9`：
```cangjie
let CHINESE_MAP: HashMap<Rune, Rune> = PinyinResource.getChineseResource()
let PINYIN_TABLE: HashMap<String, String> = PinyinResource.getPinyinResource()
let MUTIL_PINYIN_TABLE: HashMap<String, String> = PinyinResource.getMutilPinyinResource()
let TONGYONG_PINYIN_TABLE: HashMap<String, String> = PinyinResource.getTongyongPinyinResource()
```

源库通过 `PinyinResource` 类在运行时从文件系统加载字典（`get_file_path.cj` 定位 + 文件读取）。MoonBit 移植改为构建期内嵌字面量，运行时直接引用 `@data` 子包常量，消除运行时 IO，跨三后端一致。

### 后续任务边界（本任务不创建）

- `tone_conversion.mbt`（R5 声调转换内部逻辑，引用 `chinese_map` / `pinyin_table` 等）
- `pinyin_helper.mbt`（R6 拼音转换，引用 `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table`）
- `chinese_helper.mbt`（R7 繁简互转，引用 `chinese_map`）
- `pinyin_spec.mbt`（R8 形式化契约）
- 测试文件新增（R9+）
- `README.mbt.md` 填充（R10）
- `text_segment_excceed` 警告消除（设计变更，留待后续评估）