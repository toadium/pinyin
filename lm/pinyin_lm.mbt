///|
/// PinyinLM 命名空间类型，提供 N-gram 拼音语言模型能力。
/// 基于 Unigram/Bigram/Trigram 频率统计，支持 Laplace 平滑和 Katz 回退，
/// 计算拼音序列的概率和困惑度（Perplexity），为拼音输入法引擎和消歧提供概率基础。
#warnings("-struct_never_constructed")
pub struct PinyinLM {}

///|
/// 语言模型统计信息。
pub struct LMStats {
  /// 无调拼音音节总数（词汇量 V）
  vocab_size : Int32
  /// Unigram 总频次
  unigram_total : Int32
  /// Bigram 总频次
  bigram_total : Int32
  /// Trigram 总频次
  trigram_total : Int32
  /// 不同 Unigram 数量
  unigram_types : Int32
  /// 不同 Bigram 数量
  bigram_types : Int32
  /// 不同 Trigram 数量
  trigram_types : Int32
}

///|
/// Unigram 频率表：无调拼音 → 频率。
pub let unigram_freq : Map[String, Int32] = {
  let result : Map[String, Int32] = Map([])
  for _k, v in @data.pinyin_dict {
    let pinyin_array = v
      .split(@core.pinyin_separator[:])
      .map(fn(x) { x.to_owned() })
      .to_array()
    for pinyin in pinyin_array {
      let without_tone = @core.strip_tone(pinyin)
      match result.get(without_tone) {
        Some(count) => result[without_tone] = count + 1
        None => result[without_tone] = 1
      }
    }
  }
  result
}

