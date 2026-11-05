# pinyin 项目申报书

> 2026 MoonBit 国产基础软件开源大赛参赛申报 | 方向：开发者工具 | 申报日期：2026-11-05

---

## 基本信息

- 项目名称：pinyin：MoonBit 拼音转换库
- 参赛者：walkzzz
- 联系方式：13689047817 745244185@qq.com
- GitHub 仓库链接：https://github.com/toadium/pinyin.git
- mooncakes 包名：`walkzzz/pinyin`
- 项目方向：开发者工具 — 中文拼音转换核心库
- 是否为移植项目：是（从 pinyin4cj 仓颉版移植，完整移植 pinyin_helper + chinese_helper 全部 API）

---

## 项目简介

pinyin 是一个 MoonBit 拼音转换库，提供完整的汉字→拼音转换能力：单字/词句转拼音 + 繁简互转 + 多音字 + 通用拼音 + 4 种声调格式（带调标记 / 无调 / 数字调 / 首字母）+ 自定义字典扩展。库以 Map 字面量内嵌 4 张字典（共 24361 条），构建期固化，无运行时 IO，四后端（wasm / wasm-gc / js / native）全通过。

项目从仓颉版 pinyin4cj 移植到 MoonBit，**完整移植** pinyin_helper 与 chinese_helper 全部 API，逐函数手动将 camelCase 转为 snake_case，异常改用 `raise PinyinError`，字典内嵌为 MoonBit Map 字面量。源数据来自 pinyin4cj 字典资源（单字拼音 20903 条、词组拼音 843 条、繁简映射 2533 条、通用拼音 82 条）。

mooncakes 生态调研确认：截至 2026-11-05，mooncakes 全量 31909 个包中匹配 pinyin 的仅 2 个——`walkzzz/pinyin`（本项目同源发布版）与 `wjhfather/pinyin-toolkit`（异构方案，基于 Unicode 17.0 Unihan 数据，定位拼音规范化+模糊匹配+搜索索引）。本项目是 mooncakes 上 **pinyin4cj 移植线的唯一代表**，填补 MoonBit 生态汉字→拼音转换的空白。

---

## 当前完成状态（v0.1.1，合并内部迭代 0.1.2~0.1.5）

| 指标 | 数值 |
|------|------|
| 包数 | **3**（根包 pinyin + data + examples） |
| 测试数 | **60 / 后端**（四后端共 240 测试全通过） |
| 后端覆盖 | ✅ **四后端全绿**（wasm / wasm-gc / js / native） |
| 工程严格度 | ✅ `--warn-list +73 --deny-warn` 零警告零错误 |
| Warnings | **0** |
| Errors | **0** |
| 字典条目总数 | **24361**（chinese 2533 + pinyin 20903 + mutil 843 + tongyong 82） |
| 公开 API | **18**（PinyinHelper 8 + ChineseHelper 6 + PinyinFormat 4 变体 + PinyinError） |
| 声调格式 | 4 种（WithToneMark / WithoutTone / WithToneNumber / FirstLetter） |
| 多音字 | �% ✅ 支持（convert_to_pinyin_array 返回多读音，has_multi_pinyin 检测） |
| 繁简互转 | ✅ 繁→简 + 简→繁 |
| 通用拼音 | ✅ to_tongyong_pinyin_string_array |
| 自定义字典 | ✅ add_pinyin_dict_resource / add_mutil_pinyin_dict_resource / add_chinese_dict_resource |
| 字典视图共享 | ✅ 根包视图与 data 包共享同一 Map 引用（非拷贝） |
| mooncakes 发布 | ✅ `walkzzz/pinyin@0.1.0`（32 下载） |
| 版本迭代 | **5** 轮内部迭代（v0.1.0 ~ v0.1.5），对外发布 v0.1.1 |
| 工具链 | MoonBit v0.1.20260713 |

---

## 技术方案

### 三包线性架构

