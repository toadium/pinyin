///|
/// PinyinSegmenter 命名空间类型，提供连续拼音串分词能力。
/// 使用 Trie + 动态规划算法，处理歧义切分（如 "xian" → ["xi","an"] 或 ["xian"]）。
#warnings("-struct_never_constructed")
pub struct PinyinSegmenter {}

///|
/// 连续拼音串分词：返回所有可能的切分方案。
/// 例如 "nihao" → [["ni","hao"]]，"xian" → [["xi","an"],["xian"]]。
/// 空串返回 []，无法切分的串返回 []。
pub fn PinyinSegmenter::segment(pinyin_str : String) -> Array[Array[String]] {
  if pinyin_str.length() == 0 {
    return []
  }
  let n = pinyin_str.length()
  let chars = pinyin_str.to_array()
  // dp[i] = 从位置 0 到 i-1 的所有可能切分方案
  let dp : Array[Array[Array[String]]] = []
  for _ in 0..<=n {
    dp.push([])
  }
  dp[0] = [[]]
  for i in 1..<=n {
    for j in 0..<i {
      let prefix = String::from_array(chars[j:i])
      if pinyin_trie.contains(prefix) {
        for seg in dp[j] {
          let new_seg = seg.copy()
          new_seg.push(prefix)
          dp[i].push(new_seg)
        }
      }
    }
  }
  dp[n].copy()
}

///|
/// 连续拼音串最优分词：返回音节数最少的切分方案。
/// 使用动态规划，贪心选择最长匹配优先。
/// 例如 "nihao" → ["ni","hao"]，"xian" → ["xian"]。
/// 空串返回 []，无法切分的串返回 []。
pub fn PinyinSegmenter::segment_best(pinyin_str : String) -> Array[String] {
  if pinyin_str.length() == 0 {
    return []
  }
  let n = pinyin_str.length()
  let chars = pinyin_str.to_array()
  // dp[i] = 从位置 0 到 i-1 的最少音节数，-1 表示不可达
  let dp_count : Array[Int32] = []
  // prev[i] = 最优切分中位置 i 的前驱位置
  let dp_prev : Array[Int32] = []
  for _ in 0..<=n {
    dp_count.push(-1)
    dp_prev.push(-1)
  }
  dp_count[0] = 0
  for i in 1..<=n {
    for j in 0..<i {
      if dp_count[j] >= 0 {
        let prefix = String::from_array(chars[j:i])
        if pinyin_trie.contains(prefix) {
          let candidate = dp_count[j] + 1
          if dp_count[i] < 0 || candidate < dp_count[i] {
            dp_count[i] = candidate
            dp_prev[i] = j
          }
        }
      }
    }
  }
  if dp_count[n] < 0 {
    return []
  }
  // 回溯重建最优切分
  let result : Array[String] = []
  let mut i = n
  while i > 0 {
    let j = dp_prev[i]
    let syllable = String::from_array(chars[j:i])
    result.push(syllable)
    i = j
  }
  let reversed : Array[String] = []
  for i in 0..<result.length() {
    reversed.push(result[result.length() - 1 - i])
  }
  reversed
}

///|
/// 判断连续拼音串是否可以完全切分为合法音节。
pub fn PinyinSegmenter::can_segment(pinyin_str : String) -> Bool {
  if pinyin_str.length() == 0 {
    return false
  }
  let n = pinyin_str.length()
  let chars = pinyin_str.to_array()
  let dp : Array[Bool] = []
  for _ in 0..<=n {
    dp.push(false)
  }
  dp[0] = true
  for i in 1..<=n {
    for j in 0..<i {
      if dp[j] {
        let prefix = String::from_array(chars[j:i])
        if pinyin_trie.contains(prefix) {
          dp[i] = true
          break
        }
      }
    }
  }
  dp[n]
}
