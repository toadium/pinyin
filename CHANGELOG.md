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
- 重构为 src/ 目录布局，对齐源库结构
- 添加 LICENSE、CHANGELOG.md、.gitignore
- 添加 src/examples/ 目录（4 个可运行示例）
- 添加 doc/feature_api.md API 文档
- 添加 GitHub Actions CI 配置
- 添加项目申报书与移植说明
- 设置 moon.mod repository 字段
- 模块名改为 walkzzz/pinyin（匹配 mooncakes 用户名）
- inspect → debug_inspect，构建零警告