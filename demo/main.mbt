///|
/// pinyin 端到端演示：转换、消歧、分词、变调、规范化、输入法候选。
fn main {
  let text = "我是中国人"
  let pinyin = try
    @convert.PinyinHelper::convert_to_pinyin_string(text, " ")
  catch {
    _ => ""
  } noraise {
    value => value
  }
  println("1) 汉字→拼音: " + pinyin)

  let readings = try
    @disambiguate.PinyinDisambiguator::disambiguate(text)
  catch {
    _ => []
  } noraise {
    value => value
  }
  println("2) 上下文消歧: " + readings.join(" "))

  let segments = try @segment.PinyinSegmenter::segment_best("nihao") catch {
    _ => []
  } noraise {
    value => value
  }
  println("3) 拼音分词: " + segments.join(" | "))

  let sandhi = @tone.ToneSandhiHelper::apply_tone_sandhi(["nǐ", "hǎo"])
  println("4) 三声变调: " + sandhi.join(" "))

  println("5) 规范化: " + @normalize.PinyinNormalizer::normalize("ZHONG1"))
  println(
    "6) 规范化(数字调): " +
    @normalize.PinyinNormalizer::normalize_to_tone_number("zhōng"),
  )

  let engine = @input.PinyinInputEngine::new()
  let candidates = try engine.input("nihao") catch {
    _ => []
  } noraise {
    value => value
  }
  println("7) 输入法候选 (nihao):")
  for i, candidate in candidates {
    if i < 5 {
      println("   " + (i + 1).to_string() + ". " + candidate.text)
    }
  }

  let scheme = @shuangpin.ShuangpinScheme::Xiaohe
  let shuang_candidates = try engine.input_shuangpin(scheme, "nihc") catch {
    _ => []
  } noraise {
    value => value
  }
  println(
    "8) 小鹤双拼 (nihc): " +
    (if shuang_candidates.length() > 0 {
      shuang_candidates[0].text
    } else {
      "(no candidate)"
    }),
  )

  let initial_candidates = try engine.input("zg") catch {
    _ => []
  } noraise {
    value => value
  }
  println(
    "9) 简拼候选 (zg): " +
    (if initial_candidates.length() > 0 {
      initial_candidates[0].text
    } else {
      "(no candidate)"
    }),
  )

  engine.learn("你号")
  let learned = try engine.input("nihao") catch {
    _ => []
  } noraise {
    value => value
  }
  println(
    "10) 学习后首选: " +
    (if learned.length() > 0 { learned[0].text } else { "(no candidate)" }),
  )
}
