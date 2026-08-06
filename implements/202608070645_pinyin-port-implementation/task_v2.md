# 任务指令（v2）

## 动作
NEW

## 任务描述

在主包（项目根目录）定义两个基础类型，为后续全部公开 API 提供类型基础：

1. **`PinyinFormat`**（`pub(all) enum`，4 变体 + `name` 方法）— 预期文件：`pinyin_format.mbt`
   - 变体：`WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`
   - 方法：`pub fn name(self : PinyinFormat) -> String`，按变体返回 `"WITH_TONE_MARK"` / `"WITHOUT_TONE"` / `"WITH_TONE_NUMBER"` / `"FIRST_LETTER"`（返回值逐字符对齐源库 `getName()`）

2. **`PinyinError`**（`pub(all) suberror`，单变体携带消息）— 预期文件：`pinyin_error.mbt`
   - 变体：`PinyinError(String)`（携带错误消息字符串）
   - 后续方法以 `raise PinyinError` 抛错，调用方以 `catch { PinyinError::PinyinError(msg) => ... }` 捕获

验证：`moon check` 通过（exit code 0）。`unused_package` 警告仍存在（预期，本任务不引用数据子包）。

## 选择理由

- **底层优先**：`PinyinFormat` 是所有拼音转换方法的参数类型（`convert_to_pinyin_string` / `convert_to_pinyin_array` / `get_short_pinyin` 等），`PinyinError` 是所有可抛错方法的异常类型（`convert_to_pinyin_string` 空串 / `has_multi_pinyin` 非汉字 / `get_short_pinyin` 空串）。两者是全部公开 API 的基础类型依赖，必须在算法实现与 API 定义之前完成。
- **无需字典数据**：两类型为纯枚举/错误定义，不依赖 `data/` 子包的字典字面量，可在字典生成任务之前独立完成。
- **粒度合理**：两类型紧密相关（均为基础枚举/错误类型，共同构成 API 签名基础），合并为一个任务符合"1-3 个紧密相关类型"的粒度约定。
- **依赖关系**：本任务仅依赖 R1（项目骨架），不依赖任何前置编码任务；后续任务（字典字面量、`pinyin_dicts.mbt`、`pinyin_helper.mbt`、`chinese_helper.mbt`、`tone_conversion.mbt`、测试文件）均依赖本任务产出的类型。

## 任务上下文

### 技术方案依据

- **§7.1 类型形态**：
  - `PinyinFormat` → `pub(all) enum`，公开，4 变体 `WithToneMark` / `WithoutTone` / `WithToneNumber` / `FirstLetter`
  - `PinyinError` → `pub(all) suberror`，公开，单变体 `PinyinError(String)` 携带消息
- **§7.3 公开 API 方法清单与命名映射**：
  - 源库 `PinyinFormat.getName()` → MoonBit `PinyinFormat::name(self) -> String`，变体名，无异常
- **§7.4 错误处理策略**：
  - 采用 `raise PinyinError`（非 `Result[T, PinyinError]`），符合 MoonBit 检查式错误惯例（`suberror` + `raise`/`catch`），语义对齐源库 `throw`
  - 错误消息文本逐字符对齐源库（后续任务使用，本任务仅定义类型）
- **§10.1 移植映射表**：
  - `pinyin_format.cj`（33行）→ `pinyin/pinyin_format.mbt`，手写逻辑
  - `utils.cj`（25行）→ `pinyin/pinyin_error.mbt`，`Pinyin4cjException` → `PinyinError` suberror
- **§十一 关键技术决策**：
  - T9：重载实现用 labeled 参数默认值 `format~ = WithToneMark`（依赖 `PinyinFormat` 类型存在）
  - T10：错误模型 `raise PinyinError`（suberror），MoonBit 检查式错误惯例

### 源库参考

**`pinyin_format.cj`（33行）**：
```cangjie
public enum PinyinFormat {
    | WITH_TONE_MARK
    | WITHOUT_TONE
    | WITH_TONE_NUMBER
    | FIRST_LETTER

    public func getName(): String {
        match(this){
            case WITH_TONE_MARK => return "WITH_TONE_MARK"
            case WITHOUT_TONE => return "WITHOUT_TONE"
            case WITH_TONE_NUMBER => return "WITH_TONE_NUMBER"
            case FIRST_LETTER => return "FIRST_LETTER"
        }
    }
}
```

**`utils.cj`（25行）**：
```cangjie
public class Pinyin4cjException <: Exception {
    private var messages: String = ""
    public init(messages: String) {
        super(messages)
        this.messages = messages
    }
    public func getMessage(): String {
        return messages
    }
    public override func toString(): String {
        return "Pinyin4cjException: ${messages}"
    }
}
```

### 命名映射

| 源库 | MoonBit | 说明 |
|------|---------|------|
| `PinyinFormat` | `PinyinFormat` | 类型名 PascalCase 保持 |
| `WITH_TONE_MARK` | `WithToneMark` | 枚举变体 PascalCase |
| `WITHOUT_TONE` | `WithoutTone` | 枚举变体 PascalCase |
| `WITH_TONE_NUMBER` | `WithToneNumber` | 枚举变体 PascalCase |
| `FIRST_LETTER` | `FirstLetter` | 枚举变体 PascalCase |
| `getName()` | `name(self)` | 方法名 lower_snake，self 参数 |
| `Pinyin4cjException` | `PinyinError` | 异常类 → suberror |
| `messages` 字段 | suberror 变体载荷 `PinyinError(String)` | 消息字符串作为变体参数 |

### 约束

- 类型名 PascalCase，枚举变体 PascalCase，方法名 lower_snake（技术方案 §7.3 命名规范）
- `PinyinFormat` 用 `pub(all) enum`（公开所有变体与方法）
- `PinyinError` 用 `pub(all) suberror`（公开所有变体，MoonBit 检查式错误惯例）
- `name` 方法返回值逐字符对齐源库（`"WITH_TONE_MARK"` 等大写下划线形式，非变体名 PascalCase 形式）
- 代码包含必要注释和文档（用户偏好）
- 不引用数据子包（`@data.xxx`），不添加 `import`，不修改 `moon.pkg` / `moon.mod` / `data/moon.pkg`
- 不预创建后续任务文件（`pinyin_helper.mbt` / `chinese_helper.mbt` / `pinyin_dicts.mbt` / `tone_conversion.mbt` / `pinyin_spec.mbt` / 测试文件等）

## 已有代码上下文

### R1 产出（项目骨架，已通过验证）

- `moon.mod`：模块根元数据，name=`pinyin/pinyin`，version=`0.1.0`，license=MIT，零外部依赖，无 options/supported_targets
- `moon.pkg`：主包配置，`import { "pinyin/pinyin/data" }`，库包
- `data/moon.pkg`：数据子包配置，纯数据包零依赖，仅含注释
- `README.mbt.md`：占位 README，一级标题 + 一行简介

### 当前项目状态

- `moon check` 通过（exit code 0，1 warnings `unused_package`，0 errors）
- 无任何 `.mbt` 源文件存在
- 主包零源文件，import 的数据子包未被引用（`unused_package` 警告根因）

### 本任务对已有代码的影响

- 新增 `pinyin_format.mbt` / `pinyin_error.mbt` 两个 `.mbt` 源文件于项目根目录（主包）
- 不修改任何已有文件
- `unused_package` 警告将持续（本任务不引用数据子包），后续字典加载任务（`pinyin_dicts.mbt` 引用 `@data.xxx`）后消除