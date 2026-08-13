///|
/// 辅助函数：抛出携带指定消息的 PinyinError，用于测试错误捕获行为。
fn raise_pinyin_error(msg : String) -> Unit raise @pinyin.PinyinError {
  raise @pinyin.PinyinError::PinyinError(msg)
}

///|
/// 验证 PinyinError 可通过 raise 抛错并被 try...catch 捕获，
/// 捕获后可提取携带的错误消息字符串，对齐源库 Pinyin4cjException 行为。
test "pinyin_error_carries_message" {
  try raise_pinyin_error("test message") catch {
    @pinyin.PinyinError::PinyinError(msg) =>
      debug_inspect(msg, content=(
        #|"test message"
      ))
  } noraise {
    _ => fail("expected PinyinError to be raised")
  }
}

///|
/// 边界条件：空字符串作为错误消息，验证 PinyinError 可承载空消息。
test "pinyin_error_with_empty_message" {
  try raise_pinyin_error("") catch {
    @pinyin.PinyinError::PinyinError(msg) => debug_inspect(msg, content=(
      #|""
    ))
  } noraise {
    _ => fail("expected PinyinError to be raised")
  }
}

///|
/// 状态交互：不同消息产生可区分的错误值，
/// 验证 PinyinError 忠实保留构造时传入的消息载荷。
test "pinyin_error_preserves_distinct_messages" {
  try raise_pinyin_error("error one") catch {
    @pinyin.PinyinError::PinyinError(msg1) =>
      try raise_pinyin_error("error two") catch {
        @pinyin.PinyinError::PinyinError(msg2) => {
          assert_true(msg1 != msg2)
          debug_inspect(msg1, content=(
            #|"error one"
          ))
          debug_inspect(msg2, content=(
            #|"error two"
          ))
        }
      } noraise {
        _ => fail("expected second PinyinError to be raised")
      }
  } noraise {
    _ => fail("expected first PinyinError to be raised")
  }
}
