///|
/// 大词库聚合入口：pypinyin phrases_dict 转换的 47k+ 词组拼音表。
/// 数据源：https://raw.githubusercontent.com/mozillazg/python-pinyin/master/pypinyin/phrases_dict.json
/// SHA256：a45ff140a6b631ca9c82127b280a2f414e0aba6bb2824a0e9d1e77fff359c665
/// 由 scripts/gen_large_phrases.py 生成；字符串分片规避 wasm 初始化局部变量上限。
pub let large_phrase_count : Int32 = 47110

///|
pub let large_phrase_max_chars : Int32 = 9

///|
/// 解析 "词\t拼音\n" 文本为查找表。
fn parse_large_phrase_raw(raw : String) -> Map[String, String] {
  let table : Map[String, String] = Map([])
  for raw_line in raw.split("\n") {
    let line = raw_line.to_owned()
    if line.length() > 0 {
      let parts = line.split("\t").map(fn(x) { x.to_owned() }).to_array()
      if parts.length() == 2 {
        table[parts[0]] = parts[1]
      }
    }
  }
  table
}

///|
let large_phrase_shards : Array[Map[String, String]] = [
  parse_large_phrase_raw(large_phrase_raw_01),
  parse_large_phrase_raw(large_phrase_raw_02),
  parse_large_phrase_raw(large_phrase_raw_03),
  parse_large_phrase_raw(large_phrase_raw_04),
  parse_large_phrase_raw(large_phrase_raw_05),
  parse_large_phrase_raw(large_phrase_raw_06),
]

///|
/// 查询大词库；未命中返回 None。
pub fn large_phrase_lookup(word : String) -> String? {
  let mut found : String? = None
  for shard in large_phrase_shards {
    if found is None {
      match shard.get(word) {
        Some(value) => found = Some(value)
        None => ()
      }
    }
  }
  found
}
