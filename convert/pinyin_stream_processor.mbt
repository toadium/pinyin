///|
/// PinyinStreamProcessor 流式拼音处理器。
/// 支持逐字符输入汉字，实时输出拼音，适用于输入法等实时场景。
/// 内部维护已输出和待处理两部分，自动处理词组匹配。
pub struct PinyinStreamProcessor {
  pending : StringBuilder
  mut last_output : String
  format : @core.PinyinFormat
  separator : String
}

///|
/// 创建流式拼音处理器。
/// format 默认 WithToneMark，separator 默认空格。
pub fn PinyinStreamProcessor::new(
  format~ : @core.PinyinFormat = WithToneMark,
  separator~ : String = " ",
) -> PinyinStreamProcessor {
  { pending: StringBuilder(), last_output: "", format, separator, }
}

///|
/// 输入一个字符，返回增量拼音输出。
/// 每次只返回与上次相比新增的拼音片段。
pub fn PinyinStreamProcessor::feed(
  self : PinyinStreamProcessor,
  c : Char,
) -> String {
  self.pending.write_char(c)
  let full_output = self.process_pending()
  let delta = self.compute_delta(full_output)
  self.last_output = full_output
  delta
}

///|
/// 刷新缓冲区，输出剩余未处理的字符。
pub fn PinyinStreamProcessor::flush(self : PinyinStreamProcessor) -> String {
  let full_output = self.process_pending()
  let delta = self.compute_delta(full_output)
  self.last_output = full_output
  self.pending.reset()
  delta
}

///|
/// 重置处理器，清空缓冲区。
pub fn PinyinStreamProcessor::reset(self : PinyinStreamProcessor) -> Unit {
  self.pending.reset()
  self.last_output = ""
}

///|
fn PinyinStreamProcessor::process_pending(
  self : PinyinStreamProcessor,
) -> String {
  let current = self.pending.to_string()
  if current.length() == 0 {
    return ""
  }
  let chars = current.to_array()
  let result = StringBuilder()
  let mut i = 0
  while i < chars.length() {
    let remaining = String::from_array(chars[i:])
    let words = PinyinHelper::get_words(remaining)
    if words.length() > 0 {
      let word = words[0]
      match mutil_pinyin_table.get(word) {
        Some(v) => {
          let pinyin_array = @core.format_pinyin(v, self.format)
          for p in pinyin_array {
            if self.format is FirstLetter && p.length() > 0 {
              result.write_char(p[0].unsafe_to_char())
            } else {
              result.write_string(p)
            }
            result.write_string(self.separator)
          }
        }
        None => ()
      }
      i += word.length()
    } else {
      let ch = chars[i]
      if ChineseHelper::is_chinese(ch) || ch == @core.chinese_ling {
        match pinyin_table.get(ch.to_string()) {
          Some(v) => {
            let pinyin_array = @core.format_pinyin(v, self.format)
            for p in pinyin_array {
              if self.format is FirstLetter && p.length() > 0 {
                result.write_char(p[0].unsafe_to_char())
              } else {
                result.write_string(p)
              }
              result.write_string(self.separator)
            }
          }
          None => {
            result.write_char(ch)
            result.write_string(self.separator)
          }
        }
      } else {
        result.write_char(ch)
        if i + 1 < chars.length() && ChineseHelper::is_chinese(chars[i + 1]) {
          result.write_string(self.separator)
        }
      }
      i += 1
    }
  }
  let result_str = result.to_string()
  if self.separator.length() > 0 &&
    result_str.length() >= self.separator.length() &&
    result_str[result_str.length() - self.separator.length():] ==
    self.separator[:] {
    result_str[:result_str.length() - self.separator.length()].to_owned()
  } else {
    result_str
  }
}

///|
fn PinyinStreamProcessor::compute_delta(
  self : PinyinStreamProcessor,
  full_output : String,
) -> String {
  if full_output.length() <= self.last_output.length() {
    return ""
  }
  let prefix = self.last_output
  if full_output[:prefix.length()] == prefix[:] {
    let delta = full_output[prefix.length():].to_owned()
    if delta.length() > 0 &&
      self.separator.length() > 0 &&
      delta[:self.separator.length()] == self.separator[:] {
      delta[self.separator.length():].to_owned()
    } else {
      delta
    }
  } else {
    full_output
  }
}
