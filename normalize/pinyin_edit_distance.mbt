///|
/// PinyinEditDistance 命名空间类型，提供拼音编辑距离计算。
/// 基于音节级 Levenshtein 距离，支持拼写纠错和拼音搜索排序。
#warnings("-struct_never_constructed")
pub struct PinyinEditDistance {}

///|
/// 计算两个拼音串之间的音节级编辑距离。
/// 先将拼音串分词为音节，再计算音节数组之间的 Levenshtein 距离。
/// 例如 "zhongguo" 与 "zongguo" 的距离为 1（一个音节差异）。
pub fn PinyinEditDistance::distance(s1 : String, s2 : String) -> Int32 {
  let segs1 = @segment.PinyinSegmenter::segment_best(s1)
  let segs2 = @segment.PinyinSegmenter::segment_best(s2)
  PinyinEditDistance::levenshtein(segs1, segs2)
}

///|
/// 计算两个音节数组之间的 Levenshtein 距离。
fn PinyinEditDistance::levenshtein(
  arr1 : Array[String],
  arr2 : Array[String],
) -> Int32 {
  let m = arr1.length()
  let n = arr2.length()
  if m == 0 {
    return n
  }
  if n == 0 {
    return m
  }
  let dp : Array[Array[Int32]] = []
  for i in 0..<=m {
    dp.push([])
    for _ in 0..<=n {
      dp[i].push(0)
    }
  }
  for i in 0..<=m {
    dp[i][0] = i
  }
  for j in 0..<=n {
    dp[0][j] = j
  }
  for i in 1..<=m {
    for j in 1..<=n {
      let cost = if arr1[i - 1] == arr2[j - 1] { 0 } else { 1 }
      dp[i][j] = dp[i - 1][j - 1] + cost
      if dp[i - 1][j] + 1 < dp[i][j] {
        dp[i][j] = dp[i - 1][j] + 1
      }
      if dp[i][j - 1] + 1 < dp[i][j] {
        dp[i][j] = dp[i][j - 1] + 1
      }
    }
  }
  dp[m][n]
}

///|
/// 计算两个拼音串之间的音节级编辑距离，考虑模糊匹配。
/// 模糊等价的音节（如 zhong 和 zong）视为相同，距离为 0。
pub fn PinyinEditDistance::fuzzy_distance(s1 : String, s2 : String) -> Int32 {
  let segs1 = @segment.PinyinSegmenter::segment_best(s1)
  let segs2 = @segment.PinyinSegmenter::segment_best(s2)
  PinyinEditDistance::fuzzy_levenshtein(segs1, segs2)
}

///|
/// 计算两个音节数组之间的模糊 Levenshtein 距离。
fn PinyinEditDistance::fuzzy_levenshtein(
  arr1 : Array[String],
  arr2 : Array[String],
) -> Int32 {
  let m = arr1.length()
  let n = arr2.length()
  if m == 0 {
    return n
  }
  if n == 0 {
    return m
  }
  let dp : Array[Array[Int32]] = []
  for i in 0..<=m {
    dp.push([])
    for _ in 0..<=n {
      dp[i].push(0)
    }
  }
  for i in 0..<=m {
    dp[i][0] = i
  }
  for j in 0..<=n {
    dp[0][j] = j
  }
  for i in 1..<=m {
    for j in 1..<=n {
      let cost = if @fuzzy.FuzzyPinyinHelper::fuzzy_match(
          arr1[i - 1],
          arr2[j - 1],
        ) {
        0
      } else {
        1
      }
      dp[i][j] = dp[i - 1][j - 1] + cost
      if dp[i - 1][j] + 1 < dp[i][j] {
        dp[i][j] = dp[i - 1][j] + 1
      }
      if dp[i][j - 1] + 1 < dp[i][j] {
        dp[i][j] = dp[i][j - 1] + 1
      }
    }
  }
  dp[m][n]
}
