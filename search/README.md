# search

拼音搜索索引：首字母、全拼与模糊拼音检索。

[← 返回总览](../README.md)

## 安装

```bash
moon add walkzzz/pinyin@0.8.0
```

```moonbit
// moon.pkg
import {
  "walkzzz/pinyin/search" as @search
}
```

## 主要接口

| 接口 | 说明 |
|---|---|
| `PinyinSearchIndex::new()` | 创建空索引 |
| `PinyinSearchIndex::add_document(text)` | 加入文档，返回文档 id（非汉字抛错） |
| `PinyinSearchIndex::search_initial(initials)` | 按首字母检索，如 `"zws"` |
| `PinyinSearchIndex::search_pinyin(pinyin)` | 按连续全拼检索 |
| `PinyinSearchIndex::search_fuzzy(pinyin)` | 模糊检索（带规则扩展） |

## 示例

```moonbit
let index = @search.PinyinSearchIndex::new()
ignore(index.add_document("中文搜索"))
ignore(index.add_document("拼音引擎"))

let byInitial = index.search_initial("zws")
// ["中文搜索"]

let byPinyin = index.search_pinyin("zhongwensousuo")
// ["中文搜索"]

let fuzzy = index.search_fuzzy("zongwensousuo")
// ["中文搜索"]
```

## 行为说明

- 索引是倒排结构（首字母表 + 全拼表），查询 O(1) 定位候选集。
- 文档按加入顺序编号，结果返回文档原文。
- 模糊检索会扩展 zh/z、ch/c、sh/s、in/ing 等规则。

## 相关

- [API 文档](../docs/api.md#search-包)
- [模糊规则](../fuzzy/README.md)
- [测试策略](../docs/testing.md)