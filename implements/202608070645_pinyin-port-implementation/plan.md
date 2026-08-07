# 实现计划

任务描述：将 Cangjie 拼音库 pinyin4cj 移植为 MoonBit 实现（源码 + 单元测试），基于已验证的技术方案 tech_v1.md
项目根目录：D:\CodeWorkspace\forMoonbit\pinyin

---

## R1 NEW 项目骨架与包配置

任务：创建 MoonBit 模块骨架——`moon.mod`（模块元数据，license=MIT，零外部依赖）、主包 `moon.pkg`（import 数据子包）、数据子包 `data/moon.pkg`（无 import，纯数据包）、占位 `README.mbt.md`。预期文件路径：`moon.mod`、`moon.pkg`、`data/moon.pkg`、`README.mbt.md`。验证 `moon check` 通过（空骨架）。

选择理由：所有后续任务（字典字面量、类型定义、算法实现、测试）均依赖项目骨架与包配置。底层优先，先建立可编译的空项目骨架，确保工具链与包边界正确。

上下文：
- 技术方案 §2.2 文件结构、§3.1-3.3 包配置、§十一 T1-T5 决策
- moon 工具链 `moon 0.1.20260713`（rr_moon_mod / rr_moon_pkg feature flags 已启用，支持新格式 moon.mod/moon.pkg）
- 模块名 `pinyin/pinyin`（作者占位），license=MIT（对齐源库 LICENSE，落实审查建议 N2）
- 零外部依赖（无 import 块，仅 moonbitlang/core 隐式可用）
- 主包单向依赖数据子包，数据子包零依赖
- 三后端平等（不设置 preferred-target，不设置 supported_targets）
- 项目根目录当前为空（仅有 .codeartsdoer/ .git/ deliberations/ designs-oo/ designs-tech/ implements/ README.md requirements/ 目录，无 MoonBit 源文件）

---

## R1 PASSED 项目骨架与包配置

结果：创建 `moon.mod`（name=`pinyin/pinyin`，version=`0.1.0`，license=MIT，零外部依赖）、`moon.pkg`（import `pinyin/pinyin/data`）、`data/moon.pkg`（纯数据包零依赖）、`README.mbt.md`（占位）。模块空骨架建立，包边界正确。
测试：无 `.mbt` 测试文件（骨架任务无公开接口）。`moon check` exit code 0，1 warnings（`unused_package` 预期警告，主包零源文件致数据子包未引用，后续任务添加 `@data.xxx` 引用后自动消除），0 errors。

---

## R2 NEW 基础类型定义（PinyinFormat + PinyinError）

