///|
/// PinyinInputEngine 拼音输入法引擎。
/// 将拼音串解码为汉字候选序列，使用 Beam Search + N-gram 语言模型打分。
/// 集成拼音分词、反向查找、语言模型三大模块，实现完整的拼音输入法核心逻辑。
///
/// 算法流程：
/// 1. 拼音串 → PinyinSegmenter 分词 → 音节序列
/// 2. 每个音节 → ReversePinyinHelper 反查 → 候选汉字集合
/// 3. 构建音节图（Lattice）
/// 4. Beam Search 解码 + PinyinLM Bigram 打分 → 排序候选序列
///
/// 时间复杂度：O(S × B × C)，其中 S=音节数，B=beam 宽度，C=每音节候选数。
pub struct PinyinInputEngine {
  mut beam_width : Int32
  user_dict : Map[String, String]
  mut scoring_config : InputScoringConfig
}

///|
/// 输入法评分配置，控制候选排序时的加分策略。
/// 所有分值均可通过 `set_scoring_config` 调整，实现不同场景下的候选优先级。
pub(all) struct InputScoringConfig {
  /// 用户词库匹配加分（默认 10.0，用户词库优先级最高）
  user_dict_bonus : Double
  /// 内置词组表匹配加分（默认 5.0）
  phrase_bonus : Double
  /// 每音节最大候选汉字数（默认 20，避免组合爆炸）
  candidate_limit : Int32
}

///|
/// 输入候选结果，包含候选文本、对数概率得分和音节切分。
pub(all) struct InputCandidate {
  /// 候选汉字文本
  text : String
  /// 对数概率得分（越高越好）
  score : Double
  /// 对应的无调拼音音节切分
  segments : Array[String]
}

///|
/// 创建默认拼音输入法引擎（beam 宽度 = 10，默认评分配置）。
pub fn PinyinInputEngine::new() -> PinyinInputEngine {
  {
    beam_width: 10,
    user_dict: Map([]),
    scoring_config: {
      user_dict_bonus: 10.0,
      phrase_bonus: 5.0,
      candidate_limit: 20,
    },
  }
}

///|
/// 创建自定义 beam 宽度的拼音输入法引擎。
/// beam_width 越大候选越多但计算越慢，最小为 1。
pub fn PinyinInputEngine::with_beam_width(
  beam_width : Int32,
) -> PinyinInputEngine {
  {
    beam_width: if beam_width < 1 {
      1
    } else {
      beam_width
    },
    user_dict: Map([]),
    scoring_config: {
      user_dict_bonus: 10.0,
      phrase_bonus: 5.0,
      candidate_limit: 20,
    },
  }
}

///|
/// 设置 beam 宽度。
pub fn PinyinInputEngine::set_beam_width(
  self : PinyinInputEngine,
  w : Int32,
) -> Unit {
  self.beam_width = if w < 1 { 1 } else { w }
}

///|
/// 获取 beam 宽度。
pub fn PinyinInputEngine::beam_width(self : PinyinInputEngine) -> Int32 {
  self.beam_width
}

///|
/// 设置评分配置。允许调整用户词库加分、词组加分和每音节候选上限。
/// 例如：`set_scoring_config({ user_dict_bonus: 20.0, phrase_bonus: 8.0, candidate_limit: 30, })`
/// 提升用户词库优先级，扩大候选池。
pub fn PinyinInputEngine::set_scoring_config(
  self : PinyinInputEngine,
  config : InputScoringConfig,
) -> Unit {
  self.scoring_config = config
}

///|
/// 获取当前评分配置。
pub fn PinyinInputEngine::scoring_config(
  self : PinyinInputEngine,
) -> InputScoringConfig {
  self.scoring_config
}

///|
/// 添加用户自定义词库。键为无调拼音串（空格分隔音节），值为汉字词组。
/// 例如：user_dict["zhang san"] = "张三"
/// 用户词库优先于自动反查结果。
pub fn PinyinInputEngine::add_user_dict(
  self : PinyinInputEngine,
  dict : Map[String, String],
) -> Unit {
  for kv in dict {
    self.user_dict[kv.0] = kv.1
  }
}

