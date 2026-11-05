# 路线图

## 版本 0.1.1（当前）

- ✅ 源码布局重构：`src/` → 根目录（对齐 chrono_tz-mbt 约定）
- ✅ 多后端支持：wasm / wasm-gc / js / native（60/60 × 4 = 240 测试）
- ✅ 严格模式 `--warn-list +73 --deny-warn` 四后端全绿，零警告零错误
- ✅ Warning 全面治理：[0025] test_unqualified_package + [0020] deprecated to_repr + [0073] unnecessary_annotation
- ✅ AGENTS.md 创建，docs/ 开发文档补充（roadmap / architecture / api / testing）
- ✅ 白盒测试补充（pinyin_easy_wbtest.mbt，内部逻辑覆盖）
- ✅ 字典视图常量与 data 包共享引用验证

## 版本 0.1.0（初始）

- ✅ 核心移植：pinyin4cj Cangjie → MoonBit
- ✅ 4 张字典：chinese(2533) + pinyin(20903) + mutil(843) + tongyong(82)
- ✅ PinyinHelper API：convert_to_pinyin_string / convert_to_pinyin_array / get_short_pinyin / has_multi_pinyin / to_tongyong_pinyin_string_array
- ✅ ChineseHelper API：繁简转换 + 汉字判断
- ✅ PinyinFormat：WithToneMark / WithoutTone / WithToneNumber / FirstLetter
- ✅ 自定义字典扩展：add_pinyin_dict_resource / add_mutil_pinyin_dict_resource / add_chinese_dict_resource
- ✅ CI：check --target all + test + fmt --check

## 未来计划

- 白盒测试进一步拆分（tone_conversion 内部逻辑覆盖）
- 基准测试（bench）
- 更多字典格式支持
- 模糊匹配 / 搜索索引能力（评估是否引入异构库或轻量自研）