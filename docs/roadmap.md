# 路线图

## 版本 0.4.0（当前）

- ✅ 架构重构：3 包 → 10 包扁平多根布局（参照 owl-mbt 项目理念）
  - core（零依赖）：PinyinFormat / PinyinError / FuzzyRule / PinyinTrie / 声调转换
  - data（零依赖）：4 张字典字面量
  - convert（core+data）：PinyinHelper / ChineseHelper / 字典视图常量
  - reverse（core+data）：拼音→汉字反向查找
  - segment（core）：Trie+DP 拼音分词
  - fuzzy（core+reverse）：BFS 模糊匹配
  - disambiguate（core+convert）：Viterbi+bigram 多音字消歧
  - search（core+convert+segment+fuzzy）：倒排索引搜索
  - tone（core）：声调变调规则
  - normalize（core+segment+fuzzy）：规范化 + 编辑距离
- ✅ 根包改为文档入口（不导入任何子包），用户直接导入子包
- ✅ PinyinError 变体从 `PinyinError(String)` 改为 `InvalidInput(String)`
- ✅ 解决 MoonBit [0073] 跨包 bug：添加 `pub fn raise_invalid_input` 包装函数
- ✅ 黑盒测试迁移到各自子包目录，白盒测试拆分到 core / convert
- ✅ 测试数 144→151/后端（四后端共 604 测试全通过）
- ✅ CI 升级为严格模式 `--target all --warn-list +73 --deny-warn`
- ✅ 文档全面更新：README / README.mbt.md / docs/ / AGENTS.md / CHANGELOG.md
- ✅ 新增七变调/八变调规则（tone 包，5 类变调）
- ✅ 新增 3 组模糊规则：f↔h, an↔ang, ong↔eng（fuzzy 包，9 组规则）
- ✅ 新增 PinyinStreamProcessor 流式处理接口（convert 包，逐字符输入实时输出）

## 版本 0.3.0

- ✅ 多音字上下文消歧（PinyinDisambiguator：Viterbi + bigram 词频模型）
- ✅ 拼音搜索索引（PinyinSearchIndex：倒排索引，首字母/连续拼音/模糊搜索）
- ✅ 声调变调规则（ToneSandhiHelper：三声变调/一变调/不变调）
- ✅ 拼音编辑距离（PinyinEditDistance：音节级 Levenshtein + 模糊距离）
- ✅ 拼音规范化（PinyinNormalizer：大小写/数字调→带调标记/v→ü/声调位置纠正）
- ✅ 公开 API 33→45

## 版本 0.2.0

- ✅ 拼音→汉字反向查找（ReversePinyinHelper：无调/带调/数字调）
- ✅ 拼音分词（PinyinSegmenter：Trie+DP，全切分/最优切分/可切分判断）
- ✅ 模糊匹配（FuzzyPinyinHelper：6 组规则，BFS 扩展/等价判断/模糊反向查找）
- ✅ PinyinTrie 数据结构（~420 拼音音节，自研 Trie）
- ✅ FuzzyRule 枚举（Prefix / Suffix）

## 版本 0.1.1

- ✅ 源码布局重构：`src/` → 根目录（对齐 chrono_tz-mbt 约定）
- ✅ 多后端支持：wasm / wasm-gc / js / native
- ✅ 严格模式 `--warn-list +73 --deny-warn` 四后端全绿
- ✅ Warning 全面治理：[0025] + [0020] + [0073]
- ✅ AGENTS.md 创建，docs/ 开发文档补充
- ✅ 白盒测试补充，字典视图共享引用验证

## 版本 0.1.0（初始）

- ✅ 核心移植：pinyin4cj Cangjie → MoonBit
- ✅ 4 张字典：chinese(2533) + pinyin(20903) + mutil(843) + tongyong(82)
- ✅ PinyinHelper API + ChineseHelper API + PinyinFormat + 自定义字典扩展
- ✅ CI：check --target all + test + fmt --check

## 未来计划

- 基准测试（bench）
- 更多字典格式支持
- 拼音→汉字反向查找的声调精确匹配