///|
/// Beam 中的候选路径。
priv struct BeamPath {
  /// 已生成的汉字序列
  chars : Array[String]
  /// 累积对数概率
  log_prob : Double
  /// 上一个音节（用于 bigram 打分）
  last_syllable : String
  /// 候选汉字常用度序号之和（越小越常用，用于同分排序）
  rank_sum : Int32
}

///|
/// 候选汉字的常用度序号。未收录于 GB2312 一级汉字表的字排在最后。
fn char_common_rank(ch : String) -> Int32 {
  @data.common_char_rank(ch)
}

///|
/// 按常用度排序候选汉字，保证截断候选上限时优先保留常用字。
fn sort_chars_by_commonness(chars : Array[String]) -> Array[String] {
  let sorted = chars.copy()
  sorted.sort_by(fn(a : String, b : String) -> Int32 {
    let ra = char_common_rank(a)
    let rb = char_common_rank(b)
    if ra < rb {
      -1
    } else if ra > rb {
      1
    } else {
      0
    }
  })
  sorted
}

///|
/// Beam 路径排序：对数概率优先，同分时常用度序号和更小者优先。
fn compare_beam_path(a : BeamPath, b : BeamPath) -> Int32 {
  if a.log_prob > b.log_prob {
    -1
  } else if a.log_prob < b.log_prob {
    1
  } else if a.rank_sum < b.rank_sum {
    -1
  } else if a.rank_sum > b.rank_sum {
    1
  } else {
    0
  }
}

///|
/// 带常用度序号的候选，用于最终排序时保留同分次序。
priv struct RankedCandidate {
  candidate : InputCandidate
  rank_sum : Int32
}

///|
/// 按候选文本去重，保留排序后的首个（得分最高）候选。
fn dedup_candidates(items : Array[InputCandidate]) -> Array[InputCandidate] {
  let seen : Map[String, Unit] = Map([])
  let result : Array[InputCandidate] = []
  for item in items {
    if !seen.contains(item.text) {
      seen[item.text] = ()
      result.push(item)
    }
  }
  result
}

///|
/// 拼音输入法核心：输入拼音串，返回排序的汉字候选序列。
/// 使用 Beam Search 解码 + Bigram 语言模型打分。
///
/// 例如：
/// - "nihao" → [("你好", -8.5, ["ni","hao"]), ("尼好", -12.3, ["ni","hao"]), ...]
/// - "zhongguo" → [("中国", -7.2, ["zhong","guo"]), ...]
///
/// 空串或无法分词的串返回空数组。
pub fn PinyinInputEngine::input(
  self : PinyinInputEngine,
  pinyin_str : String,
) -> Array[InputCandidate] raise @core.PinyinError {
  if pinyin_str.length() == 0 {
    @core.raise_invalid_input("Please enter a pinyin string")
  }
  let segments = @segment.PinyinSegmenter::segment_best(pinyin_str)
  if segments.length() == 0 {
    return []
  }
  self.input_from_segments(segments)
}

