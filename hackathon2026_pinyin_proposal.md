# pinyin 项目申报书

**基本信息**
- 参赛者：蒋本雄（GitHub：toadium / walkzzz）
- 方向：基础库 / 中文文本处理基础设施
- GitHub：https://github.com/toadium/pinyin
- Gitlink：提交前填写（与 GitHub 同步）
- mooncakes：`walkzzz/pinyin`；许可证：MIT（字典参考 pinyin4cj，MIT）

**项目简介**
pinyin 不是字典查表封装，而是 MoonBit 的“拼音 → 中文”推理层：输入法解码、多音字上下文消歧、连续拼音分词、变调、模糊匹配与中文搜索。

**与竞品的差异**
pinyin-toolkit 强在 UniHan 数据、可审计 token/搜索键、批量转换和加权距离；它明确把多音字交给调用方 override，不做上下文推断，也没有输入法解码。本项目补的正是这一段：
- 消歧：常用多音词 99.5% vs 首读音基线 68.0%（66 条 gold + 47,110 词组大词库）
- 输入法：Beam+LM、词组候选、简拼、小鹤/自然码双拼、用户学习
- 连续拼音 Trie+DP、5 类变调、9 组模糊规则

**本轮新增（2026-11）**
- `shuangpin` 包：小鹤/自然码双向转换并接入输入法
- 输入法：简拼、147 常用词 + 47,110 词组大词库、用户选择学习重排
- 消歧：词级优先 + 句内最大匹配 + 带调 bigram 回退
- 质量：328 测试/后端（共 1312 测试）、覆盖率/变异/CI 门禁

**三个使用场景**
1. 拼音输入法：全拼/简拼/双拼、词组与用户学习
2. 中文搜索与索引：首字母/全拼/模糊检索
3. 拼音教学与 NLP 前处理：多音字标注、变调、规范化

**技术方案**
Viterbi+bigram O(nk²)；Beam O(SBC)；Trie+DP O(n²L)；双拼 O(n)。四后端 wasm/wasm-gc/js/native，零运行时 IO。

**移植边界**
convert/data 的字典与接口参考 pinyin4cj（MIT）；其余 reverse/segment/fuzzy/disambiguate/search/tone/normalize/lm/input/shuangpin 自研。

**AI 使用说明**
AI 辅助测试、文档和部分实现；算法选型、边界与验收由人工确认，结论以 `moon test`、覆盖率、变异门禁实测为准。

**预期交付**
MoonBit 包、`demo`、README/API 文档、1200+ 测试、CI 门禁。

> 技术细节与组委会关切逐条回复见 `docs/proposal_appendix.md`。