///|
/// Bigram 频率表：前一个无调拼音 → (后一个无调拼音 → 频率)。
pub let bigram_freq : Map[String, Map[String, Int32]] = {
  let result : Map[String, Map[String, Int32]] = Map([])
  for _word, pinyin_str in @data.mutil_pinyin_dict {
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
/// Trigram 频率表：(前两个无调拼音) → (第三个无调拼音 → 频率)。
/// 键格式为 "p1,p2"（逗号分隔）。
let trigram_freq : Map[String, Map[String, Int32]] = {
  let result : Map[String, Map[String, Int32]] = Map([])
  for _word, pinyin_str in @data.mutil_pinyin_dict {
    let pinyin_array = @core.convert_without_tone(pinyin_str)
    if pinyin_array.length() >= 3 {
      for i in 0..<(pinyin_array.length() - 2) {
        let p1 = pinyin_array[i]
        let p2 = pinyin_array[i + 1]
        let p3 = pinyin_array[i + 2]
        let key = p1 + "," + p2
        match result.get(key) {
          Some(inner) =>
            match inner.get(p3) {
              Some(count) => inner[p3] = count + 1
              None => inner[p3] = 1
            }
          None => {
            let inner : Map[String, Int32] = Map([])
            inner[p3] = 1
            result[key] = inner
          }
        }
      }
    }
  }
  result
}

///|
/// 计算 Unigram 总频次。
fn unigram_total_count() -> Int32 {
  let mut total : Int32 = 0
  for _k, v in unigram_freq {
    total += v
  }
  total
}

///|
/// 计算 Bigram 总频次。
fn bigram_total_count() -> Int32 {
  let mut total : Int32 = 0
  for _k, inner in bigram_freq {
    for _k2, v in inner {
      total += v
    }
  }
  total
}

///|
/// 计算 Trigram 总频次。
fn trigram_total_count() -> Int32 {
  let mut total : Int32 = 0
  for _k, inner in trigram_freq {
    for _k2, v in inner {
      total += v
    }
  }
  total
}

///|
/// 计算 Unigram 类型数（不同音节数量）。
fn unigram_type_count() -> Int32 {
  let mut count : Int32 = 0
  for _k, _v in unigram_freq {
    count += 1
  }
  count
}

///|
/// 计算 Bigram 类型数。
fn bigram_type_count() -> Int32 {
  let mut count : Int32 = 0
  for _k, inner in bigram_freq {
    for _k2, _v in inner {
      count += 1
    }
  }
  count
}

///|
/// 计算 Trigram 类型数。
fn trigram_type_count() -> Int32 {
  let mut count : Int32 = 0
  for _k, inner in trigram_freq {
    for _k2, _v in inner {
      count += 1
    }
  }
  count
}

///|
/// Unigram 概率（Laplace 平滑）：P(w) = (count(w) + 1) / (N + V)。
/// N = 总频次，V = 词汇量（不同音节数量）。
pub fn PinyinLM::unigram_prob(pinyin : String) -> Double {
  let v = unigram_type_count().to_double()
  let n = unigram_total_count().to_double()
  let count = match unigram_freq.get(pinyin) {
    Some(c) => c.to_double()
    None => 0.0
  }
  (count + 1.0) / (n + v)
}

///|
/// Bigram 概率（Laplace 平滑）：P(w2|w1) = (count(w1,w2) + 1) / (count(w1) + V)。
/// 未见 bigram 回退到 smoothed unigram。
pub fn PinyinLM::bigram_prob(prev : String, curr : String) -> Double {
  let v = unigram_type_count().to_double()
  let prev_count = match unigram_freq.get(prev) {
    Some(c) => c.to_double()
    None => 0.0
  }
  let pair_count = match bigram_freq.get(prev) {
    Some(inner) =>
      match inner.get(curr) {
        Some(c) => c.to_double()
        None => 0.0
      }
    None => 0.0
  }
  if prev_count > 0.0 {
    (pair_count + 1.0) / (prev_count + v)
  } else {
    PinyinLM::unigram_prob(curr)
  }
}

///|
/// Trigram 概率（Katz 回退）：
/// P(w3|w1,w2) = (count(w1,w2,w3) + 1) / (count(w1,w2) + V)  （如果 count(w1,w2) > 0）
/// 否则回退到 P(w3|w2)（bigram）。
pub fn PinyinLM::trigram_prob(
  p2 : String,
  p1 : String,
  curr : String,
) -> Double {
  let v = unigram_type_count().to_double()
  let key = p2 + "," + p1
  let pair_count = match bigram_freq.get(p2) {
    Some(inner) =>
      match inner.get(p1) {
        Some(c) => c.to_double()
        None => 0.0
      }
    None => 0.0
  }
  if pair_count > 0.0 {
    let tri_count = match trigram_freq.get(key) {
      Some(inner) =>
        match inner.get(curr) {
          Some(c) => c.to_double()
          None => 0.0
        }
      None => 0.0
    }
    (tri_count + 1.0) / (pair_count + v)
  } else {
    PinyinLM::bigram_prob(p1, curr)
  }
}

///|
/// 整句概率（对数概率）：log P(s) = Σ log P(w_i | w_{i-1})。
/// 使用 Bigram 模型计算。空串返回 0.0。
pub fn PinyinLM::sentence_log_prob(pinyin_array : Array[String]) -> Double {
  if pinyin_array.length() == 0 {
    return 0.0
  }
  let mut log_prob : Double = 0.0
  log_prob += @math.ln(PinyinLM::unigram_prob(pinyin_array[0]))
  for i in 1..<pinyin_array.length() {
    log_prob += @math.ln(
      PinyinLM::bigram_prob(pinyin_array[i - 1], pinyin_array[i]),
    )
  }
  log_prob
}

///|
/// 整句概率（Trigram 模型，对数概率）：
/// log P(s) = Σ log P(w_i | w_{i-2}, w_{i-1})。
/// 首词用 unigram，次词用 bigram，之后用 trigram。
/// 空串返回 0.0。
pub fn PinyinLM::sentence_log_prob_trigram(
  pinyin_array : Array[String],
) -> Double {
  if pinyin_array.length() == 0 {
    return 0.0
  }
  let mut log_prob : Double = 0.0
  log_prob += @math.ln(PinyinLM::unigram_prob(pinyin_array[0]))
  if pinyin_array.length() >= 2 {
    log_prob += @math.ln(
      PinyinLM::bigram_prob(pinyin_array[0], pinyin_array[1]),
    )
  }
  for i in 2..<pinyin_array.length() {
    log_prob += @math.ln(
      PinyinLM::trigram_prob(
        pinyin_array[i - 2],
        pinyin_array[i - 1],
        pinyin_array[i],
      ),
    )
  }
  log_prob
}

///|
/// 困惑度（Perplexity）：PP = exp(-1/N × Σ log P(w_i | context))。
/// 使用 Bigram 模型。输入为拼音数组列表（多句子）。
/// 困惑度越低表示模型对数据拟合越好。
/// 空句子列表或所有句子均为空时抛 PinyinError（困惑度无定义）。
pub fn PinyinLM::perplexity(
  sentences : Array[Array[String]],
) -> Double raise @core.PinyinError {
  let mut total_log_prob : Double = 0.0
  let mut total_words : Int32 = 0
  for sentence in sentences {
    total_words += sentence.length()
    total_log_prob += PinyinLM::sentence_log_prob(sentence)
  }
  if total_words == 0 {
    @core.raise_invalid_input(
      "Cannot compute perplexity: empty sentences or all sentences are empty",
    )
  }
  @math.exp(-total_log_prob / total_words.to_double())
}

///|
/// 困惑度（Trigram 模型）。
/// 空句子列表或所有句子均为空时抛 PinyinError（困惑度无定义）。
pub fn PinyinLM::perplexity_trigram(
  sentences : Array[Array[String]],
) -> Double raise @core.PinyinError {
  let mut total_log_prob : Double = 0.0
  let mut total_words : Int32 = 0
  for sentence in sentences {
    total_words += sentence.length()
    total_log_prob += PinyinLM::sentence_log_prob_trigram(sentence)
  }
  if total_words == 0 {
    @core.raise_invalid_input(
      "Cannot compute perplexity: empty sentences or all sentences are empty",
    )
  }
  @math.exp(-total_log_prob / total_words.to_double())
}

///|
/// 线性插值平滑概率：P(w3|w1,w2) = λ1·P_trigram + λ2·P_bigram + λ3·P_unigram。
/// λ1 + λ2 + λ3 应等于 1.0，函数不做归一化检查（调用者负责）。
/// 任意 λ 为负数时抛 PinyinError。
/// 提供比 Katz 回退更平滑的概率估计，是 NLP 教科书标准方法。
pub fn PinyinLM::interpolation_prob(
  p2 : String,
  p1 : String,
  curr : String,
  lambda1 : Double,
  lambda2 : Double,
  lambda3 : Double,
) -> Double raise @core.PinyinError {
  if lambda1 < 0.0 || lambda2 < 0.0 || lambda3 < 0.0 {
    @core.raise_invalid_input(
      "Interpolation lambdas must be non-negative, got: " +
      lambda1.to_string() +
      ", " +
      lambda2.to_string() +
      ", " +
      lambda3.to_string(),
    )
  }
  lambda1 * PinyinLM::trigram_prob(p2, p1, curr) +
  lambda2 * PinyinLM::bigram_prob(p1, curr) +
  lambda3 * PinyinLM::unigram_prob(curr)
}

///|
/// 整句概率（Interpolation 模型，对数概率）：
/// log P(s) = Σ log P(w_i | w_{i-2}, w_{i-1}, λ1, λ2, λ3)。
/// 首词用 unigram，次词用 bigram，之后用 interpolation。
/// 空串返回 0.0。负数 λ 抛 PinyinError。
pub fn PinyinLM::sentence_log_prob_interpolation(
  pinyin_array : Array[String],
  lambda1 : Double,
  lambda2 : Double,
  lambda3 : Double,
) -> Double raise @core.PinyinError {
  if pinyin_array.length() == 0 {
    return 0.0
  }
  let mut log_prob : Double = 0.0
  log_prob += @math.ln(PinyinLM::unigram_prob(pinyin_array[0]))
  if pinyin_array.length() >= 2 {
    log_prob += @math.ln(
      PinyinLM::bigram_prob(pinyin_array[0], pinyin_array[1]),
    )
  }
  for i in 2..<pinyin_array.length() {
    log_prob += @math.ln(
      PinyinLM::interpolation_prob(
        pinyin_array[i - 2],
        pinyin_array[i - 1],
        pinyin_array[i],
        lambda1,
        lambda2,
        lambda3,
      ),
    )
  }
  log_prob
}

///|
/// 困惑度（Interpolation 模型）。
/// 空句子列表或所有句子均为空时抛 PinyinError（困惑度无定义）。
pub fn PinyinLM::perplexity_interpolation(
  sentences : Array[Array[String]],
  lambda1 : Double,
  lambda2 : Double,
  lambda3 : Double,
) -> Double raise @core.PinyinError {
  let mut total_log_prob : Double = 0.0
  let mut total_words : Int32 = 0
  for sentence in sentences {
    total_words += sentence.length()
    total_log_prob += PinyinLM::sentence_log_prob_interpolation(
      sentence, lambda1, lambda2, lambda3,
    )
  }
  if total_words == 0 {
    @core.raise_invalid_input(
      "Cannot compute perplexity: empty sentences or all sentences are empty",
    )
  }
  @math.exp(-total_log_prob / total_words.to_double())
}

///|
/// 获取语言模型统计信息。
pub fn PinyinLM::stats() -> LMStats {
  {
    vocab_size: unigram_type_count(),
    unigram_total: unigram_total_count(),
    bigram_total: bigram_total_count(),
    trigram_total: trigram_total_count(),
    unigram_types: unigram_type_count(),
    bigram_types: bigram_type_count(),
    trigram_types: trigram_type_count(),
  }
}
