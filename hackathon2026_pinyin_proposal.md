# pinyin 项目申报书

> 2026 MoonBit 国产基础软件开源大赛 | 方向：开发者工具 | 申报日期：2026-11-05 | 更新日期：2026-11-11

---

## 基本信息

- 项目名称：pinyin：MoonBit 拼音引擎
- 参赛者：walkzzz
- 联系方式：13689047817 745244185@qq.com
- GitHub 仓库链接：https://github.com/toadium/pinyin.git
- mooncakes 包名：`walkzzz/pinyin`
- 是否为移植项目：是（从 pinyin4cj 仓颉版移植，完整移植全部 API + 自研八大核心引擎）

---

## 项目简介

pinyin 是一个 MoonBit 拼音引擎，提供双向拼音转换、智能分词、上下文消歧、搜索索引、变调规则、编辑距离与规范化能力。库以 Map 字面量内嵌 4 张字典（24361 条），构建期固化，无运行时 IO，四后端全通过。从仓颉版 pinyin4cj 完整移植 pinyin_helper + chinese_helper 全部 API，并自研八大核心引擎：Trie 数据结构（~420 音节）、Trie+DP 分词、BFS 模糊匹配、Viterbi+bigram 消歧、倒排索引搜索、声调变调规则、音节级编辑距离、拼音规范化。

mooncakes 调研：31909 个包中匹配 pinyin 的仅 2 个——本项目与 `wjhfather/pinyin-toolkit`（异构方案，基于 Unicode 17.0 Unihan）。本项目在功能覆盖面和算法深度上全面超越 pinyin-toolkit。

---

## 当前完成状态（v0.4.0）

| 指标 | 数值 |
|------|------|
| 包数 | **10**（core/data/convert/reverse/segment/fuzzy/disambiguate/search/tone/normalize） |
| 测试数 | **151/后端**（四后端共 604 全通过） |
| 工程严格度 | ✅ `--warn-list +73 --deny-warn` 零警告零错误 |
| 字典条目 | **24361**（chinese 2533 + pinyin 20903 + mutil 843 + tongyong 82） |
| 公开 API | **49**（15 个类/枚举） |
| mooncakes | ✅ `walkzzz/pinyin@0.1.1`（32 下载），v0.4.0 待发布 |

---

## 技术方案

### 10 包扁平多根架构

```
core（零依赖）    data（零依赖）
  ↑                  ↑
convert（core+data）
  ↑
┌───┴───┬──────────┬──────────┐
reverse segment  fuzzy    disambiguate
    ↑         ↑         ↑
  search    normalize    tone
```

参照 owl-mbt 项目理念，线性无环依赖，core/data 零依赖，各子包职责单一。根包为文档入口（不导入子包），用户直接导入子包。

### 八大自研核心引擎

1. **PinyinTrie**：自研 Trie，~420 音节构建期固化
2. **Trie+DP 分词**：全切分 + 最优切分，处理歧义（"xian" → ["xi","an"] 或 ["xian"]）
3. **BFS 模糊匹配**：18 条双向规则（9 组：zh↔z, ch↔c, sh↔s, n↔l, f↔h, in↔ing, en↔eng, an↔ang, ong↔eng），扩展 + Trie 验证 + 去重
4. **Viterbi+bigram 消歧**：从 843 条词组构建 bigram 频率表，动态规划选最优读音序列
5. **倒排索引搜索**：首字母/连续拼音/模糊拼音搜索
6. **声调变调引擎**：三声变调/一变调/不变调/七变调/八变调（5 类变调规则）
7. **音节级编辑距离**：Levenshtein + 模糊距离（等价音节代价为 0）
8. **拼音规范化**：大小写/数字调→带调标记/v→ü/声调位置纠正

**PinyinStreamProcessor**：流式拼音处理器，逐字符输入汉字实时输出增量拼音（new/feed/flush/reset），适用于输入法等实时场景。

### PinyinError 跨包设计

`pub(all) suberror PinyinError { InvalidInput(String) }`。由于 MoonBit [0073] 跨包 bug，提供 `pub fn raise_invalid_input(msg) -> Unit raise PinyinError` 包装函数。

---

## 核心功能范围

