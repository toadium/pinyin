# 设计审查报告（v2 r1）

## 审查结果
APPROVED

## 发现

### 验证方法

本次审查不仅做了文档级审查，还进行了**实证验证**：按设计文档"精确到字节"的代码契约在项目根目录实际创建 `pinyin_format.mbt` / `pinyin_error.mbt` 两文件，执行 `moon check` / `moon test` / `moon info`，并编写临时测试验证 `PinyinFormat::name` 四变体返回值与 `PinyinError` 的 `raise`/`catch` 语义。验证完毕后清理所有临时文件，恢复项目至 R1 骨架状态（`moon check` 仍为 exit code 0 + 1 `unused_package` 警告，与 R1 一致）。

实证结果：
- `moon check`：exit code 0，1 warnings（`unused_package`，预期），0 errors — 与设计 §E 预期完全一致。
- `moon test`：2 tests passed（`PinyinFormat::name` 四变体断言 + `PinyinError` raise/catch 断言）。
- `moon info` 生成 `pkg.generated.mbti` 公开 API：`pub(all) suberror PinyinError { PinyinError(String) }` / `pub(all) enum PinyinFormat { ... }` / `pub fn PinyinFormat::name(Self) -> String` — 与设计 §依赖关系/公开接口一致。

### 任务覆盖性

设计覆盖 task_v2.md 全部要求：
- `PinyinFormat`（`pub(all) enum`，4 变体 + `name` 方法）✓
- `PinyinError`（`pub(all) suberror`，单变体 `PinyinError(String)`）✓
- `name` 返回值逐字符对齐源库 `getName()` ✓（四变体返回值经测试断言验证）
- 不引用数据子包、不添加 import、不修改已有文件 ✓
- `moon check` 通过 + `unused_package` 警告预期保留 ✓

### 技术正确性

- `pub(all) enum` 语法：对齐 wiki `libs/time.md:104` `Weekday` 示例，moon check 通过 ✓
- `pub(all) suberror` 语法：对齐 wiki `libs/json5.md:22` `ParseError` 示例，变体名与类型名同名符合 MoonBit 惯例，moon check 通过 ✓
- `raise PinyinError` / `catch { PinyinError::PinyinError(msg) => ... }` 错误模型：经测试验证可正常抛出与捕获 ✓
- `PinyinFormat::name` 方法签名 `pub fn PinyinFormat::name(self : PinyinFormat) -> String`：moon check 通过，`pkg.generated.mbti` 确认公开 ✓

### 源库保真度

- `pinyin_format.cj` → `pinyin_format.mbt`：4 变体名 PascalCase 映射正确，`getName()` → `name(self)` 命名映射正确，4 个返回值字面量逐字符对齐 ✓
- `utils.cj` → `pinyin_error.mbt`：`Pinyin4cjException` → `PinyinError` suberror 映射正确，`messages` 字段 → `PinyinError(String)` 载荷映射正确 ✓
- `toString()` / `getMessage()` 不在本任务范围：设计 §类型定义/PinyinError 明确说明"本任务不实现"，对齐 task_v2.md 约束，避免过度设计 ✓

### 命名规范

类型名 PascalCase、枚举变体 PascalCase、方法名 lower_snake、文件名 lower_snake — 全部符合 task_v2.md §约束与 requirement.md 用户偏好 ✓

### 行为契约质量

- §A/§B 内容契约给出"精确到字节"的完整文件内容，编码 agent 可直接照抄 — 经实证验证照抄后 moon check 通过 ✓
- §C 命名规范契约逐元素列出源库对应 ✓
- §D 与已有代码交互契约明确不修改范围 ✓
- §E 验证契约含失败模式表、警告治理五要素 (a)-(e)、不执行验证清单 — 完整且与 R1 验证报告一致 ✓
- §依赖关系 明确暴露给后续任务的公开接口与后续任务边界 ✓

### 发现的问题

- **[轻微]** 第 120 行错误处理失败模式表第 3 行内部交叉引用错误：处置列引用 `§类型定义/PinyinError 方法实现`，但 `name` 方法属于 `PinyinFormat` 而非 `PinyinError`，应为 `§类型定义/PinyinFormat 方法实现`（或 `§行为契约/A`）。不影响代码正确性（代码契约本身正确），仅影响编码 agent 在遇到该失败模式时查找修正指引的路径。