任务：在主包定义 `PinyinFormat`（`pub(all) enum`，4 变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`，含 `name` 方法返回变体名）与 `PinyinError`（`pub(all) suberror`，单变体 `PinyinError(String)` 携带消息）。预期文件路径：`pinyin_format.mbt`、`pinyin_error.mbt`。验证 `moon check` 通过，`unused_package` 警告仍存在（预期，本任务不引用数据子包）。

选择理由：`PinyinFormat` 是所有拼音转换方法的参数类型，`PinyinError` 是所有可抛错方法的异常类型。两者是全部公开 API 的基础类型依赖，无需字典数据，属最底层。按"底层优先"原则，在字典字面量与算法实现之前先定义基础类型，为后续 `PinyinHelper` / `ChineseHelper` 方法签名提供类型基础。两类型紧密相关（均为基础枚举/错误类型），合并为一个任务符合粒度约定（1-3 个紧密相关类型）。

上下文：
- 技术方案 §7.1 类型形态（PinyinFormat pub(all) enum 4 变体 / PinyinError pub(all) suberror 单变体）、§7.3 公开 API 方法清单（PinyinFormat::name）、§7.4 错误处理策略（raise PinyinError 检查式错误）、§10.1 移植映射表（pinyin_format.cj → pinyin_format.mbt / utils.cj → pinyin_error.mbt）、§十一 T9/T10 决策
- 源库 `pinyin_format.cj`（33行）：enum PinyinFormat 4 变体 + getName() 方法，match 返回变体名字符串
- 源库 `utils.cj`（25行）：class Pinyin4cjException <: Exception，携带 messages 字段，getMessage() / toString()
- MoonBit suberror 惯例：`pub(all) suberror PinyinError { PinyinError(String) }`，调用方 `raise PinyinError` / `catch { PinyinError::PinyinError(msg) => ... }`
- 命名映射：WITH_TONE_MARK→WithToneMark / WITHOUT_TONE→WithoutTone / WITH_TONE_NUMBER→WithToneNumber / FIRST_LETTER→FirstLetter / getName→name
- R1 已建立模块骨架（moon.mod / moon.pkg / data/moon.pkg / README.mbt.md），`moon check` 通过
- 本任务不引用数据子包（`@data.xxx`），`unused_package` 警告将持续至后续字典加载任务

---

## R2 PASSED 基础类型定义（PinyinFormat + PinyinError）

结果：主包根目录新增 `pinyin_format.mbt`（`pub(all) enum PinyinFormat` 4 变体 + `PinyinFormat::name` 方法）与 `pinyin_error.mbt`（`pub(all) suberror PinyinError` 单变体 `PinyinError(String)`）。未修改 R1 产出，未引用数据子包。
测试：`pinyin_format_test.mbt`（5 用例）+ `pinyin_error_test.mbt`（3 用例）。`moon check` exit code 0，1 warnings（`unused_package` 预期），0 errors。`moon test` Total 8, passed 8, failed 0。

---

## R3 NEW 字典数据子包字面量生成（含生成脚本）

任务：创建 Python 3 生成脚本 `scripts/gen_pinyin_dict.py`，从源库 `D:\CodeWorkspace\forCangjie\pinyin4cj` 的 `src/chinese.dict.cj` / `src/mutil_pinyin.dict.cj` / `src/tongyong_pinyin_dict.cj` / `resource/pinyin.dict.txt` 转写为 MoonBit 字面量，生成 4 个数据子包源文件：`data/chinese_dict.mbt`（`let chinese_dict : Map[Int, Int]`，约 2556 条，16 进制码点）、`data/mutil_pinyin_dict.mbt`（`let mutil_pinyin_dict : Map[String, String]`，约 856 条）、`data/tongyong_pinyin_dict.mbt`（`let tongyong_pinyin_dict : Map[String, String]`，83 条）、`data/pinyin_dict.mbt`（`let pinyin_dict : Map[String, String]`，20903 条）。运行脚本生成产物，验证 `moon check` 通过（数据子包零依赖，主包仍不引用 `@data.xxx`，`unused_package` 警告持续至 R4 字典视图任务）。预期文件路径：`scripts/gen_pinyin_dict.py`、`data/chinese_dict.mbt`、`data/mutil_pinyin_dict.mbt`、`data/tongyong_pinyin_dict.mbt`、`data/pinyin_dict.mbt`。

选择理由：四张字典是全部算法实现（`pinyin_dicts.mbt` 字典视图 / `tone_conversion.mbt` 声调转换 / `pinyin_helper.mbt` 拼音转换 / `chinese_helper.mbt` 繁简互转）的底层数据依赖。按"底层优先"原则，在算法实现之前先建立字典数据子包。四张字典均为纯数据字面量（非复杂行为类型），紧密相关，合并为一个任务符合粒度约定。生成脚本入版本控制，产物亦入版本控制（便于 `moon check` 离线验证，落实技术方案 §5.1）。

上下文：
- 技术方案 §4.1 字典数据结构选型（CHINESE_MAP: Map[Int, Int] / PINYIN_TABLE: Map[String, String] / MUTIL_PINYIN_TABLE: Map[String, String] / TONGYONG_PINYIN_TABLE: Map[String, String]）、§4.2 存储策略（构建期内嵌为 MoonBit 字面量）、§5.1 生成脚本路径与输入输出、§5.2 转写规则（4 子节）、§十一 T6/T7/T8 决策
- 源库 `src/chinese.dict.cj`（2556 行）：`HashMap<Rune, Rune>([(r'臺', r'台'), ...])`，约 2556 条繁→简映射
- 源库 `src/mutil_pinyin.dict.cj`（858 行）：`HashMap<String, String>([("阿訇", "ā,hōng"), ...])`，约 856 条词组拼音
- 源库 `src/tongyong_pinyin_dict.cj`（92 行）：`HashMap<String, String>([("chi", "chih"), ...])`，83 条通用拼音
- 源库 `resource/pinyin.dict.txt`（41806 行 / 20903 组）：两行一组（汉字 / 拼音读音），单字拼音字典
- 转写规则：`chinese_dict.mbt` 用 16 进制码点字面量（`0x81FA: 0x53F0`）；其余三张直接转写键值字符串；`pinyin_dict.mbt` 条目数必须 = 20903（脚本含断言校验）
- R1 已建立数据子包骨架（`data/moon.pkg` 纯数据包零依赖），R2 已建立基础类型（本任务不依赖 R2 产出）
- 本任务不修改主包源文件，不引用 `@data.xxx`，`unused_package` 警告将持续至 R4 字典视图任务

---

## R3 RETRY 字典数据子包字面量生成（含生成脚本）— 审议修订 r1

原因：v3 任务分配被计划审查驳回（plan_review_v3_r1.md），4 项问题（1 严重 / 2 一般 / 1 轻微）。

修订要点（详见 task_v3.md §修订说明 v3 r1）：
1. **[严重] 可见性修饰符**：删除 `pub(self) let` 错误备选，明确要求数据子包常量使用 `pub let`（已查阅 wiki `language/packages.md:79-80` 确认跨包 `@data` 引用正确性）
2. **[一般] UTF-8 编码**：补充脚本所有文件读写显式指定 `encoding="utf-8"` 的强制要求
3. **[一般] 确定性输出顺序**：补充脚本按 key 排序输出的强制要求（`chinese_dict` 按 Int key 升序，其余按 String key 字典序）
4. **[轻微] 完整性校验**：四张字典均改为精确条目数断言（严格相等，不使用约等于容差）

修正方向：覆写 task_v3.md，保留前序内容 + 追加修订说明，不创建新版本号文件。继续 R3 任务。