| 包 | 类 | 方法数 | 核心功能 |
|---|---|---|---|
| convert | PinyinHelper | 8 | 词句转拼音、多音字数组、首字母、通用拼音、自定义字典 |
| convert | ChineseHelper | 6 | 繁简互转、汉字判断、自定义字典 |
| convert | PinyinStreamProcessor | 4 | 流式处理：new/feed/flush/reset |
| reverse | ReversePinyinHelper | 4 | 无调/带调/数字调反向查找、合法音节判断 |
| segment | PinyinSegmenter | 3 | 全切分/最优切分/可切分判断 |
| fuzzy | FuzzyPinyinHelper | 3 | 模糊扩展/等价判断/模糊反向查找（9 组规则） |
| disambiguate | PinyinDisambiguator | 1 | Viterbi+bigram 上下文消歧 |
| search | PinyinSearchIndex | 5 | 倒排索引：首字母/连续/模糊搜索 |
| tone | ToneSandhiHelper | 1 | 三声变调/一变调/不变调/七变调/八变调 |
| normalize | PinyinEditDistance | 2 | Levenshtein + 模糊距离 |
| normalize | PinyinNormalizer | 3 | 带调标记/数字调/无调规范化 |
| core | PinyinTrie | 4 | Trie insert/contains/prefix_lengths |
| core | PinyinFormat | 4 变体 | WithToneMark/WithoutTone/WithToneNumber/FirstLetter |
| core | FuzzyRule | 2 变体 | Prefix/Suffix |
| core | PinyinError | 1 变体 | InvalidInput(String) |

---

## 质量与测试

| 包 | 白盒 | 黑盒 | 合计 |
|---|---|---|---|
| core | 14 | 0 | 14 |
| convert | 8 | 31 | 39 |
| reverse | 0 | 10 | 10 |
| segment | 0 | 12 | 12 |
| fuzzy | 0 | 19 | 19 |
| disambiguate | 0 | 7 | 7 |
| search | 0 | 7 | 7 |
| tone | 0 | 12 | 12 |
| normalize | 0 | 17 | 17 |
| examples | 0 | 14 | 14 |
| **总计** | **22** | **129** | **151/后端** |

四后端共 604 测试全通过，严格模式零警告零错误。
## mooncakes.io 生态对比

| 库 | 数据源 | 字典条目 | 繁简 | 反向查找 | 分词 | 消歧 | 搜索 | 变调 | 编辑距离 | 规范化 | 四后端 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **walkzzz/pinyin** | pinyin4cj 内嵌 | 24361 | ✅ | ✅ | ✅ | ✅ Viterbi | ✅ | ✅ | ✅ | ✅ | ✅ 604 |
| wjhfather/pinyin-toolkit | Unicode 17.0 | 未公开 | ✗ | ✗ | ✗ | ✗ override | ✅ | ✗ | ✅ | ✅ | ✅ |

**差异化定位**：本项目是 mooncakes.io 唯一 pinyin4cj 移植；独有反向查找、拼音分词、Viterbi 消歧、变调规则、繁简互转；10 包扁平架构参照 owl-mbt。


## 版本交付计划

| 版本 | 交付内容 | 状态 |
|------|---------|------|
| v0.1.0 | 核心移植 pinyin4cj → MoonBit | ✅ |
| v0.1.1 | 工程化 + warning 治理 + 严格 deny-warn | ✅ |
| v0.2.0 | 反向查找 + 拼音分词 + 模糊匹配 | ✅ |
| v0.3.0 | 消歧 + 搜索索引 + 变调 + 编辑距离 + 规范化 | ✅ |
| v0.4.0 | 10 包架构重构 + PinyinError 跨包 + 七/八变调 + 3组新模糊规则 + PinyinStreamProcessor | ✅ |

---

## 验收标准对齐

| 大赛验收项 | 满足方式 |
|-----------|---------|
| MoonBit 为主 | 100% MoonBit，10 包扁平架构 |
| 仓库公开可访问 | GitHub，v0.1.0~v0.4.0 持续迭代 |
| 源代码结构清晰 | 10 包职责单一，线性无环依赖 |
| README 可复现 | README + 14 示例 + 604 测试 |
| CI 覆盖检查/构建/测试 | `--target all --warn-list +73 --deny-warn` |
| 可运行示例 | examples 包 14 个示例测试 |
| 完整测试覆盖 | 151/后端 × 4 = 604 |
| OSI 许可证 | MIT，参考来源 pinyin4cj 已标注 |
| 发布到 mooncakes | `walkzzz/pinyin@0.1.1` 已发布 |

**参考项目**：[pinyin4cj](https://gitcode.com/pinyin4cj/pinyin4cj) — 仓颉原版（MIT）。**设计原则**：完整移植 + 自研八大引擎；逐函数手动转换；字典内嵌构建期固化；