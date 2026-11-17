# 参与贡献

感谢你对 pinyin 项目的关注！欢迎参与任何形式的贡献。

## 反馈渠道

- **Bug 报告**：提交 [GitHub Issue](https://github.com/toadium/pinyin/issues)，请包含复现步骤和期望行为
- **功能建议**：提交 Issue 并标注 `enhancement` 标签
- **安全漏洞**：请通过 Issue 私密报告，高危漏洞将在 7 日内修复

## 贡献方式

### 提交 Bug 报告

请包含以下信息：

1. MoonBit 版本（`moon version`）
2. 复现步骤和最小示例代码
3. 期望行为 vs 实际行为
4. 错误信息（如有）

### 提交代码

1. Fork 仓库并创建特性分支
2. 确保所有测试通过：`moon test --target all --warn-list +73 --deny-warn`
3. 格式化代码：`moon fmt`
4. 提交 PR，描述变更内容和动机

### 代码规范

- 遵循 MoonBit 代码风格（`moon fmt` 自动格式化）
- 公开 API 必须编写 `///` 文档注释
- 新功能须附带测试（黑盒测试 `_test.mbt` 或白盒测试 `_wbtest.mbt`）
- 黑盒测试引用宿主包须加 `@包名.` 限定前缀
- 错误处理使用 `raise @core.PinyinError` / `@core.raise_invalid_input`
- 严禁静默吞掉异常，边界输入须有校验

### 测试要求

- 核心逻辑单元测试覆盖率 ≥ 80%
- 必须覆盖边界值、非法输入、空串等异常场景
- 四后端全通过：`moon test --target all --warn-list +73 --deny-warn`

### 版本规范

- 遵循语义化版本（SemVer）
- 补丁版本：Bug 修复，不改变行为契约
- 次版本：新增功能，保持向下兼容
- 主版本：破坏性变更，须提前公示迁移方案
- 废弃接口保留至少一个次版本过渡期

## 维护响应

- 高危 Bug：7 日内响应
- 一般 Bug：14 日内响应
- 功能建议：30 日内评估
