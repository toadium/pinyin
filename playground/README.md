# playground

浏览器演示导出层：把拼音引擎编译成一份 JS，在页面内直接调用。

[← 返回总览](../README.md)

## 用途

GitHub Pages 的在线演示由本包提供：`pkgtype(kind: "foreign_library")` +
`#export_name` 导出 17 个**非 raise** 函数，错误折叠为空串，JS 侧无需异常映射。
除基础转换/消歧/输入法外，还覆盖 pinyin4cj 的十项功能示例：繁简互转、词句转换、
自定义输出格式、三类自定义字典、多音字集合、繁简转拼音与通用拼音。

## 导出函数

| 导出名 | 签名 | 返回 |
|---|---|---|
| `pinyin_version` | `() -> String` | 版本号 |
| `pinyin_convert` | `(text, separator, format) -> String` | 拼音串；`format` 为 `mark` / `number` / `plain` / `initial` |
| `pinyin_disambiguate` | `(text) -> String` | 空格分隔的逐字带调读音 |
| `pinyin_input` | `(pinyin) -> String` | 最多 10 个候选，`\|` 分隔 |
| `pinyin_shuangpin` | `(scheme, input) -> String` | 空格分隔全拼；方案为 `xiaohe` / `ziranma` |
| `pinyin_segment` | `(pinyin) -> String` | 空格分隔的最优切分 |
| `pinyin_normalize` | `(pinyin) -> String` | 规范化结果 |
| `pinyin_to_simplified` | `(text) -> String` | 繁 → 简 |
| `pinyin_to_traditional` | `(text) -> String` | 简 → 繁 |
| `pinyin_convert_sentence` | `(text) -> String` | 词句 → 带调拼音（空格分隔） |
| `pinyin_convert_format` | `(text, separator, format) -> String` | 自定义格式输出 |
| `pinyin_add_dict_char` | `(char, readings, text) -> String` | 注入单字字典后转换 |
| `pinyin_add_dict_phrase` | `(phrase, readings, text) -> String` | 注入词组字典后转换 |
| `pinyin_add_dict_chinese` | `(trad, simp, text) -> String` | 注入繁简映射后转换 |
| `pinyin_multi_readings` | `(text) -> String` | 逐字读音集合（`字: a/b`） |
| `pinyin_convert_traditional` | `(text, format) -> String` | 繁体 → 拼音（先转简） |
| `pinyin_tongyong` | `(text) -> String` | 通用拼音（`字: a/b`） |

## 构建

```bash
moon build --target js --release playground
```

产物：

```text
_build/js/release/build/playground/playground.js
```

页面侧以 ES module 直接导入：

```js
import {
  pinyin_version,
  pinyin_convert,
  pinyin_disambiguate,
  pinyin_input,
  pinyin_shuangpin,
  pinyin_segment,
  pinyin_normalize,
} from "./playground.js";
```

## 示例

```js
pinyin_convert("我是中国人", " ", "mark");
// "wǒ shì zhōng guó rén"

pinyin_disambiguate("我明天还钱");
// "wǒ míng tiān huán qián"

pinyin_input("nihao").split("|")[0];
// "你好"
```

## 约束

- 导出函数必须保持非 raise；新增导出需同步 `docs/app.js` 与 `scripts/check_pages.mjs`。
- 产物包含完整字典（4.73 MB，gzip 0.86 MB），页面加载即完成初始化。
- 修改导出或交互后需跑浏览器验收，字符串断言不能替代真实运行。

## 相关

- [API 文档](../docs/api.md#convert-包)
- [页面入口](../docs/index.html)
- [展示页门禁](../scripts/check_pages.mjs)