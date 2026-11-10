///|
/// PinyinSearchIndex 拼音搜索索引，支持首字母搜索、连续拼音搜索、模糊拼音搜索。
/// 为中文文本建立倒排索引，通过拼音快速检索中文文档。
pub struct PinyinSearchIndex {
  initial_index : Map[String, Array[Int32]]
  pinyin_index : Map[String, Array[Int32]]
  documents : Array[String]
}

///|
/// 创建空搜索索引。
pub fn PinyinSearchIndex::new() -> PinyinSearchIndex {
  { initial_index: Map([]), pinyin_index: Map([]), documents: [], }
}

///|
/// 添加文档到搜索索引，返回文档 ID。
/// 自动为文档建立首字母索引和无调拼音索引。
/// 对多音字取第一个读音，确保索引键唯一。
pub fn PinyinSearchIndex::add_document(
  self : PinyinSearchIndex,
  text : String,
) -> Int32 raise PinyinError {
  if text.length() == 0 {
    raise PinyinError("Please enter a word or sentence")
  }
  let doc_id = self.documents.length()
  self.documents.push(text)
  let initial_buf = StringBuilder()
  let pinyin_buf = StringBuilder()
  for c in text {
    if ChineseHelper::is_chinese(c) || c == chinese_ling {
      match pinyin_table.get(c.to_string()) {
        Some(v) => {
          let pinyin_array = v
            .split(pinyin_separator[:])
            .map(fn(x) { x.to_owned() })
            .to_array()
          if pinyin_array.length() > 0 {
            let first_pinyin = pinyin_array[0]
            let without_tone = strip_tone(first_pinyin)
            if without_tone.length() > 0 {
              initial_buf.write_char(without_tone[0].unsafe_to_char())
            }
            pinyin_buf.write_string(without_tone)
          }
        }
        None => {
          initial_buf.write_char(c)
          pinyin_buf.write_string(c.to_string())
        }
      }
    } else {
      initial_buf.write_char(c)
      pinyin_buf.write_string(c.to_string())
    }
  }
  let initial_str = initial_buf.to_string()
  let pinyin_str = pinyin_buf.to_string()
  match self.initial_index.get(initial_str) {
    Some(arr) => arr.push(doc_id)
    None => self.initial_index[initial_str] = [doc_id]
  }
  match self.pinyin_index.get(pinyin_str) {
    Some(arr) => arr.push(doc_id)
    None => self.pinyin_index[pinyin_str] = [doc_id]
  }
  doc_id
}

///|
/// 首字母搜索：输入首字母串（如 "zgr"），返回匹配的文档列表。
pub fn PinyinSearchIndex::search_initial(
  self : PinyinSearchIndex,
  query : String,
) -> Array[String] {
  match self.initial_index.get(query) {
    Some(arr) => {
      let result : Array[String] = []
      for id in arr {
        result.push(self.documents[id])
      }
      result
    }
    None => []
  }
}

///|
/// 连续拼音搜索：输入无调拼音串（如 "zhongguoren"），返回匹配的文档列表。
pub fn PinyinSearchIndex::search_pinyin(
  self : PinyinSearchIndex,
  query : String,
) -> Array[String] {
  match self.pinyin_index.get(query) {
    Some(arr) => {
      let result : Array[String] = []
      for id in arr {
        result.push(self.documents[id])
      }
      result
    }
    None => []
  }
}

///|
/// 模糊拼音搜索：对查询进行模糊扩展后搜索，返回匹配的文档列表。
/// 例如输入 "zongguoren" 也能匹配 "中国人"（zh↔z 模糊）。
pub fn PinyinSearchIndex::search_fuzzy(
  self : PinyinSearchIndex,
  query : String,
) -> Array[String] {
  let exact = PinyinSearchIndex::search_pinyin(self, query)
  if exact.length() > 0 {
    return exact
  }
  let segments = PinyinSegmenter::segment_best(query)
  if segments.length() == 0 {
    return []
  }
  let expanded_segments : Array[Array[String]] = []
  for seg in segments {
    expanded_segments.push(FuzzyPinyinHelper::fuzzy_expand(seg))
  }
  let result : Array[String] = []
  let seen : Map[String, Unit] = Map([])
  PinyinSearchIndex::search_combinations(
    self, expanded_segments, 0, "", result, seen,
  )
  result
}

///|
/// 递归搜索所有模糊扩展组合。
fn PinyinSearchIndex::search_combinations(
  self : PinyinSearchIndex,
  expanded_segments : Array[Array[String]],
  pos : Int32,
  current : String,
  result : Array[String],
  seen : Map[String, Unit],
) -> Unit {
  if pos >= expanded_segments.length() {
    match self.pinyin_index.get(current) {
      Some(arr) =>
        for id in arr {
          let doc = self.documents[id]
          if !seen.contains(doc) {
            seen[doc] = ()
            result.push(doc)
          }
        }
      None => ()
    }
    return
  }
  for variant in expanded_segments[pos] {
    PinyinSearchIndex::search_combinations(
      self,
      expanded_segments,
      pos + 1,
      current + variant,
      result,
      seen,
    )
  }
}