```
data（零依赖纯数据包：4 张字典字面量）
  ↑
pinyin（根包：核心 API + 字典视图常量 + 测试）
  ↑
examples（示例包：14 个示例测试，依赖根包）
```

线性无环依赖，data 零依赖可独立复用。源码位于仓库根目录（非 src/ 子目录），对齐 chrono_tz-mbt 约定。

### 字典内嵌与分段合并

4 张字典以 MoonBit Map 字面量 `{ k => v, ... }` 构建期固化，无运行时 IO：

| 字典 | 类型 | 条目数 | 说明 |
|------|------|--------|------|
| `chinese_dict` | `Map[Int, Int]` | 2533 | 繁→简码点映射 |
| `pinyin_dict` | `Map[String, String]` | 20903 | 单字拼音（分 11 段 merge） |
| `mutil_pinyin_dict` | `Map[String, String]` | 843 | 词组拼音 |
| `tongyong_pinyin_dict` | `Map[String, String]` | 82 | 通用拼音 |

`pinyin_dict.mbt`（20962 行）分 11 段（seg0..seg10）后 `.merge()` 合并，规避单段文本过长警告。根包 `pinyin_dicts.mbt` 的 `chinese_map` / `pinyin_table` / `mutil_pinyin_table` / `tongyong_pinyin_table` 与 data 包共享同一 Map 对象引用（非拷贝），`add_*_dict_resource` 的自定义追加对两者均可见。

### 声调转换内部逻辑

`tone_conversion.mbt` 处理带调元音与声调数字/无调互转：
- `convert_with_tone_number`：每音节仅处理首个带调元音，未找到则追加 "5"（轻声），ü 替换为 v
- `convert_without_tone`：逐字符替换所有带调元音为对应无调元音，ü 替换为 v
- `format_pinyin`：按 PinyinFormat 分发（match 模式匹配，比源库字符串比较更地道）

### 错误处理

采用 MoonBit `pub(all) suberror PinyinError { PinyinError(String) }`，自动提升 `Error`。`convert_to_pinyin_string` / `get_short_pinyin` / `has_multi_pinyin` 等方法用 `raise PinyinError("msg")` 抛错，调用方用 `try expr catch { PinyinError::PinyinError(msg) => ... }` 捕获。

### 类型映射

| MoonBit | 说明 | 示例 |
|---------|------|------|
| `PinyinHelper` | 拼音转换主入口（8 方法） | `PinyinHelper::convert_to_pinyin_string("中国", " ")` |
| `ChineseHelper` | 繁简转换 + 汉字判断（6 方法） | `ChineseHelper::convert_to_simplified_chinese("臺")` |
| `PinyinFormat` | 输出格式枚举（4 变体） | `WithToneMark / WithoutTone / WithToneNumber / FirstLetter` |
| `PinyinError` | 统一错误类型 | `raise PinyinError("非汉字字符")` |

---

## 核心功能范围

### PinyinHelper — 拼音转换主入口

- `convert_to_pinyin_string(str, separator, format?) -> String raise PinyinError` — 词句转拼音字符串
- `convert_to_pinyin_string_traditional(str, separator, format?) -> String raise PinyinError` — 先繁→简再转拼音
- `convert_to_pinyin_array(c, format?) -> Array[String]` — 单字所有读音数组（多音字）
- `get_short_pinyin(str) -> String raise PinyinError` — 首字母格式
- `has_multi_pinyin(c) -> Bool raise PinyinError` — 多音字检测
- `to_tongyong_pinyin_string_array(char) -> Array[String]` — 通用拼音数组
- `add_pinyin_dict_resource(dict) -> Unit` — 追加自定义单字拼音字典
- `add_mutil_pinyin_dict_resource(dict) -> Unit` — 追加自定义词组拼音字典

### ChineseHelper — 繁简转换 + 汉字判断

