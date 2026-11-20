///|
/// 取字典中的第一个读音作为无上下文基线。
fn baseline_reading(ch : String) -> String {
  match @convert.pinyin_table.get(ch) {
    Some(value) => {
      let readings = value
        .split(@core.pinyin_separator)
        .map(fn(x) { x.to_owned() })
        .to_array()
      if readings.length() > 0 {
        readings[0]
      } else {
        ch
      }
    }
    None => ch
  }
}

///|
test "disambiguate: 上下文消歧准确率对比基线" {
  let cases : Array[(String, Array[String])] = [
    ("银行", ["yín", "háng"]),
    ("行长", ["háng", "zhǎng"]),
    ("重庆", ["chóng", "qìng"]),
    ("重要", ["zhòng", "yào"]),
    ("重新", ["chóng", "xīn"]),
    ("长大", ["zhǎng", "dà"]),
    ("音乐", ["yīn", "yuè"]),
    ("快乐", ["kuài", "lè"]),
    ("处理", ["chǔ", "lǐ"]),
    ("调查", ["diào", "chá"]),
    ("调整", ["tiáo", "zhěng"]),
    ("的确", ["dí", "què"]),
    ("觉得", ["jué", "de"]),
    ("睡觉", ["shuì", "jiào"]),
    ("数学", ["shù", "xué"]),
    ("教师", ["jiào", "shī"]),
    ("传记", ["zhuàn", "jì"]),
    ("血压", ["xuè", "yā"]),
    ("人参", ["rén", "shēn"]),
    ("种子", ["zhǒng", "zi"]),
    ("种植", ["zhòng", "zhí"]),
    ("归还", ["guī", "huán"]),
    ("空调", ["kōng", "tiáo"]),
    ("着急", ["zháo", "jí"]),
    ("薄荷", ["bò", "he"]),
    ("便宜", ["pián", "yi"]),
    ("大夫", ["dài", "fū"]),
    ("背包", ["bēi", "bāo"]),
    ("兴奋", ["xīng", "fèn"]),
    ("高兴", ["gāo", "xìng"]),
    ("数量", ["shù", "liàng"]),
    ("数数", ["shǔ", "shù"]),
    ("鲜血", ["xiān", "xuè"]),
    ("薄弱", ["bó", "ruò"]),
    ("参差", ["cēn", "cī"]),
    ("调解", ["tiáo", "jiě"]),
    ("行走", ["xíng", "zǒu"]),
    ("行为", ["xíng", "wéi"]),
    ("银行行长", ["yín", "háng", "háng", "zhǎng"]),
    ("我爱重庆", ["wǒ", "ài", "chóng", "qìng"]),
    ("他很重要", ["tā", "hěn", "zhòng", "yào"]),
    ("重新开始", ["chóng", "xīn", "kāi", "shǐ"]),
    ("长大以后", ["zhǎng", "dà", "yǐ", "hòu"]),
    ("音乐老师", ["yīn", "yuè", "lǎo", "shī"]),
    ("处理问题", ["chǔ", "lǐ", "wèn", "tí"]),
    ("调查数据", ["diào", "chá", "shù", "jù"]),
    ("觉得很好", ["jué", "de", "hěn", "hǎo"]),
    ("睡觉时间", ["shuì", "jiào", "shí", "jiān"]),
    ("数学老师", ["shù", "xué", "lǎo", "shī"]),
    ("参加比赛", ["cān", "jiā", "bǐ", "sài"]),
    ("解决问题", ["jiě", "jué", "wèn", "tí"]),
    ("重复劳动", ["chóng", "fù", "láo", "dòng"]),
    ("种植树木", ["zhòng", "zhí", "shù", "mù"]),
    ("归还图书", ["guī", "huán", "tú", "shū"]),
    ("空调房间", ["kōng", "tiáo", "fáng", "jiān"]),
    ("着急回家", ["zháo", "jí", "huí", "jiā"]),
    ("薄荷糖", ["bò", "he", "táng"]),
    ("便宜衣服", ["pián", "yi", "yī", "fu"]),
    ("大夫看病", ["dài", "fū", "kàn", "bìng"]),
    ("背包旅行", ["bēi", "bāo", "lǚ", "xíng"]),
    ("兴奋不已", ["xīng", "fèn", "bù", "yǐ"]),
    ("高兴极了", ["gāo", "xìng", "jí", "le"]),
    ("数量很多", ["shù", "liàng", "hěn", "duō"]),
    ("数数孩子", ["shǔ", "shù", "hái", "zi"]),
    ("鲜血直流", ["xiān", "xuè", "zhí", "liú"]),
    ("薄弱环节", ["bó", "ruò", "huán", "jié"]),
    ("参差不齐", ["cēn", "cī", "bù", "qí"]),
    ("调解纠纷", ["tiáo", "jiě", "jiū", "fēn"]),
    ("行走困难", ["xíng", "zǒu", "kùn", "nán"]),
    ("行为规范", ["xíng", "wéi", "guī", "fàn"]),
  ]
  let mut total = 0
  let mut correct = 0
  let mut baseline_correct = 0
  for item in cases {
    let text = item.0
    let expected = item.1
    let actual = @disambiguate.PinyinDisambiguator::disambiguate(text)
    let chars = text.to_array()
    for i in 0..<expected.length() {
      total += 1
      if i < actual.length() && actual[i] == expected[i] {
        correct += 1
      }
      if i < chars.length() &&
        baseline_reading(chars[i].to_string()) == expected[i] {
        baseline_correct += 1
      }
    }
  }
  let accuracy = correct.to_double() / total.to_double()
  let baseline = baseline_correct.to_double() / total.to_double()
  println("disambiguation accuracy: " + (accuracy * 100.0).to_string() + "%")
  println("baseline accuracy: " + (baseline * 100.0).to_string() + "%")
  assert_true(accuracy >= 0.9)
  assert_true(accuracy > baseline)
}
