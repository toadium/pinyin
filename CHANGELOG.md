#### V0.8.0
- **新增 `shuangpin` 包：双拼输入**
  - 小鹤双拼、自然码双拼 ↔ 全拼互转（Rime 键位映射）
  - `PinyinInputEngine::input_shuangpin` 接入输入法解码
- **输入法增强**
  - 简拼输入 `input_initial`（首字母串 → 词组候选）
  - 常用词表 `data/common_phrases`（147 词），词组候选优先
  - 用户选择学习 `learn`，学习过的候选优先重排
- **消歧增强**
  - 词级优先（常用词表 + 词组表）→ 带调 bigram Viterbi 回退
  - 句内词表最大匹配：`我明天还钱` → `huán qián`，补齐「还」的 26 组动词搭配
  - 常用多音词准确率 99.0%，首读音基线 68.0%
- **展示**
  - GitHub Pages 在线演示：`playground/`（7 个 `#export_name` 导出）+ `docs/` 静态页 + `pages.yml` + `check_pages.mjs`（56 项）
  - 页面内完成拼音转换、输入法候选、双拼、消歧、分词与规范化，无后端
- **质量**
  - 测试 302 → 327 / 后端（四后端共 1308）
  - 新增双拼、简拼、用户学习、消歧 gold 评测

#### V0.7.0
- **输入法候选质量修复（常用字优先）**
  - 新增 `data/common_chars.mbt`：GB2312-80 一级汉字 3755 字 + 高频字序（由 `scripts/gen_common_chars.py` 生成）
  - `PinyinInputEngine` 反查候选按常用度排序并截断，修复生僻字优先问题
  - Beam 路径同分时按候选汉字常用度排序，修复 "nihao" → "你好"、"zhongguo" → "中国"
  - 候选按文本去重，消除重复候选
- **变调同音误伤修复**
  - 一/七/八/不 变调增加原调守卫（一、七、八仅一声，不已四声），避免 "qǐ" 被当作 "七" 改为 "qī"
- **规范化边界修复**
  - 轻声数字 5 正确去除（"ma5" → "ma"）；空串规范化不再返回 "5"
- **工程证据**
  - 测试 225 → 302 / 后端（四后端共 1208）
  - 核心覆盖率 94.2%（排除 data/examples，门槛 92%，每包 ≥85%）
  - 变异测试 13/13 KILLED
  - 新增覆盖率/变异/文档一致性门禁脚本与 CI 多 job
  - 新增 `demo/` 端到端可运行演示（`moon run demo --target native`）
- **文档口径统一**：版本、测试数、工具链版本、包结构、roadmap 与实测对齐

#### V0.6.0
- **输入校验与错误处理强化（对照上游库规范）**
  - `segment`/`segment_best`：空串从返回 `[]` 改为抛 `PinyinError`（破坏性变更，v0.x 允许）
  - `fuzzy_expand`/`fuzzy_match`：空串从静默处理改为抛 `PinyinError`
  - `get_initial`/`get_final`：空串从返回空字符串改为抛 `PinyinError`
  - `PinyinEditDistance::distance`/`fuzzy_distance`：空串抛 `PinyinError`，级联 raise 签名
  - `PinyinLM::perplexity`/`perplexity_trigram`/`perplexity_interpolation`：空句子从返回 ∞ 改为抛 `PinyinError`
  - `PinyinLM::interpolation_prob`：负数 λ 抛 `PinyinError`
  - `PinyinLM::sentence_log_prob_interpolation`：级联 raise 签名
  - `PinyinInputEngine::input_from_segments`：空 segments 从返回 `[]` 改为抛 `PinyinError`
  - `PinyinInputEngine::input_with_limit`：limit < 1 抛 `PinyinError`
  - `PinyinSearchIndex::search_fuzzy`：级联 raise 签名
- **扩展点增强（对照上游库规范 §6 低侵入可扩展）**
  - `FuzzyPinyinHelper::add_fuzzy_rules`：支持追加自定义模糊规则（如方言 r→l 混淆）
  - `PinyinInputEngine::InputScoringConfig`：新增可配置评分结构体（user_dict_bonus/phrase_bonus/candidate_limit）
  - `PinyinInputEngine::set_scoring_config` / `scoring_config`：运行时调整评分策略
  - 原硬编码 10.0/5.0/20 全部改为配置项，默认值不变，向下兼容
- **错误路径测试补全**
  - 新增 18 个错误路径+扩展点测试：segment(2) + search(2) + tone(2) + lm(3) + normalize(2) + convert(3) + fuzzy(1) + input(4)
  - 所有公开 `raise` 函数均有非法输入→PinyinError 测试覆盖
- **文档完善（对照上游库规范 §9）**
  - README 新增「适用场景」与「不适用场景」
  - README 新增「常见问题」（6 条 FAQ）
  - 新增 `CONTRIBUTING.md`（贡献流程、代码规范、测试要求、维护响应时效）
  - `add_pinyin_dict_resource`/`add_mutil_pinyin_dict_resource`/`add_chinese_dict_resource`：新增「全局状态副作用」文档（共享引用、影响范围、不受影响组件）
