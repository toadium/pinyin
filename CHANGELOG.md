#### V0.1.0
- 移植 pinyin4cj 至 MoonBit
- 支持词、句转换成拼音
- 支持常用简体/繁体中文字符转换成拼音
- 支持常见多音字符转换成拼音
- 支持 Unicode 格式的字符 ü、支持声调符号、支持首字母格式
- 支持常用简体、繁体中文字符互转
- 支持添加自定义字典
- 支持常用简体/繁体中文字符转换成通用拼音
- 适配 moon 版本 0.1.20260713

#### V0.1.1
- 工程化：LICENSE、CHANGELOG.md、.gitignore、GitHub Actions CI、申报书与移植说明
- 模块名改为 walkzzz/pinyin（匹配 mooncakes 用户名），设置 moon.mod repository 字段
- inspect → debug_inspect，构建零警告
- 源码布局重构：src/ → 根目录（对齐 chrono_tz-mbt 约定）
- 多后端支持：wasm / wasm-gc / js / native（60/60 × 4 = 240 测试）
- supported_targets = "+wasm+wasm-gc+js+native"
- AGENTS.md 创建，docs/ 开发文档补充（roadmap / architecture / api / testing）
- 白盒测试补充（pinyin_easy_wbtest.mbt，内部逻辑覆盖）
- 测试组织调整：白盒 + 黑盒（mid/difficult）+ examples 分层
- 字典视图常量与 data 包共享引用验证
- pinyin_dict 分 11 段 merge，规避单段文本过长警告
- Warning 全面治理（50 个 → 0）：
  - [0025] test_unqualified_package：黑盒测试与 README 加 `@pinyin.` 限定前缀
  - [0020] deprecated to_repr：example 改用 `Repr(x)`
  - [0073] unnecessary_annotation：枚举变体在 `format=` 位置去除冗余限定
- 严格模式 `--warn-list +73 --deny-warn` 四后端全绿，零警告零错误
- 文档全面更新：README.md / README.mbt.md / docs/ / AGENTS.md 同步至 v0.1.1 现状
- mooncakes 发布 `walkzzz/pinyin@0.1.1`

> 内部迭代历史：v0.1.2（根布局+多后端）→ v0.1.3（白盒测试）→ v0.1.4（字典分段）→ v0.1.5（warning 治理），统一对外发布为 v0.1.1。