///|
/// pinyin — MoonBit 拼音引擎
///
/// 汉字→拼音 + 拼音→汉字 + 拼音分词 + 模糊匹配 + 多音字消歧 +
/// 搜索索引 + 变调规则 + 编辑距离 + 拼音规范化 + 繁简转换 +
/// 多音字 + 声调格式，移植自 pinyin4cj。
///
/// 包结构（扁平多根包布局，线性无环依赖）：
///
/// ```
/// core（零依赖：类型 + 声调转换 + Trie）
///   ↑
/// data（零依赖：字典数据）
///   ↑
/// convert（PinyinHelper + ChineseHelper）
///   ↑
/// ┌───┴───┬──────────┬──────────┐
/// reverse segment  fuzzy    disambiguate
/// (反向)  (分词)   (模糊)   (消歧+变调)
///     ↑         ↑         ↑
///   search（搜索索引）
///   normalize（规范化+编辑距离）
///   tone（?）
/// ```
///
/// 用户应直接导入所需子包，例如：
/// ```moonbit nocheck
/// import {
///   "walkzzz/pinyin/convert",
/// }
/// ```
pub let version : String = "0.4.0"