- **测试数量**：207 → 225 / 后端（共 900 测试，四后端全通过）
- 严格模式 `--warn-list +73 --deny-warn` 零警告零错误

#### V0.5.0
- **新增 `lm` 包：N-gram 语言模型**
  - unigram / bigram / trigram 频率表（从 data 包字典自动构建）
  - Laplace 平滑 + Katz 回退（解决数据稀疏问题）
  - Interpolation 平滑（可配置 λ₁/λ₂/λ₃ 插值权重）
  - 句子对数概率（bigram / trigram / interpolation 模型）
  - 困惑度评估（bigram / trigram / interpolation）
  - LMStats 统计信息（词汇量 / 总频次 / n-gram 类型数）
- **新增 `input` 包：拼音输入法引擎**
  - PinyinInputEngine：Beam Search 解码 + LM 评分
  - InputCandidate 候选结构（text / score / segments）
  - 单条切分候选生成 + 全切分路径候选生成
  - 用户词库（add_user_dict，+10.0 加分）+ 词组优先（build_phrase_table，+5.0 加分）
  - 模糊拼音输入（input_fuzzy，自动扩展模糊音节）
  - 可配置 beam 宽度，候选自动去重排序
- **新增 `core` 包声母/韵母提取**
  - get_initial：提取声母（zh/ch/sh/z/c/s/...）
  - get_final：提取韵母（ong/ang/eng/...）
  - initials_list：22 个声母表
- **新增 `examples/` 子包全覆盖示例**
  - 10 个新示例文件：initials_finals/reverse/segment/fuzzy/disambiguate/search/tone/normalize/lm/input
  - 示例测试：14 → 37
- 依赖拓扑扩展：`lm(core+data+math)` → `input(core+segment+reverse+lm+math+data+fuzzy)`
- 测试数量：169 → 207 / 后端（共 828 测试，四后端全通过）
- 关键词新增 `ngram`、`input-method`
- 项目描述更新：去除"移植自 pinyin4cj"，新增 N-gram 语言模型 + 拼音输入法
- 文档全面更新：README.md / README.mbt.md / docs/ / AGENTS.md / 申报书同步至 v0.5.0

#### V0.4.0
- **架构重构：单包 → 10 包扁平多根布局**（参照 owl-mbt 项目理念）
  - `core`：核心类型 + 声调转换 + Trie（零依赖）
  - `data`：字典数据（零依赖）
  - `convert`：核心转换引擎 PinyinHelper / ChineseHelper（依赖 core + data）
  - `reverse`：拼音→汉字反向查找（依赖 core + data）
  - `segment`：拼音分词 Trie+DP（依赖 core）
  - `fuzzy`：模糊匹配（依赖 core + reverse）
  - `disambiguate`：多音字消歧 Viterbi+bigram（依赖 core + convert）
  - `search`：搜索索引倒排索引（依赖 core + convert + segment + fuzzy）
  - `tone`：声调变调规则（依赖 core）
  - `normalize`：规范化 + 编辑距离（依赖 core + segment + fuzzy）
- 根包改为文档入口（不导入任何子包），用户直接导入子包
- PinyinError 变体从 `PinyinError(String)` 改为 `InvalidInput(String)`
- 解决 MoonBit [0073] 跨包 bug：添加 `pub fn raise_invalid_input` 包装函数
- 黑盒测试迁移到各自子包目录，白盒测试拆分到 core / convert
- 测试数量：60 → 151 / 后端（共 604 测试，四后端全通过）
- CI 升级为严格模式 `--target all --warn-list +73 --deny-warn`
- 文档全面更新：README.md / README.mbt.md / docs/ / AGENTS.md 同步至 v0.4.0 现状
- 新增七变调/八变调规则（tone 包，变调规则 3→5 类）
- 新增 3 组模糊规则：f↔h, an↔ang, ong↔eng（fuzzy 包，模糊规则 6→9 组）
- 新增 PinyinStreamProcessor 流式处理接口（convert 包，4 方法：new/feed/flush/reset）

#### V0.3.0
- 新增多音字上下文消歧（PinyinDisambiguator：Viterbi + bigram 词频模型）
- 新增拼音搜索索引（PinyinSearchIndex：首字母/连续/模糊搜索）
- 新增声调变调规则（ToneSandhiHelper：三声/一/不/七/八变调）
- 新增拼音编辑距离（PinyinEditDistance：音节级 Levenshtein + 模糊距离）
- 新增拼音规范化（PinyinNormalizer：大小写/数字调/v→ü）
- 公开 API 33 → 45

#### V0.2.0
- 新增拼音→汉字反向查找（ReversePinyinHelper：无调/带调/数字调）
- 新增拼音分词（PinyinSegmenter：Trie + DP，全切分/最优切分）
- 新增模糊匹配（FuzzyPinyinHelper：6 组规则，BFS 扩展）
- 新增 PinyinTrie 数据结构（约 420 个拼音音节）
- 新增 FuzzyRule 枚举（Prefix / Suffix）

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
