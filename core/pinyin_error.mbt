///|
/// 拼音库统一错误类型，对齐源库 pinyin4cj 的 Pinyin4cjException。
/// pub(all) suberror，跨包 raise 用 `@core.raise_invalid_input("msg")`，
/// 调用方以 `try expr catch { _ => ... }` 捕获。
pub(all) suberror PinyinError {
  InvalidInput(String)
}

///|
#warnings("-73")
/// 跨包抛错包装函数：子包用 `@core.raise_invalid_input("msg")` 代替
/// `raise @core.PinyinError::InvalidInput("msg")`，避免 [0073] 警告。
pub fn raise_invalid_input(msg : String) -> Unit raise PinyinError {
  raise PinyinError::InvalidInput(msg)
}
