# 编码实现任务

## 任务目标

基于已验证的技术方案设计和其独立审查报告，将 Cangjie 拼音库 `pinyin4cj` 移植为可运行的 MoonBit 实现，产出源码 + 单元测试。

## 输入文档

1. **技术方案设计**：`D:\CodeWorkspace\forMoonbit\pinyin\designs-tech\202608070004_pinyin-port-tech-design\tech_v1.md`
   — 经 technical-design-harness 验证通过的技术方案，涵盖 MoonBit 工具链、包依赖管理、数据结构选型、FFI 路径、算法实现路径、API 形态、测试技术路径、资源构建、移植映射表等
2. **技术方案审查报告**：`D:\CodeWorkspace\forMoonbit\pinyin\deliberations\202608070024_review-tech-v1\output_v1.md`
   — 对技术方案的独立深入审查产出，包含架构落实性、审查建议落实、技术选型合理性、MoonBit 生态符合性、源库保真度、skill 规范符合性、可实施性、测试充分性、用户偏好符合性等维度的审查发现与修订建议
3. **架构设计方案**：`D:\CodeWorkspace\forMoonbit\pinyin\designs-oo\202608062251_pinyin-port-arch-design\design_v2.md`
4. **架构审查报告**：`D:\CodeWorkspace\forMoonbit\pinyin\deliberations\202608062345_review-design-v2\output_v1.md`
5. **需求文档**：`D:\CodeWorkspace\forMoonbit\pinyin\requirements\202608062224_pinyin-port-to-moonbit\req_v1.md`
6. **需求审查报告**：`D:\CodeWorkspace\forMoonbit\pinyin\deliberations\202608062236_review-req-v1\output_v1.md`
7. **源库**：`D:\CodeWorkspace\forCangjie\pinyin4cj`（Cangjie 语言拼音库，移植对象）
8. **Skills 目录**：`D:\CodeWorkspace\forMoonbit\pinyin\.codeartsdoer\skills`
   — 相关 skill：moonbit-agent-guide、moonbit-c-binding、make-moonbit-c-bindings、moonbit-spec-test-development、moonbit-refactoring、moonbit-orientation 等

## 实现要求

- 严格按照技术方案 tech_v1.md 的移植映射表和包结构实现
- 充分考虑技术方案审查报告 output_v1.md 中的修订建议
- 正确应用 .codeartsdoer/skills 下相关 skill 的规范
- 源码和测试直接写入项目根目录 `D:\CodeWorkspace\forMoonbit\pinyin` 的目录树
- 使用 moon 包管理器，目标后端按技术方案确定
- 类型名使用 PascalCase，项目/文档命名使用 kebab-case
- 代码包含必要的注释和文档
- 采用 spec-driven 测试组织（参考 moonbit-spec-test-development skill）

## 用户偏好（须遵循）

- 偏好 MoonBit 语言，使用 moon 包管理器和 mooncakes.io 注册表
- 使用简体中文交互，技术文档命名和术语使用英文
- 项目和技术文档命名使用 kebab-case
- 类型名使用 PascalCase
- 希望代码包含必要的注释和文档
- 偏好彻底的根因分析，不忽略任何警告
- 倾向于批量完成修改后统一测试

## 验收标准

- `moon check` 通过
- `moon test` 通过
- 核心 API 行为与源库 pinyin4cj 一致（经测试验证）
- 包结构符合技术方案设计