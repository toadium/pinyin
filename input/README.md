# input

拼音输入法引擎：Beam Search + LM 评分，支持全拼、简拼、双拼、模糊输入与用户词库。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/input" as @input,
  "walkzzz/pinyin/shuangpin" as @shuangpin
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinInputEngine::new()` | 创建引擎（beam 宽度 10） |
| `PinyinInputEngine::with_beam_width(n)` | 指定 beam 宽度 |
| `PinyinInputEngine::input(pinyin)` | 全拼 / 简拼候选 |
| `PinyinInputEngine::input_initial(initials)` | 首字母串候选（不抛错） |
| `PinyinInputEngine::input_shuangpin(scheme, pinyin)` | 双拼候选 |
| `PinyinInputEngine::input_fuzzy(pinyin)` | 模糊输入候选 |
| `PinyinInputEngine::input_all_segments(pinyin)` | 全切分候选 |
| `PinyinInputEngine::input_with_limit(pinyin, n)` | 截断候选数 |
| `PinyinInputEngine::add_user_dict(dict)` | 注入用户词库 |
| `InputScoringConfig` | 用户词 / 词组加分与候选上限 |
| `InputCandidate` | `text` / `score` / `segments` |

## 示例

```moonbit
let engine = @input.PinyinInputEngine::new()

let candidates = engine.input("nihao")
// candidates[0].text == "你好"

let byInitial = engine.input_initial("zg")
// ["中国", ...]

let shuangpin = engine.input_shuangpin(@shuangpin.ShuangpinScheme::Xiaohe, "nihc")
// ["你好", ...]
```

## 行为说明

- 解码流程：分词 → 反查 → 常用字优先 → Beam Search + LM 剪枝 → 词组合并去重。
- 词组候选优先来自 `mutil_pinyin_dict`（843）与 `common_phrases`（151）。
- 候选按评分排序，同分时按汉字常用度（`common_char_rank`）排序。
- 非法拼音抛 `PinyinError`；空串在 `input` 中抛错，`input_initial` 返回空数组。

## 相关

- [API 文档](../docs/api.md#input-包)
- [双拼方案](../shuangpin/README.md)
- [语言模型](../lm/README.md)
- [测试策略](../docs/testing.md)