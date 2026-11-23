///|
test "disambiguate: 常用多音词" {
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("银行"), [
    "yín", "háng",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("重庆"), [
    "chóng", "qìng",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("重要"), [
    "zhòng", "yào",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("长大"), [
    "zhǎng", "dà",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("音乐"), [
    "yīn", "yuè",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("快乐"), [
    "kuài", "lè",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("处理"), [
    "chǔ", "lǐ",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("调查"), [
    "diào", "chá",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("的确"), [
    "dí", "què",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("觉得"), [
    "jué", "de",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("睡觉"), [
    "shuì", "jiào",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("数学"), [
    "shù", "xué",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("教师"), [
    "jiào", "shī",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("传记"), [
    "zhuàn", "jì",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("血压"), [
    "xuè", "yā",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("人参"), [
    "rén", "shēn",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("种子"), [
    "zhǒng", "zi",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("种植"), [
    "zhòng", "zhí",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("归还"), [
    "guī", "huán",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("空调"), [
    "kōng", "tiáo",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("着急"), [
    "zháo", "jí",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("薄荷"), [
    "bò", "he",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("还钱"), [
    "huán", "qián",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("还书"), [
    "huán", "shū",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("还债"), [
    "huán", "zhài",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("还是"), [
    "hái", "shì",
  ])
  assert_eq(
    @disambiguate.PinyinDisambiguator::disambiguate("我明天还钱"),
    ["wǒ", "míng", "tiān", "huán", "qián"],
  )
  // pypinyin 大词库：整串命中与句内最大匹配
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("虚与委蛇"), [
    "xū", "yǔ", "wēi", "yí",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("螳臂当车"), [
    "táng", "bì", "dāng", "chē",
  ])
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("暴殄天物"), [
    "bào", "tiǎn", "tiān", "wù",
  ])
  assert_eq(
    @disambiguate.PinyinDisambiguator::disambiguate("他虚与委蛇"),
    ["tā", "xū", "yǔ", "wēi", "yí"],
  )
  // 「一/不」保持原调，变调交由 tone 包
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("一不小心"), [
    "yī", "bù", "xiǎo", "xīn",
  ])
  // 项目常用词表优先级高于大词库（大词库对「还款」误读 hái）
  assert_eq(@disambiguate.PinyinDisambiguator::disambiguate("还款"), [
    "huán", "kuǎn",
  ])
}
