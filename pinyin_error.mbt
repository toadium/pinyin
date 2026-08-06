/// 拼音库统一错误类型，对齐源库 pinyin4cj 的 Pinyin4cjException。
/// 单变体携带错误消息字符串，后续方法以 `raise PinyinError("msg")` 抛错，
/// 调用方以 `try expr catch { PinyinError::PinyinError(msg) => ... }` 捕获。
pub(all) suberror PinyinError {
  PinyinError(String)
}