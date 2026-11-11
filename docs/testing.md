# 测试策略

## 测试组织

| 包 | 文件 | 类型 | 测试数 | 内容 |
|------|------|------|--------|------|
| `core` | `pinyin_core_wbtest.mbt` | 白盒 | 5 | PinyinFormat + PinyinError 内部逻辑 |
| `core` | `pinyin_trie_wbtest.mbt` | 白盒 | 9 | Trie + strip_tone 内部逻辑 |
| `convert` | `convert_wbtest.mbt` | 白盒 | 8 | 转换引擎内部逻辑 |
| `convert` | `convert_test.mbt` | 黑盒 | 19 | 正向用例、格式转换、自定义字典、共享引用 |
| `convert` | `convert_dict_test.mbt` | 黑盒 | 5 | 字典完整性验证（条目数、采样、边界） |
| `convert` | `stream_processor_test.mbt` | 黑盒 | 7 | 流式处理器（feed/flush/reset/增量输出） |
| `reverse` | `reverse_test.mbt` | 黑盒 | 10 | 反向查找（无调/带调/数字调/合法性） |
| `segment` | `segment_test.mbt` | 黑盒 | 12 | 分词（全切分/最优切分/歧义切分） |
| `fuzzy` | `fuzzy_test.mbt` | 黑盒 | 19 | 模糊匹配（扩展/等价/反向查找，9 组规则） |
| `disambiguate` | `disambiguate_test.mbt` | 黑盒 | 7 | 多音字消歧（Viterbi+bigram） |
| `search` | `search_test.mbt` | 黑盒 | 7 | 搜索索引（首字母/连续/模糊） |
| `tone` | `tone_test.mbt` | 黑盒 | 12 | 声调变调（三声/一变调/不变调/七变调/八变调） |
| `normalize` | `normalizer_test.mbt` | 黑盒 | 10 | 规范化（大小写/ü/v/声调格式） |
| `normalize` | `edit_distance_test.mbt` | 黑盒 | 7 | 编辑距离（Levenshtein/模糊距离） |
| `examples` | `*.mbt` | 黑盒 | 14 | 示例测试（chinese 2 + pinyin_helper 5 + array 4 + custom 3） |
| **总计** | | | **151 / 后端** | |

## 四后端验证

```bash
moon test --target wasm      --warn-list +73 --deny-warn   # 151/151 ✓
moon test --target wasm-gc   --warn-list +73 --deny-warn   # 151/151 ✓
moon test --target js        --warn-list +73 --deny-warn   # 151/151 ✓
moon test --target native    --warn-list +73 --deny-warn   # 151/151 ✓
```

四后端共 604 测试全通过，严格模式零警告零错误。

## CI 流程

```bash
moon fmt    --check                                       # 格式检查
moon check  --target all --warn-list +73 --deny-warn      # 四后端编译检查
moon build  --target all --warn-list +73 --deny-warn      # 四后端构建
moon test   --target all --warn-list +73 --deny-warn      # 四后端测试
moon info   --target all                                  # 生成接口文件
```

## 测试约定

- 白盒测试（`_wbtest.mbt`）：验证内部逻辑，可访问包私有成员，无需 `@包名.` 前缀
- 黑盒测试（`_test.mbt`）：通过公开 API 验证端到端行为，需 `@包名.` 限定访问宿主包
- 示例测试（`examples/`）：可运行的示例，兼做测试
- `inspect` / `debug_inspect` 用于快照断言，`assert_eq` / `assert_true` / `assert_false` 用于稳定结果断言
- 自定义字典测试用 `set` + `remove` 清理副作用，避免测试间污染

## Warning 治理记录

### v0.1.1

| Warning | 数量 | 根因 | 治理 |
|---|---|---|---|
| `[0025] test_unqualified_package` | 46 | 黑盒测试/README 裸用宿主包类型与全局变量 | 加 `@pinyin.` 限定前缀 |
| `[0020] deprecated to_repr` | 4 | example 用过时 `to_repr(x)` | 改为 `Repr(x)` |
| `[0073] unnecessary_annotation` | 7 | `format=@pinyin.PinyinFormat::Xxx` 限定冗余 | 枚举变体裸用（类型由参数推断） |

### v0.4.0

| Warning | 根因 | 治理 |
|---|---|---|
| `[0073] unnecessary_annotation` | `raise @core.PinyinError::InvalidInput("msg")` 在子包中触发误报（MoonBit 编译器 bug：[0073] 检查未考虑去掉前缀后标识符不可见） | 添加 `pub fn raise_invalid_input` 包装函数，子包用 `@core.raise_invalid_input("msg")` 代替直接 raise；catch 块改用 `_` 匹配 |
| `[0025] test_unqualified_package` | 黑盒测试迁移到子包目录后仍需 `@包名.` 前缀 | 各子包黑盒测试文件加对应 `@包名.` 前缀 |