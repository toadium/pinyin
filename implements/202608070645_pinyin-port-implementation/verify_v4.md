# 验证报告（v4）

## 结果
PASSED

## 统计
- 通过：26
- 失败：0

## 测试执行日志

### moon check

```
Warning: [0033]
       ╭─[ D:\CodeWorkspace\forMoonbit\pinyin\data\pinyin_dict.mbt:16384:1 ]
       │ 16384 │  "璺?: "j墨",
       │      │
       │      ╰─ Warning (text_segment_excceed): Text segment is about to exceed the line limit. Consider mark `///|` above the the top-level structures to splitting it into multiple segments.
─── Warning: [0029]
   │[ D:\CodeWorkspace\forMoonbit\pinyin\moon.pkg:2:3 ]
   │ 2 │  "pinyin/pinyin/data",
   │      ───────────────────────
   │            ╰─ Warning (unused_package): Unused package 'pinyin/pinyin/data'
─── Finished. moon: ran 3 tasks, now up to date (2 warnings, 0 errors)
```

### moon test

```
Total tests: 26, passed: 26, failed: 0.
```