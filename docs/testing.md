# 测试策略

## 测试组织

| 文件 | 类型 | 测试数 | 内容 |
|------|------|--------|------|
| `pinyin_easy_wbtest.mbt` | 白盒 | 13 | 内部逻辑覆盖（声调转换、字典查找） |
| `pinyin_mid_test.mbt` | 黑盒 | 19 | 正向用例、格式转换、自定义字典、共享引用 |
| `pinyin_difficult_test.mbt` | 黑盒 | 5 | 字典完整性验证（条目数、采样、边界） |
| `examples/*.mbt` | 黑盒 | 14 | 示例测试（chinese 2 + pinyin_helper 5 + array 4 + custom 3） |
| `README.mbt.md` | 可执行 | 11 | README 中的可执行测试块 |
| **总计** | | **60 / 后端** | |

## 四后端验证

```bash
moon test --target wasm      --warn-list +73 --deny-warn   # 60/60 ✓
moon test --target wasm-gc   --warn-list +73 --deny-warn   # 60/60 ✓
moon test --target js        --warn-list +73 --deny-warn   # 60/60 ✓
moon test --target native    --warn-list +73 --deny-warn   # 60/60 ✓
```

四后端共 240 测试全通过，严格模式零警告零错误。

## CI 流程

```bash
moon fmt    --check                                       # 格式检查
moon check  --target all --warn-list +73 --deny-warn      # 四后端编译检查
moon build  --target all --warn-list +73 --deny-warn      # 四后端构建
moon test   --target all --warn-list +73 --deny-warn      # 四后端测试
moon info   --target all                                  # 生成接口文件
```

## 测试约定

- 白盒测试（`_wbtest.mbt`）：验证内部逻辑，可访问包私有成员
- 黑盒测试（`_test.mbt`）：通过公开 API 验证端到端行为，需 `@pinyin.` 限定访问宿主包
- 示例测试（`examples/`）：可运行的示例，兼做测试
- `inspect` / `debug_inspect` 用于快照断言，`assert_eq` / `assert_true` / `assert_false` 用于稳定结果断言
- 自定义字典测试用 `set` + `remove` 清理副作用，避免测试间污染

## Warning 治理记录（v0.1.1）

| Warning | 数量 | 根因 | 治理 |
|---|---|---|---|
| `[0025] test_unqualified_package` | 46 | 黑盒测试/README 裸用宿主包类型与全局变量 | 加 `@pinyin.` 限定前缀 |
| `[0020] deprecated to_repr` | 4 | example 用过时 `to_repr(x)` | 改为 `Repr(x)` |
| `[0073] unnecessary_annotation` | 7 | `format=@pinyin.PinyinFormat::Xxx` 限定冗余 | 枚举变体裸用（类型由参数推断） |