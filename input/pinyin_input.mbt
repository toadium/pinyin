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
/// 创建默认拼音输入法引擎（beam 宽度 = 10）。
pub fn PinyinInputEngine::new() -> PinyinInputEngine {
  { beam_width: 10, }
}

///|
/// 创建自定义 beam 宽度的拼音输入法引擎。
/// beam_width 越大候选越多但计算越慢，最小为 1。
pub fn PinyinInputEngine::with_beam_width(
  beam_width : Int32,
) -> PinyinInputEngine {
  { beam_width: if beam_width < 1 { 1 } else { beam_width }, }
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
/// Beam 中的候选路径。
priv struct BeamPath {
  /// 已生成的汉字序列
  chars : Array[String]
  /// 累积对数概率
  log_prob : Double
  /// 上一个音节（用于 bigram 打分）
  last_syllable : String
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
pub fn PinyinInputEngine::input_from_segments(
  self : PinyinInputEngine,
  segments : Array[String],
) -> Array[InputCandidate] {
  if segments.length() == 0 {
    return []
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
      // 无候选，用音节本身作为占位
      all_candidates.push([seg])
    } else {
      // 限制每音节候选数，避免组合爆炸
      let limit = if chars.length() > 20 {
        chars[:20].to_owned()
      } else {
        chars
      }
      all_candidates.push(limit)
    }
  }
  // Beam Search
  let beam : Array[BeamPath] = [
    { chars: [], log_prob: 0.0, last_syllable: "", },
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
        })
      }
    }
    // 裁剪：保留 top-k
    new_beam.sort_by(fn(a : BeamPath, b : BeamPath) -> Int32 {
      if a.log_prob > b.log_prob {
        -1
      } else if a.log_prob < b.log_prob {
        1
      } else {
        0
      }
    })
    let max_k = if new_beam.length() > self.beam_width {
      self.beam_width
    } else {
      new_beam.length()
    }
    current_beam = new_beam[:max_k].to_owned()
  }
  // 转换为 InputCandidate
  let results : Array[InputCandidate] = []
  for path in current_beam {
    let text = path.chars.join("")
    results.push({ text, score: path.log_prob, segments: segments.copy(), })
  }
  results
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
pub fn PinyinInputEngine::input_with_limit(
  self : PinyinInputEngine,
  pinyin_str : String,
  limit : Int32,
) -> Array[InputCandidate] raise @core.PinyinError {
  let all = self.input(pinyin_str)
  if all.length() <= limit {
    all
  } else {
    all[:limit].to_owned()
  }
}