///|
/// 从预分词的音节数组生成候选。
/// 允许调用者使用自定义分词结果。
/// 空音节数组抛 PinyinError。
pub fn PinyinInputEngine::input_from_segments(
  self : PinyinInputEngine,
  segments : Array[String],
) -> Array[InputCandidate] raise @core.PinyinError {
  if segments.length() == 0 {
    @core.raise_invalid_input("Segments array must not be empty")
  }
  let joined = segments.join(" ")
  let phrase_candidates : Array[InputCandidate] = []
  // 用户词库优先
  match self.user_dict.get(joined) {
    Some(text) =>
      phrase_candidates.push({
        text,
        score: self.scoring_config.user_dict_bonus,
        segments: segments.copy(),
      })
    None => ()
  }
  // 词组表匹配
  let phrase_table = build_phrase_table()
  match phrase_table.get(joined) {
    Some(text) =>
      if !self.user_dict.contains(joined) {
        phrase_candidates.push({
          text,
          score: self.scoring_config.phrase_bonus,
          segments: segments.copy(),
        })
      }
    None => ()
  }
  // 为每个音节查找候选汉字
  let all_candidates : Array[Array[String]] = []
  for seg in segments {
    let chars = try @reverse.ReversePinyinHelper::reverse_lookup(seg) catch {
      _ => []
    } noraise {
      arr => arr
    }
    if chars.length() == 0 {
      all_candidates.push([seg])
    } else {
      let sorted_chars = sort_chars_by_commonness(chars)
      let limit = if sorted_chars.length() > self.scoring_config.candidate_limit {
        sorted_chars[:self.scoring_config.candidate_limit].to_owned()
      } else {
        sorted_chars
      }
      all_candidates.push(limit)
    }
  }
  // Beam Search
  let beam : Array[BeamPath] = [
    { chars: [], log_prob: 0.0, last_syllable: "", rank_sum: 0, },
  ]
  let mut current_beam = beam
  for i in 0..<segments.length() {
    let syllable = segments[i]
    let candidates = all_candidates[i]
    let new_beam : Array[BeamPath] = []
    for path in current_beam {
      for c in candidates {
        let new_log_prob = if path.last_syllable.length() == 0 {
          path.log_prob + @math.ln(@lm.PinyinLM::unigram_prob(syllable))
        } else {
          path.log_prob +
          @math.ln(@lm.PinyinLM::bigram_prob(path.last_syllable, syllable))
        }
        let new_chars = path.chars.copy()
        new_chars.push(c)
        new_beam.push({
          chars: new_chars,
          log_prob: new_log_prob,
          last_syllable: syllable,
          rank_sum: path.rank_sum + char_common_rank(c),
        })
      }
    }
    new_beam.sort_by(compare_beam_path)
    let max_k = if new_beam.length() > self.beam_width {
      self.beam_width
    } else {
      new_beam.length()
    }
    current_beam = new_beam[:max_k].to_owned()
  }
  // 转换为 InputCandidate
  let ranked : Array[RankedCandidate] = []
  for path in current_beam {
    let text = path.chars.join("")
    ranked.push({
      candidate: { text, score: path.log_prob, segments: segments.copy(), },
      rank_sum: path.rank_sum,
    })
  }
  // 合并词组/用户词库候选（高分优先）
  for pc in phrase_candidates {
    ranked.push({ candidate: pc, rank_sum: 0, })
  }
  ranked.sort_by(fn(a : RankedCandidate, b : RankedCandidate) -> Int32 {
    compare_beam_path(
      {
        chars: [],
        log_prob: a.candidate.score,
        last_syllable: "",
        rank_sum: a.rank_sum,
      },
      {
        chars: [],
        log_prob: b.candidate.score,
        last_syllable: "",
        rank_sum: b.rank_sum,
      },
    )
  })
  let results : Array[InputCandidate] = []
  for item in ranked {
    results.push(item.candidate)
  }
  dedup_candidates(results)
}

///|
/// 拼音输入法（全分词模式）：输入拼音串，返回所有可能分词路径的候选序列。
/// 对每种分词方案分别执行 Beam Search，合并后按得分排序。
/// 例如 "xian" 会同时考虑 ["xi","an"] 和 ["xian"] 两种切分。
pub fn PinyinInputEngine::input_all_segments(
  self : PinyinInputEngine,
  pinyin_str : String,
) -> Array[InputCandidate] raise @core.PinyinError {
  if pinyin_str.length() == 0 {
    @core.raise_invalid_input("Please enter a pinyin string")
  }
  let all_segmentations = @segment.PinyinSegmenter::segment(pinyin_str)
  if all_segmentations.length() == 0 {
    return []
  }
  let all_results : Array[InputCandidate] = []
  for seg in all_segmentations {
    let candidates = self.input_from_segments(seg)
    for c in candidates {
      all_results.push(c)
    }
  }
  // 按得分降序排序
  all_results.sort_by(fn(a : InputCandidate, b : InputCandidate) -> Int32 {
    if a.score > b.score {
      -1
    } else if a.score < b.score {
      1
    } else {
      0
    }
  })
  // 去重（相同文本只保留得分最高的）
  let seen : Map[String, Unit] = Map([])
  let deduped : Array[InputCandidate] = []
  for c in all_results {
    if !seen.contains(c.text) {
      seen[c.text] = ()
      deduped.push(c)
    }
  }
  deduped
}

