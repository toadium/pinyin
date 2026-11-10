///|
/// FuzzyPinyinHelper 命名空间类型，提供拼音模糊匹配能力。
/// 支持南方方言常见混淆：zh↔z, ch↔c, sh↔s, n↔l, in↔ing, en↔eng。
#warnings("-struct_never_constructed")
pub struct FuzzyPinyinHelper {}

///|
/// 模糊匹配规则类型：Prefix 表示声母替换，Suffix 表示韵母后缀替换。
pub(all) enum FuzzyRule {
  Prefix(String, String)
  Suffix(String, String)
}

///|
/// 全部模糊匹配规则。
/// zh↔z, ch↔c, sh↔s（声母混淆），n↔l（声母混淆），
/// in↔ing, en↔eng（韵母后缀混淆）。
pub let fuzzy_rules : Array[FuzzyRule] = [
  Prefix("zh", "z"),
  Prefix("z", "zh"),
  Prefix("ch", "c"),
  Prefix("c", "ch"),
  Prefix("sh", "s"),
  Prefix("s", "sh"),
  Prefix("n", "l"),
  Prefix("l", "n"),
  Suffix("in", "ing"),
  Suffix("ing", "in"),
  Suffix("en", "eng"),
  Suffix("eng", "en"),
]

///|
/// 对单个拼音应用所有模糊规则，生成模糊等价拼音集合（含原始拼音）。
/// 仅保留合法拼音音节（通过 pinyin_trie 验证）。
/// 例如 "zhong" → ["zhong", "zong"]，"zhen" → ["zhen", "zheng", "zen", "zeng"]。
pub fn FuzzyPinyinHelper::fuzzy_expand(pinyin : String) -> Array[String] {
  let result : Array[String] = [pinyin]
  let seen : Map[String, Unit] = Map([])
  seen[pinyin] = ()
  let queue : Array[String] = [pinyin]
  while queue.length() > 0 {
    match queue.pop() {
      Some(current) => {
        let variants = FuzzyPinyinHelper::apply_fuzzy_rules(current)
        for v in variants {
          if !seen.contains(v) && pinyin_trie.contains(v) {
            seen[v] = ()
            result.push(v)
            queue.push(v)
          }
        }
      }
      None => break
    }
  }
  result
}

///|
/// 对单个拼音应用所有模糊规则，返回所有变体（不验证合法性，不去重）。
fn FuzzyPinyinHelper::apply_fuzzy_rules(pinyin : String) -> Array[String] {
  let result : Array[String] = []
  for rule in fuzzy_rules {
    match rule {
      Prefix(from, to) =>
        if pinyin.has_prefix(from[:]) {
          result.push(to + pinyin[from.length():].to_owned())
        }
      Suffix(from, to) =>
        if pinyin.has_suffix(from[:]) {
          result.push(pinyin[:pinyin.length() - from.length()].to_owned() + to)
        }
    }
  }
  result
}

///|
/// 判断两个拼音是否模糊等价（含完全相同）。
pub fn FuzzyPinyinHelper::fuzzy_match(
  pinyin1 : String,
  pinyin2 : String,
) -> Bool {
  if pinyin1 == pinyin2 {
    return true
  }
  let variants = FuzzyPinyinHelper::fuzzy_expand(pinyin1)
  for v in variants {
    if v == pinyin2 {
      return true
    }
  }
  false
}

///|
/// 模糊反向查找：对给定拼音进行模糊扩展后，返回所有模糊等价拼音对应的汉字集合。
/// 例如 "zhong" → 查找 "zhong" 和 "zong" 对应的所有汉字。
pub fn FuzzyPinyinHelper::fuzzy_reverse_lookup(
  pinyin : String,
) -> Array[String] raise PinyinError {
  if pinyin.length() == 0 {
    raise PinyinError("Please enter a pinyin syllable")
  }
  let variants = FuzzyPinyinHelper::fuzzy_expand(pinyin)
  let result : Array[String] = []
  let seen : Map[String, Unit] = Map([])
  for v in variants {
    match reverse_pinyin_table.get(v) {
      Some(arr) =>
        for ch in arr {
          if !seen.contains(ch) {
            seen[ch] = ()
            result.push(ch)
          }
        }
      None => ()
    }
  }
  result
}