- `is_chinese(c) -> Bool` — 汉字判断（CJK U+4E00-U+9FFF 或汉字零 U+3007）
- `is_traditional_chinese(c) -> Bool` — 繁体汉字判断
- `contains_chinese(str) -> Bool` — 包含汉字判断
- `convert_to_simplified_chinese(str) -> String` — 繁→简
- `convert_to_traditional_chinese(str) -> String` — 简→繁
- `add_chinese_dict_resource(dict) -> Unit` — 追加自定义繁简映射

### PinyinFormat — 输出格式枚举

```moonbit
pub(all) enum PinyinFormat {
  WithToneMark      // lǚ
  WithoutTone       // lü
  WithToneNumber    // lü3
  FirstLetter       // l
}
```

### 质量与测试

| 测试文件 | 类型 | 测试数 | 覆盖维度 |
|----------|------|--------|----------|
| `pinyin_easy_wbtest.mbt` | 白盒 | 13 | 声调转换内部逻辑、字典查找 |
| `pinyin_mid_test.mbt` | 黑盒 | 19 | 正向用例、格式转换、自定义字典、共享引用 |
| `pinyin_difficult_test.mbt` | 黑盒 | 5 | 字典完整性（条目数、采样、边界） |
| `examples/*.mbt` | 黑盒 | 14 | 示例测试（chinese 2 + pinyin_helper 5 + array 4 + custom 3） |
| `README.mbt.md` | 可执行 | 11 | README 可执行测试块 |
| **总计** | | **60 / 后端** | **白盒 + 黑盒 + 示例 + 文档可执行** |

四后端共 240 测试全通过，严格模式 `--warn-list +73 --deny-warn` 零警告零错误。

---

## 项目架构（3 个包）

```
pinyin/                           # 根包 — 核心 API（源码在仓库根目录）
├── moon.mod / moon.pkg           #   模块元数据 + 根包依赖声明
├── pinyin_helper.mbt             #   PinyinHelper 命名空间（8 方法）
├── chinese_helper.mbt            #   ChineseHelper 命名空间（6 方法）
├── tone_conversion.mbt           #   声调转换内部逻辑
├── pinyin_format.mbt             #   PinyinFormat 枚举（4 变体）
├── pinyin_error.mbt              #   PinyinError 错误类型
├── pinyin_dicts.mbt              #   字典视图常量（与 data 包共享引用）
├── pinyin_easy_wbtest.mbt        #   白盒测试（13）
├── pinyin_mid_test.mbt           #   黑盒测试（19）
├── pinyin_difficult_test.mbt     #   黑盒测试（5）
├── data/                         # 字典数据包（零依赖）
│   ├── moon.pkg                  #   纯数据包，无 import
│   ├── chinese_dict.mbt          #   繁→简映射（2533 条）
│   ├── pinyin_dict.mbt           #   单字拼音（20903 条，分 11 段 merge）
│   ├── mutil_pinyin_dict.mbt     #   词组拼音（843 条）
│   └── tongyong_pinyin_dict.mbt  #   通用拼音（82 条）
├── examples/                     # 示例包（14 个示例测试）
│   ├── moon.pkg
│   ├── chinese_helper_example.mbt
│   ├── pinyin_helper_example.mbt
│   ├── pinyin_array_example.mbt
│   └── custom_dict_example.mbt
├── docs/                         # 开发文档（4 份）
│   ├── roadmap.md
│   ├── architecture.md
│   ├── api.md
│   └── testing.md
├── scripts/
│   └── gen_pinyin_dict.py        #   字典生成脚本（从 pinyin4cj 转写）
├── AGENTS.md                     # 项目规范
├── CHANGELOG.md                  # 变更日志
├── README.md                     # 项目文档
├── README.mbt.md                 # mooncakes 发布文档（含可执行测试）
└── LICENSE                       # MIT
```

---

## 版本交付计划

