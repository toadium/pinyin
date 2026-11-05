# 路线图

## 版本 0.1.5（当前）

- ✅ 源码布局重构：`src/` → 根目录（对齐 chrono_tz-mbt 约定）
- ✅ 多后端支持：wasm / wasm-gc / js / native（60/60 × 4）
- ✅ AGENTS.md 创建
- ✅ docs/ 开发文档补充

## 版本 0.1.0（初始）

- ✅ 核心移植：pinyin4cj Cangjie → MoonBit
- ✅ 4 张字典：chinese(2533) + pinyin(20903) + mutil(843) + tongyong(82)
- ✅ PinyinHelper API：convert_to_pinyin_string / convert_to_pinyin_array / get_short_pinyin
- ✅ ChineseHelper API：繁简转换 + 汉字判断
- ✅ PinyinFormat：WithToneMark / WithoutTone / WithToneNumber / FirstLetter
- ✅ 自定义字典扩展：add_pinyin_dict_resource / add_mutil_pinyin_dict_resource / add_chinese_dict_resource
- ✅ 46 个测试（easy 11 + mid 16 + difficult 5 + examples 14）
- ✅ CI：check --target all + test + fmt --check

## 未来计划

- 白盒测试拆分（内部逻辑覆盖）
- 基准测试
- 更多字典格式支持