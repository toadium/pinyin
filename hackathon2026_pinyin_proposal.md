# pinyin 项目申报书

**基本信息**

- 参赛者：蒋本雄（GitHub：toadium / walkzzz）
- 方向：基础库 / 中文文本处理基础设施
- 仓库：https://github.com/toadium/pinyin
- 在线演示：https://toadium.github.io/pinyin/（浏览器内计算，无后端）
- Gitlink：提交前填写（与 GitHub 同步）
- 版本：开发版 v0.8.0；mooncakes 最新发布 v0.6.0（v0.8.0 待发布）
- 许可证：MIT；字典数据参考 pinyin4cj（MIT），大词库来自 pypinyin（MIT）
- 当前提交：`1ce5094`（2026-11-23）

**项目简介**

pinyin 不是字典查表封装，而是 MoonBit 的“拼音 → 中文”推理层：输入法解码、
多音字上下文消歧、连续拼音分词、变调、模糊匹配与中文搜索。四后端
（native / wasm / wasm-gc / js）共用同一份源码，零运行时 IO。

**与竞品的差异**

pinyin-toolkit 强在 UniHan 数据、可审计 token/搜索键、批量转换和加权距离；它明确把
多音字交给调用方 override，不做上下文推断，也没有输入法解码。本项目补的正是这一段：

- 消歧：常用多音词 **99.5%** vs 首读音基线 68.0%（66 条 gold + 47,110 词组大词库）
- 输入法：Beam+LM、词组候选、简拼、小鹤/自然码双拼、用户学习
- 连续拼音 Trie+DP、5 类变调、9 组模糊规则
- 交付形态：17 个浏览器导出 + 可交互在线演示（发布后验收 104 项）

**本轮新增（2026-11）**

- 词库：接入 pypinyin **47,110** 条词组（`scripts/gen_large_phrases.py`），
  优先级 `common_phrases(147) > 大词库(47,110) > mutil(843)`；「一/不」还原原调
- 消歧：句内词表最大匹配（最长 9 字）+ 带调 bigram 回退；修复「还钱」误读 hái，
  准确率 96.1% → **99.5%**
- 在线演示：GitHub Pages 上线；playground 导出 **7 → 17**，Live demo 覆盖 pinyin4cj
  十项功能（繁简互转、词句转换、自定义格式、三类自定义字典、多音集合、繁简转拼音、
  通用拼音）与转换/输入法/双拼/消歧/分词/规范化
- 文档：14 份包级 README；页面模块卡/API 表/演示标签直达对应包文档
- 质量：**328 测试/后端 × 4 = 1312**、覆盖率 **94.2%**（1335/1417）、变异 **14/14**、
  `check_pages` **104 项**、`check_docs` **76 项**，CI 四后端严格门禁
- 多音字覆盖：**3,050** 字 / **6,669** 读音全部收录；常用字 **617** 个多音字词组覆盖 **100%**
  （`check_polyphones.mjs` 门禁；全量词组覆盖 31.15%，生僻字回退字级 + bigram）

**五个使用场景**

1. 拼音输入法：全拼/简拼/双拼、词组与用户学习
2. 中文搜索与索引：首字母/全拼/模糊检索
3. 拼音教学与 NLP 前处理：多音字标注、变调、规范化
4. 中文文本转换与清洗：繁简互转、词句转拼音、自定义输出格式、繁简转拼音、通用拼音
5. 可配置词表与多音字教学：三类自定义字典（单字/词组/繁简）、多音字读音集合

**技术方案**

Viterbi+bigram O(nk²)；Beam O(SBC)；Trie+DP O(n²L)；双拼 O(n)。大词库以 **6 个字符串
分片 + 运行时解析**存储，规避 wasm 全局初始化 `local count too large` 与 MoonBit
单文本段行数上限；`playground.js` 4.73 MB（gzip 0.86 MB），Node 侧加载+初始化
711 ms，单次消歧约 0.08 ms（2026-11-23 实测）。四后端行为一致，零运行时 IO。

**在线演示与可复现证据**

- 17 个 `#export_name` 导出全部由同一份 MoonBit 编译为 JS，在浏览器本地运行；
  页面不调用后端，也不请求第三方接口。
- 发布后使用 Chrome DevTools Protocol 做真实浏览器验收：**104 项**（96 桌面 + 8 移动），
  覆盖 wasm/JS 语义、输入、主题持久化、复制、模块跳转与移动端布局。
- 一键复现：

```bash
moon check --target all --warn-list +73 --deny-warn
moon test  --target all --warn-list +73 --deny-warn   # 328 × 4 = 1312
node scripts/check_coverage.mjs                        # 94.2%（1335/1417）
node scripts/mutation_test.mjs                         # 14/14 KILLED
node scripts/check_docs.mjs                            # 76 项
node scripts/check_polyphones.mjs                      # 多音字覆盖门禁
node scripts/check_pages.mjs                           # 104 项
```

**移植边界**

`convert` / `data` 的字典与查表接口参考 pinyin4cj（MIT）；`reverse` / `segment` /
`fuzzy` / `disambiguate` / `search` / `tone` / `normalize` / `lm` / `input` /
`shuangpin` 自研。pypinyin 大词库仅用于消歧与输入法候选；`convert` 保持“多音字字级
全展开”契约，不引入大词库——这是有意的语义边界，避免改变既有 API 行为。

**AI 使用说明**

AI 辅助测试、文档、展示页与部分实现；算法选型、边界与验收由人工确认，结论以
`moon test`、覆盖率、变异、文档/页面门禁实测为准，不以生成内容作为事实来源。

**预期交付**

MoonBit 包、`demo`、14 份包 README、1312 测试、104 项页面门禁、在线交互演示。

> 技术细节与组委会关切逐条回复见 `docs/proposal_appendix.md` 与 `回复组委会关切.md`。