| 版本 | 交付内容 | 验收标准 | 实际状态 |
|------|---------|---------|---------|
| v0.1.0 | 核心移植：pinyin4cj Cangjie → MoonBit | 4 张字典 + PinyinHelper + ChineseHelper + PinyinFormat + 自定义字典 | ✅ 完成 |
| v0.1.1 | 工程化：src/ 布局 + LICENSE + CI + examples + 申报书 | inspect→debug_inspect，构建零警告 | ✅ 完成 |
| v0.1.2 | 源码布局重构：src/ → 根目录 + 多后端 + AGENTS.md + docs/ | 四后端 60/60 × 4 | ✅ 完成 |
| v0.1.3 | 白盒测试补充 + 测试组织调整 | 白盒 + 黑盒 + examples 分层 | ✅ 完成 |
| v0.1.4 | 字典视图共享引用验证 + pinyin_dict 分 11 段 merge | 规避单段过长警告 | ✅ 完成 |
| v0.1.5 | Warning 全面治理 + 严格 deny-warn + 文档全面更新 | 50 warning → 0，`+73 --deny-warn` 四后端全绿 | ✅ 完成 |

---

## 参考与设计说明

- 参考项目 1：[pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj) — 仓颉原版（MIT）
- 本项目许可证：MIT

### 设计原则

- **完整移植**：pinyin_helper + chinese_helper 全部 API 完整移植，无功能缺失
- **逐函数手动转换**：camelCase → snake_case，异常改用 `raise PinyinError`，非自动代码转换
- **字典内嵌**：构建期内嵌为 MoonBit Map 字面量，无运行时 IO，启动零解析开销
- **分段合并**：大字典（20903 条）分 11 段后 `.merge()` 合并，规避单段文本过长警告
- **字典视图共享**：根包视图常量与 data 包共享同一 Map 对象引用（非拷贝），自定义追加对两者均可见
- **四后端零警告**：wasm / wasm-gc / js / native 全通过，严格 `--warn-list +73 --deny-warn`
- **三包线性无环**：data ← pinyin ← examples，data 零依赖可独立复用

---

## mooncakes.io 生态对比分析（截至 2026-11-05）

在 mooncakes.io 全量 31909 个 MoonBit 包中检索 pinyin 相关库，匹配的仅 2 个。下表按相关性排序，数据来源为 mooncakes.io 公开页面。

### 提供汉字→拼音转换功能的库

| 库 | 版本 | 下载 | 数据源 | 字典条目 | 繁简互转 | 通用拼音 | 多音字 | 自定义字典 | 声调格式 | 工具链 | 移植血缘 | 四后端 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **walkzzz/pinyin**（本项目） | 0.1.0 | 32 | pinyin4cj 字典内嵌 | 24361 | ✅ | ✅ | ✅ | ✅ | 4 种 | ✗ | ✅ pinyin4cj 仓颉 | ✅ 60 测试 |
| wjhfather/pinyin-toolkit | 0.1.0 | 30 | Unicode 17.0 Unihan | 未公开 | ✗ | ✗ | ✅ 显式 override | ✅ phrase lexicon | 多种 | ✗ | ✗ 原创 | ✅ |

### 本项目差异化定位（强依据）

1. **唯一 pinyin4cj 移植** — mooncakes.io 上无其他库标注移植自 pinyin4cj；本项目是仓颉生态拼音库向 MoonBit 移植的代表
2. **繁简互转** — ChineseHelper 提供 繁→简 + 简→繁 + 汉字判断，pinyin-toolkit 不提供
3. **通用拼音** — to_tongyong_pinyin_string_array 支持 82 条通用拼音映射，pinyin-toolkit 不提供
4. **四后端全绿 + 严格 deny-warn** — `--warn-list +73 --deny-warn` 零警告零错误，240 测试
5. **字典视图共享** — 根包与 data 包共享同一 Map 引用，自定义追加对两者均可见
6. **24361 条字典内嵌** — 构建期固化，无运行时 IO，启动零解析开销

### 互补关系（非竞争）

