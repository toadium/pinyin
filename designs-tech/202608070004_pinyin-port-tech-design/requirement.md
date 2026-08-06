# 技术方案设计需求

## 任务目标

基于已验证的架构级 OOD 设计方案和其独立审查报告，对「将 Cangjie 拼音库 pinyin4cj 移植到 MoonBit」进行技术方案设计——落实到库和技术路径级别，衔接架构设计与编码实现。

## 输入文档

1. **架构设计方案**：`D:\CodeWorkspace\forMoonbit\pinyin\designs-oo\202608062251_pinyin-port-arch-design\design_v2.md`
   — 经 architecture-design-harness 验证通过的架构级 OOD 设计
2. **架构设计审查报告**：`D:\CodeWorkspace\forMoonbit\pinyin\deliberations\202608062345_review-design-v2\output_v1.md`
   — 对架构设计方案的独立深入审查产出，包含需求符合性、架构合理性、MoonBit 可行性、源库保真度、skill 规范符合性、测试架构充分性、清晰性与可实施性、用户偏好符合性等维度的审查发现与修订建议
3. **需求文档**：`D:\CodeWorkspace\forMoonbit\pinyin\requirements\202608062224_pinyin-port-to-moonbit\req_v1.md`
4. **需求审查报告**：`D:\CodeWorkspace\forMoonbit\pinyin\deliberations\202608062236_review-req-v1\output_v1.md`
5. **源库**：`D:\CodeWorkspace\forCangjie\pinyin4cj`（Cangjie 语言拼音库，移植对象）
6. **Skills 目录**：`D:\CodeWorkspace\forMoonbit\pinyin\.codeartsdoer\skills`
   — 相关 skill：moonbit-agent-guide、moonbit-c-binding、make-moonbit-c-bindings、moonbit-spec-test-development、moonbit-refactoring、moonbit-orientation 等

## 设计要求

技术方案是衔接架构设计和编码实现的桥梁——比架构设计更具体（落实到库和技术路径级别），但比代码更抽象（不涉及具体实现细节）。须明确的技术事项包括但不限于：

- **MoonBit 工具链与版本**：moon 版本、目标后端（wasm/js/native）及对应构建配置
- **包与依赖管理**：moon.mod.json/moon.pkg.json 具体配置、mooncakes.io 依赖选择
- **核心数据结构的技术选型**：拼音字典的存储格式（内嵌 JSON/二进制/外部资源）、加载策略、索引结构
- **FFI 与 native-stub 技术路径**（如需）：extern "c" 声明、C stub、link.native 配置（参考 moonbit-c-binding、make-moonbit-c-bindings skill）
- **核心算法的技术实现路径**：拼音转换、多音字消歧、分词、声调处理等
- **API 技术形态**：公开 API 的类型签名设计（PascalCase 类型名）、错误处理策略
- **测试技术路径**：spec-driven 测试框架选择、spec.mbt 组织、测试数据管理（参考 moonbit-spec-test-development skill）
- **资源与构建**：字典数据资源的构建集成、moon test/build/check 命令
- **移植映射表**：源库模块/API → MoonBit 包/API 的对应关系

## 用户偏好（须遵循）

- 偏好 MoonBit 语言，使用 moon 包管理器和 mooncakes.io 注册表
- 使用简体中文交互，技术文档命名和术语使用英文
- 项目和技术文档命名使用 kebab-case
- 类型名使用 PascalCase
- 希望代码包含必要的注释和文档
- 偏好彻底的根因分析，不忽略任何警告
- 倾向于批量完成修改后统一测试

## 注意事项

- 技术方案须充分考虑架构设计审查报告 output_v1.md 中提出的修订建议
- 须正确应用 .codeartsdoer/skills 下相关 skill 的规范
- 须与 MoonBit 语言特性及生态相符
- 须落实架构设计 design_v2.md 中的所有关键设计决策