///|
/// 限制返回候选数量的便捷方法。
/// limit 小于 1 时抛 PinyinError。
pub fn PinyinInputEngine::input_with_limit(
  self : PinyinInputEngine,
  pinyin_str : String,
  limit : Int32,
) -> Array[InputCandidate] raise @core.PinyinError {
  if limit < 1 {
    @core.raise_invalid_input("Limit must be >= 1, got: " + limit.to_string())
  }
  let all = self.input(pinyin_str)
  if all.length() <= limit {
    all
  } else {
    all[:limit].to_owned()
  }
}

///|
/// 从 mutil_pinyin_dict 构建词组查找表。
/// 键为无调拼音串（空格分隔音节），值为汉字词组。
fn build_phrase_table() -> Map[String, String] {
  let table : Map[String, String] = Map([])
  for kv in @data.mutil_pinyin_dict {
    let hanzi = kv.0
    let pinyin_str = kv.1
    if pinyin_str.contains(@core.pinyin_separator) {
      let parts = pinyin_str.split(@core.pinyin_separator)
      let unmarked : Array[String] = []
      for p in parts {
        unmarked.push(@core.strip_tone(p.to_owned()))
      }
      let key = unmarked.join(" ")
      table[key] = hanzi
    }
  }
  table
}

///|
/// 模糊拼音输入：先对输入拼音进行模糊扩展，再执行 Beam Search。
/// 允许用户输入 "zongguo" 匹配到 "zhongguo" 的候选。
pub fn PinyinInputEngine::input_fuzzy(
  self : PinyinInputEngine,
  pinyin_str : String,
) -> Array[InputCandidate] raise @core.PinyinError {
  if pinyin_str.length() == 0 {
    @core.raise_invalid_input("Please enter a pinyin string")
  }
  let segments = @segment.PinyinSegmenter::segment_best(pinyin_str)
  if segments.length() == 0 {
    return []
  }
  // 对每个音节进行模糊扩展，收集所有等价音节的候选
  let all_candidates : Array[Array[String]] = []
  for seg in segments {
    let variants = @fuzzy.FuzzyPinyinHelper::fuzzy_expand(seg)
    let chars_set : Map[String, Unit] = Map([])
    for v in variants {
      let chars = try @reverse.ReversePinyinHelper::reverse_lookup(v) catch {
        _ => []
      } noraise {
        arr => arr
      }
      for ch in chars {
        if !chars_set.contains(ch) {
          chars_set[ch] = ()
        }
      }
    }
    let unique_chars = sort_chars_by_commonness(chars_set.keys().to_array())
    if unique_chars.length() == 0 {
      all_candidates.push([seg])
    } else {
      let limit = if unique_chars.length() > self.scoring_config.candidate_limit {
        unique_chars[:self.scoring_config.candidate_limit].to_owned()
      } else {
        unique_chars
      }
      all_candidates.push(limit)
    }
  }
  // Beam Search
  let beam : Array[BeamPath] = [
    { chars: [], log_prob: 0.0, last_syllable: "", rank_sum: 0, },
  ]
  let mut current_beam = beam
  for i in 0..<segments.length() {
    let syllable = segments[i]
    let candidates = all_candidates[i]
    let new_beam : Array[BeamPath] = []
    for path in current_beam {
      for c in candidates {
        let new_log_prob = if path.last_syllable.length() == 0 {
          path.log_prob + @math.ln(@lm.PinyinLM::unigram_prob(syllable))
        } else {
          path.log_prob +
          @math.ln(@lm.PinyinLM::bigram_prob(path.last_syllable, syllable))
        }
        let new_chars = path.chars.copy()
        new_chars.push(c)
        new_beam.push({
          chars: new_chars,
          log_prob: new_log_prob,
          last_syllable: syllable,
          rank_sum: path.rank_sum + char_common_rank(c),
        })
      }
    }
    new_beam.sort_by(compare_beam_path)
    let max_k = if new_beam.length() > self.beam_width {
      self.beam_width
    } else {
      new_beam.length()
    }
    current_beam = new_beam[:max_k].to_owned()
  }
  let results : Array[InputCandidate] = []
  for path in current_beam {
    let text = path.chars.join("")
    results.push({ text, score: path.log_prob, segments: segments.copy(), })
  }
  dedup_candidates(results)
}
