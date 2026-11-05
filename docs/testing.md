# 测试策略

## 测试组织

| 文件 | 类型 | 测试数 | 内容 |
|------|------|--------|------|
| `pinyin_easy_test.mbt` | 黑盒 | 11 | 基础功能与边界条件 |
| `pinyin_mid_test.mbt` | 黑盒 | 16 | 正向用例、格式转换、自定义字典 |
| `pinyin_difficult_test.mbt` | 黑盒 | 5 | 字典完整性验证 |
| `examples/*.mbt` | 黑盒 | 14 | 示例测试 |
| **总计** | | **46** | |

## 四后端验证

```bash
moon test --target wasm      # 60/60 ✓
moon test --target wasm-gc   # 60/60 ✓
moon test --target js        # 60/60 ✓
moon test --target native    # 60/60 ✓
```

## CI 流程

```yaml
- moon check --target all   # 四后端编译检查
- moon test                 # 运行测试
- moon fmt --check          # 格式检查
```

## 测试约定

- 黑盒测试（`_test.mbt`）：通过公开 API 验证端到端行为
- 白盒测试（`_wbtest.mbt`）：验证内部逻辑（待补充）
- 示例测试（`examples/`）：可运行的示例，兼做测试
- `assert_eq` / `assert_true` 用于稳定结果的断言