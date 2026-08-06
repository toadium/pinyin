# 原始需求

将 `D:\CodeWorkspace\forCangjie\pinyin4cj` 库移植到 MoonBit 实现。

## 关键信息

- **源库**：`D:\CodeWorkspace\forCangjie\pinyin4cj`（Cangjie 语言的拼音库）
- **目标**：移植为 MoonBit 语言实现，工作目录 `D:\CodeWorkspace\forMoonbit\pinyin`
- **参考技能**：`D:\CodeWorkspace\forMoonbit\pinyin\.codeartsdoer\skills` 目录下的相关 skill（如 moonbit-agent-guide、moonbit-c-binding、make-moonbit-c-bindings、moonbit-spec-test-development 等），需在移植过程中学习并应用这些 skill 的规范

## 用户偏好（来自全局配置）

- 偏好 MoonBit 语言，使用 moon 包管理器和 mooncakes.io 注册表
- 使用简体中文交互，技术文档命名和术语使用英文
- 项目和技术文档命名使用 kebab-case
- 类型名使用 PascalCase
- 希望代码包含必要的注释和文档
- 偏好 AI 直接执行操作而非详细解释原理，指令风格为行动导向
- 倾向于批量完成修改后统一测试
- 偏好详细的需求分析和库对比
- 偏好彻底的根因分析，不忽略任何警告

## 待澄清事项

1. 源库 `pinyin4cj` 的完整功能范围、API 表面、核心数据结构
2. 源库依赖的第三方库（如拼音字典数据、规则引擎等）及其在 MoonBit 生态中的对应物
3. 移植的目标范围：完整移植还是核心子集？是否包含测试、文档、示例？
4. MoonBit 目标后端（wasm/js/native）选择及对应的 FFI 策略
5. 拼音字典数据的来源与加载方式（内嵌 / 外部资源 / 运行时加载）
6. 性能、内存、API 兼容性等非功能性要求
7. 测试策略：是否采用 spec-driven 测试（参考 moonbit-spec-test-development skill）
8. 是否需要保留与原库一致的 API 命名，还是按 MoonBit 惯例重新设计