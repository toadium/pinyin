///|
/// 字典视图常量集合，从 @data 子包读取构建期内嵌的字面量并绑定为运行时 Map 视图。
/// 四个常量均为 pub let 可见性，作为主包公共只读常量暴露。
/// 对应源库 pinyin_resource.cj 的资源加载逻辑（构建期内嵌替代运行时 IO）。

///|
/// 繁体→简体汉字码点映射，2533 条，对应源库 CHINESE_MAP。
pub let chinese_map : Map[Int, Int] = @data.chinese_dict

///|
/// 单字拼音映射，20903 条，对应源库 PINYIN_TABLE。
pub let pinyin_table : Map[String, String] = @data.pinyin_dict

///|
/// 词组拼音映射，843 条，对应源库 MUTIL_PINYIN_TABLE。
pub let mutil_pinyin_table : Map[String, String] = @data.mutil_pinyin_dict

///|
/// 通用拼音映射，82 条，对应源库 TONGYONG_PINYIN_TABLE。
pub let tongyong_pinyin_table : Map[String, String] = @data.tongyong_pinyin_dict
