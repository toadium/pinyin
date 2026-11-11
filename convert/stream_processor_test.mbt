///|
test "stream_processor: 逐字符输入汉字" {
  let processor = @convert.PinyinStreamProcessor::new()
  let r1 = processor.feed('你')
  assert_eq(r1, "nǐ")
  let r2 = processor.feed('好')
  assert_true(r2.contains("hǎo"))
}

///|
test "stream_processor: 非汉字字符" {
  let processor = @convert.PinyinStreamProcessor::new()
  let r1 = processor.feed('a')
  assert_eq(r1, "a")
  let r2 = processor.feed('b')
  assert_eq(r2, "b")
}

///|
test "stream_processor: flush 输出剩余缓冲" {
  let processor = @convert.PinyinStreamProcessor::new()
  let _ = processor.feed('中')
  let flushed = processor.flush()
  assert_eq(flushed, "")
}

///|
test "stream_processor: reset 清空缓冲" {
  let processor = @convert.PinyinStreamProcessor::new()
  let _ = processor.feed('中')
  processor.reset()
  let flushed = processor.flush()
  assert_eq(flushed, "")
}

///|
test "stream_processor: 首字母格式" {
  let processor = @convert.PinyinStreamProcessor::new(format=FirstLetter)
  let r1 = processor.feed('国')
  assert_eq(r1, "g")
}

///|
test "stream_processor: 数字调格式" {
  let processor = @convert.PinyinStreamProcessor::new(format=WithToneNumber)
  let r1 = processor.feed('国')
  assert_eq(r1, "guo2")
}

///|
test "stream_processor: 完整句子流式处理" {
  let processor = @convert.PinyinStreamProcessor::new()
  let r1 = processor.feed('中')
  assert_true(r1.contains("zhōng"))
  let r2 = processor.feed('国')
  assert_true(r2.contains("guó"))
  let r3 = processor.flush()
  assert_eq(r3, "")
}
