# 架构级 OOD 设计需求

## 任务目标

基于已澄清的需求文档和其审查报告，对「将 Cangjie 拼音库 pinyin4cj 移植到 MoonBit」进行架构级 OOD 设计。

## 输入文档

1. **需求文档**：`D:\CodeWorkspace\forMoonbit\pinyin\requirements\202608062224_pinyin-port-to-moonbit\req_v1.md`
   — 经 requirement-design-harness 澄清并验证通过的需求规格
2. **审查报告**：`D:\CodeWorkspace\forMoonbit\pinyin\deliberations\202608062236_review-req-v1\output_v1.md`
   — 对需求文档的独立深入审查产出，包含准确性、完整性、可行性、skill 规范符合性、清晰性、用户偏好符合性等维度的审查发现与修订建议
3. **原始需求**：`D:\CodeWorkspace\forMoonbit\pinyin\requirements\202608062224_pinyin-port-to-moonbit\requirement.md`
4. **源库**：`D:\CodeWorkspace\forCangjie\pinyin4cj`（Cangjie 语言拼音库，移植对象）
5. **Skills 目录**：`D:\CodeWorkspace\forMoonbit\pinyin\.codeartsdoer\skills`
   — 相关 skill：moonbit-agent-guide、moonbit-c-binding、make-moonbit-c-bindings、moonbit-spec-test-development、moonbit-refactoring、moonbit-orientation 等

## 设计要求

本框架产出**架构级 OOD 设计**，聚焦于：

- **职责划分**：模块/包的边界与职责
- **抽象层次**：核心抽象、接口、类型层次
- **协作模式**：模块间协作、数据流、控制流
- **关键设计决策**：目标后端选择、FFI 策略、数据加载方式、字典存储格式、API 风格（是否对齐原库 vs MoonBit 惯例）等
- **MoonBit 包结构**：moon.mod.json、moon.pkg.json 的包组织
- **测试架构**：spec-driven 测试组织（参考 moonbit-spec-test-development skill）

设计方案的抽象度应足以指导后续的详细设计和编码实现，但不直接包含可执行的代码规格。

## 用户偏好（须遵循）

- 偏好 MoonBit 语言，使用 moon 包管理器和 mooncakes.io 注册表
- 使用简体中文交互，技术文档命名和术语使用英文
- 项目和技术文档命名使用 kebab-case
- 类型名使用 PascalCase
- 希望代码包含必要的注释和文档
- 偏好彻底的根因分析，不忽略任何警告
- 倾向于批量完成修改后统一测试

## 注意事项

- 设计须充分考虑审查报告 output_v1.md 中提出的修订建议
- 须正确应用 .codeartsdoer/skills 下相关 skill 的规范
- 须与 MoonBit 语言特性及生态相符