# 计划审查报告（v3 r1）

## 审查结果
REJECTED

## 发现

- **[严重]** 可见性修饰符描述自相矛盾，会误导编码 agent 选择错误修饰符，导致 R4 字典视图任务无法引用 `@data.xxx`。task_v3.md 第 105 行原文：

  > 顶层 `let` 绑定，数据子包内 `pub(self)` 可见性（仅包内可访问，主包通过 `@data` 引用）。**注意**：数据子包的 `let` 常量需对主包可见，应使用 `pub let` 或 `pub(self) let`（由编码 agent 根据 moon 工具链实际可见性规则确定，参考 wiki `libs/map.md` Map 字面量示例）。

  存在两处矛盾：
  1. 第一句声称 `pub(self)` 可见性"仅包内可访问"，同时又称"主包通过 `@data` 引用"——`pub(self)` 语义是仅当前包可见，主包**无法**通过 `@data` 引用，二者直接矛盾。
  2. 第二句称"需对主包可见，应使用 `pub let` 或 `pub(self) let`"——`pub(self) let` 是仅包内可见，主包**不可见**，与"需对主包可见"的要求直接矛盾。

  编码 agent 若按此提示选择 `pub(self) let`，则主包在 R4 任务中引用 `@data.chinese_dict` 等将报"不可见"错误，直接阻断后续任务链。给出的两个候选选项中 `pub(self) let` 是错误选项，不应作为备选。

- **[一般]** 生成脚本未明确要求以 UTF-8 编码读写文件。源库 `resource/pinyin.dict.txt` 与 `src/mutil_pinyin_dict.cj` 含带调元音字符（如 `líng`、`ā,hōng`），task_v3.md 第 51 行也提到"含带调元音 UTF-8 字符串原样保留"。但 task_v3.md 未在脚本行为要求中明确以 UTF-8 编码打开文件。Windows 平台 Python 3 默认使用系统编码（如 GBK cp936），若脚本未显式指定 `encoding="utf-8"`，将导致带调元音字符在读写过程中损坏，生成的 `.mbt` 文件含错误字符，`moon check` 可能通过（MoonBit 字符串字面量允许任意 UTF-8）但运行时拼音数据错误，缺陷隐蔽且难以排查。

- **[一般]** 生成脚本未要求确定性输出顺序。task_v3.md 要求生成脚本与产物均入版本控制（第 25 行、第 47 行），但未要求脚本输出条目按确定性顺序排列（如按 key 排序）。若脚本使用 Python `dict` 且直接迭代输出，Python 3.7+ 虽保持插入顺序，但若解析过程中顺序受源文件行序影响且源文件顺序变化，将产生不必要的 diff。更关键的是，`pinyin_dict.mbt` 有 20903 条目，若顺序不稳定，版本控制中的 diff 将极难审阅。应明确要求脚本按 key 排序输出（`chinese_dict` 按 Int key 升序，其余按 String key 字典序）。

- **[轻微]** 完整性校验仅对 `pinyin_dict.mbt`（= 20903）和 `tongyong_pinyin_dict.mbt`（= 83）要求精确等于，对 `chinese_dict.mbt`（≈ 2556）和 `mutil_pinyin_dict.mbt`（≈ 856）使用约等于。建议脚本对四张字典均含精确条目数断言（解析后实际计数与预期值比较），约等于的容差会让脚本校验形同虚设——若解析逻辑漏掉若干条目，脚本仍可能通过校验。

## 修改要求

### 问题 1：可见性修饰符矛盾（严重）

**问题**：task_v3.md 第 105 行对数据子包 `let` 常量的可见性修饰符给出自相矛盾的指导，同时提供 `pub let`（正确）与 `pub(self) let`（错误，主包不可见）两个备选，并错误声称 `pub(self)` 可被主包通过 `@data` 引用。

**为什么是问题**：R4 字典视图任务（`pinyin_dicts.mbt`）需通过 `@data.chinese_dict` / `@data.pinyin_dict` / `@data.mutil_pinyin_dict` / `@data.tongyong_pinyin_dict` 引用数据子包常量。若编码 agent 据此选择 `pub(self) let`，主包引用将报可见性错误，直接阻断 R4 及全部后续算法实现任务（R5-R8）。这是任务链的关键依赖点，不能留模糊空间。

**期望的修正方向**：删除 `pub(self) let` 备选项与"`pub(self)` 主包可通过 `@data` 引用"的错误陈述。明确要求数据子包常量使用 `pub let`（对包外可见，主包可通过 `@data` 引用）或 `pub(all) let`（公开所有，含内部成员可见）。建议直接定为 `pub let`（最小充分可见性），并说明理由：数据子包常量是纯数据，无内部成员需公开，`pub let` 足矣。同时建议查阅 wiki `libs/map.md` 或 moon 工具链文档确认 `pub let` 在跨包 `@data` 引用场景下的正确性，将确认结果写入 task。

### 问题 2：生成脚本未要求 UTF-8 编码（一般）

**问题**：task_v3.md 未在脚本行为要求中明确以 UTF-8 编码读写源库文件与生成产物文件。

**为什么是问题**：源库与产物均含带调元音 UTF-8 字符（`ā`、`ōng`、`líng` 等），Windows 平台 Python 3 默认编码非 UTF-8，未显式指定将导致字符损坏，缺陷隐蔽（`moon check` 可能通过但数据错误）。

**期望的修正方向**：在 task_v3.md §源库字典格式 或 §验证契约 中明确补充脚本编码要求：所有文件读写必须显式指定 `encoding="utf-8"`（如 `open(path, "r", encoding="utf-8")`），确保带调元音字符原样保留。

### 问题 3：生成脚本未要求确定性输出顺序（一般）

**问题**：task_v3.md 要求脚本与产物入版本控制，但未要求产物条目按确定性顺序排列。

**为什么是问题**：`pinyin_dict.mbt` 有 20903 条目，若输出顺序不稳定，版本控制 diff 将极难审阅，且脚本可重复性无法保证（多次运行可能产生不同产物）。

**期望的修正方向**：在 task_v3.md §技术方案依据/§5.1 生成脚本 或 §验证契约 中明确补充：脚本输出条目必须按 key 排序（`chinese_dict` 按 Int key 升序，`pinyin_dict` / `mutil_pinyin_dict` / `tongyong_pinyin_dict` 按 String key 字典序），确保多次运行产生字节级一致的产物。