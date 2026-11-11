///|
/// PinyinDisambiguator 命名空间类型，提供多音字上下文消歧能力。
/// 使用 Viterbi 算法 + bigram 词频模型，自动推断多音字在上下文中的正确读音。
#warnings("-struct_never_constructed")
pub struct PinyinDisambiguator {}

///|
/// bigram 词频表：前一个无调拼音 → (后一个无调拼音 → 频率)。
/// 从 mutil_pinyin_table 运行时构建，用于 Viterbi 消歧。
let pinyin_bigram_freq : Map[String, Map[String, Int32]] = {
  let result : Map[String, Map[String, Int32]] = Map([])
  for _word, pinyin_str in @convert.mutil_pinyin_table {
    let pinyin_array = @core.convert_without_tone(pinyin_str)
    if pinyin_array.length() >= 2 {
      for i in 0..<(pinyin_array.length() - 1) {
        let prev = pinyin_array[i]
        let next = pinyin_array[i + 1]
        match result.get(prev) {
          Some(inner) =>
            match inner.get(next) {
              Some(count) => inner[next] = count + 1
              None => inner[next] = 1
            }
          None => {
            let inner : Map[String, Int32] = Map([])
            inner[next] = 1
            result[prev] = inner
          }
        }
      }
    }
  }
  result
}

///|
/// 获取 bigram 频率，未见 bigram 返回 0。
fn bigram_count(prev : String, next : String) -> Int32 {
  match pinyin_bigram_freq.get(prev) {
    Some(inner) =>
      match inner.get(next) {
        Some(count) => count
        None => 0
      }
    None => 0
  }
}

///|
/// 多音字上下文消歧：使用 Viterbi 算法 + bigram 词频模型，
/// 自动推断每个汉字在上下文中的最优读音。
/// 返回带调拼音数组（每个字一个读音）。
/// 例如 "银行" → ["yín", "háng"]，"重要" → ["zhòng", "yào"]。
pub fn PinyinDisambiguator::disambiguate(
  str : String,
) -> Array[String] raise @core.PinyinError {
  let chars = str.to_array()
  if chars.length() == 0 {
    @core.raise_invalid_input("Please enter a word or sentence")
  }
  let all_readings : Array[Array[String]] = []
  for c in chars {
    if @convert.ChineseHelper::is_chinese(c) || c == @core.chinese_ling {
      match @convert.pinyin_table.get(c.to_string()) {
        Some(v) => {
          let readings = v
            .split(@core.pinyin_separator[:])
            .map(fn(x) { x.to_owned() })
            .to_array()
          all_readings.push(readings)
        }
        None => all_readings.push([c.to_string()])
      }
    } else {
      all_readings.push([c.to_string()])
    }
  }
  let n = all_readings.length()
  if n == 1 {
    return [all_readings[0][0]]
  }
  let dp : Array[Array[Int32]] = []
  let prev_idx : Array[Array[Int32]] = []
  for _ in 0..<n {
    dp.push([])
    prev_idx.push([])
  }
  for _ in 0..<all_readings[0].length() {
    dp[0].push(0)
    prev_idx[0].push(-1)
  }
  for i in 1..<n {
    for j in 0..<all_readings[i].length() {
      let current_no_tone = @core.strip_tone(all_readings[i][j])
      let mut best_score = -1
      let mut best_prev = 0
      for k in 0..<all_readings[i - 1].length() {
        let prev_no_tone = @core.strip_tone(all_readings[i - 1][k])
        let score = dp[i - 1][k] +
          bigram_count(prev_no_tone, current_no_tone) +
          1
        if score > best_score {
          best_score = score
          best_prev = k
        }
      }
      dp[i].push(best_score)
      prev_idx[i].push(best_prev)
    }
  }
  let mut best_last = 0
  let mut best_last_score = -1
  for j in 0..<all_readings[n - 1].length() {
    if dp[n - 1][j] > best_last_score {
      best_last_score = dp[n - 1][j]
      best_last = j
    }
  }
  let result : Array[String] = []
  let mut idx = best_last
  let mut i = n - 1
  while i >= 0 {
    result.push(all_readings[i][idx])
    idx = prev_idx[i][idx]
    i -= 1
  }
  let reversed : Array[String] = []
  for k in 0..<result.length() {
    reversed.push(result[result.length() - 1 - k])
  }
  reversed
}
