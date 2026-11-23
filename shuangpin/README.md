# shuangpin

双拼方案：小鹤 / 自然码 ↔ 全拼双向转换，并接入输入法候选。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/shuangpin" as @shuangpin
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `ShuangpinScheme` | `Xiaohe`（小鹤）/ `Ziranma`（自然码） |
| `ShuangpinScheme::from_name(name)` | 解析 `"xiaohe"` / `"小鹤"`，未知返回 `None` |
| `ShuangpinScheme::from_full(syllable)` | 全拼 → 双拼（声母键 + 韵母键） |
| `ShuangpinScheme::to_full(input)` | 双拼串 → 空格分隔全拼 |
| `ShuangpinScheme::name()` | 方案展示名 |

## 示例

```moonbit
let scheme = @shuangpin.ShuangpinScheme::Xiaohe

let full = scheme.to_full("nihc")
// "ni hao"

let short = scheme.from_full("ni hao")
// "nihc"

let name = scheme.name()
// "小鹤双拼"

match @shuangpin.ShuangpinScheme::from_name("自然码") {
  Some(s) => println(s.name())  // "自然码双拼"
  None => println("未知方案")
}
```

## 行为说明

- 键位映射参考 Rime `double_pinyin_flypy` / `double_pinyin` schema。
- 覆盖 zh / ch / sh 声母、零声母与 ü / ün 归一化。
- 奇数长度或未知键位原样返回，不抛错。
- 输入法集成：`PinyinInputEngine::input_shuangpin(scheme, pinyin)`。

## 相关

- [API 文档](../docs/api.md#shuangpin-包)
- [输入法引擎](../input/README.md)
- [测试策略](../docs/testing.md)