`wjhfather/pinyin-toolkit` 定位不同：基于 Unicode 17.0 Unihan 官方数据，聚焦**确定性拼音规范化 + 模糊匹配（zh/z、ch/c、sh/s、n/l）+ 搜索索引（Trie + 4 种 IndexProfile）+ 编辑距离对齐 + 批量转换 + 可审计 diagnostics**，提供 40+ 结构化类型。本项目聚焦**轻量拼音转换 + 繁简互转 + 通用拼音**，API 简洁（18 个公开符号）。两者互补：本项目做基础转换，pinyin-toolkit 做规范化与搜索匹配。

### 大赛要求满足结论

本项目满足大赛要求的三个不可替代点：
1. **填补生态空白**：mooncakes.io 首个 pinyin4cj 仓颉移植版本，填补 MoonBit 生态汉字→拼音转换空白
2. **工程严格度**：四后端零警告 + 240 测试 + 严格 `+73 --deny-warn` + warning 治理记录
3. **完整移植**：pinyin_helper + chinese_helper 全部 API 完整移植，无功能缺失

---

## 验收标准对齐（大赛要求）

| 大赛验收项 | 本项目满足方式 |
|-----------|-------------|
| MoonBit 为主 | 库自身 100% MoonBit 实现（拼音转换 + 繁简互转 + 声调转换 + 字典数据） |
| 仓库公开 | GitHub 公开仓库，持续提交（v0.1.0 ~ v0.1.5，5 轮内部迭代，对外发布 v0.1.1） |
| 能够运行 | README + 可运行示例 + 240 测试 + 0 warnings |
| 工作有效 | 从仓颉移植到 MoonBit，逐函数手动转换，2026 完成 |
| 开源合规 | MIT License，参考来源 pinyin4cj 已标注 |
| AI 可解释 | AI 辅助开发，所有算法经人工审查 |

---

## 技术亮点

1. **24361 条字典内嵌** — 4 张字典构建期固化为 Map 字面量，无运行时 IO
2. **完整移植** — pinyin_helper + chinese_helper 全部 API，无功能缺失
3. **4 种声调格式** — WithToneMark / WithoutTone / WithToneNumber / FirstLetter
4. **多音字支持** — convert_to_pinyin_array 返回多读音，has_multi_pinyin 检测
5. **繁简互转** — 繁→简 + 简→繁 + 汉字判断 + 繁体判断
6. **通用拼音** — 82 条通用拼音映射，to_tongyong_pinyin_string_array
7. **自定义字典扩展** — 3 个 add_*_dict_resource 方法，原地合并，键冲突新值覆盖
8. **字典视图共享** — 根包与 data 包共享同一 Map 引用（非拷贝）
9. **分段合并** — 20903 条单字拼音分 11 段 merge，规避单段过长警告
10. **四后端零警告** — wasm/wasm-gc/js/native 全通过，`+73 --deny-warn` 零警告零错误
11. **240 测试全通过** — 白盒 13 + 黑盒 24 + 示例 14 + 文档可执行 11，每后端 60
12. **线性无环架构** — data ← pinyin ← examples 三包线性，data 零依赖可独立复用
13. **mooncakes 已发布** — `walkzzz/pinyin@0.1.0`，32 下载

---

## 技术风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 字典数据更新 | pinyin4cj 字典变更 | `scripts/gen_pinyin_dict.py` 可重新生成字典字面量 |
| MoonBit 语言 beta-preview | 语言本身尚未 stable | 已可用于生产，不兼容变更严格评估 |
| 多音字上下文推断 | 本项目字典查表，不静默推断 | 显式 phrase override 由调用方通过 add_mutil_pinyin_dict_resource 提供 |
| 通用拼音覆盖范围 | 82 条通用拼音映射有限 | 可通过自定义字典扩展，与 pinyin-toolkit 互补 |
| WASM local count 限制 | 大字典 match 可能触发 | 字典用 Map 字面量（非大 match），四后端已验证无此问题 |