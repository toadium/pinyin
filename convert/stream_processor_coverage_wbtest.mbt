///|
test "stream_processor: 自定义分隔符" {
  let processor = PinyinStreamProcessor::new(separator="-")
  assert_eq(processor.feed('中'), "zhōng-zhòng")
  assert_eq(processor.feed('国'), "guó")
}

///|
test "stream_processor: 首字母无分隔符" {
  let processor = PinyinStreamProcessor::new(format=FirstLetter, separator="")
  assert_eq(processor.feed('中'), "zz")
  assert_eq(processor.feed('国'), "g")
}

///|
test "stream_processor: 非汉字后接汉字" {
  let processor = PinyinStreamProcessor::new()
  assert_eq(processor.feed('a'), "a")
  assert_eq(processor.feed('中'), "zhōng zhòng")
}

///|
test "stream_processor: 词组增量输出" {
  let processor = PinyinStreamProcessor::new()
  assert_eq(processor.feed('阿'), "ā ē")
  assert_eq(processor.feed('訇'), "ā hōng")
}

///|
test "stream_processor: 无调格式" {
  let processor = PinyinStreamProcessor::new(format=WithoutTone)
  assert_eq(processor.feed('国'), "guo")
}

///|
test "stream_processor: 空 flush 与 reset 后复用" {
  let processor = PinyinStreamProcessor::new()
  assert_eq(processor.flush(), "")
  assert_eq(processor.feed('中'), "zhōng zhòng")
  processor.reset()
  assert_eq(processor.feed('国'), "guó")
}

///|
test "stream_processor: 标点与汉字混合" {
  let processor = PinyinStreamProcessor::new()
  assert_eq(processor.feed('中'), "zhōng zhòng")
  assert_eq(processor.feed('，'), "，")
  assert_eq(processor.feed('国'), "guó")
}
