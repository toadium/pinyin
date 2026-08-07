# 验证报告（v3）

## 结果
FAILED

## 统计
- 通过：24
- 失败：2

## 测试执行日志
```
Warning: [0033]
       鈺攢[ D:\CodeWorkspace\forMoonbit\pinyin\data\pinyin_dict.mbt:16384:1 ]
       鈹? 16384 鈹?  "璺?: "j墨",
       鈹?鈹? 
       鈹?鈺扳攢鈹€ Warning (text_segment_excceed): Text segment is about to exceed the line limit. Consider mark `///|` above the the top-level structures to splitting it into multiple segments.
鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈺?Warning: [0029]
   鈺攢[ D:\CodeWorkspace\forMoonbit\pinyin\moon.pkg:2:3 ]
   鈹? 2 鈹?  "pinyin/pinyin/data",
   鈹?  鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€  
   鈹?            鈺扳攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ Warning (unused_package): Unused package 'pinyin/pinyin/data'
鈹€鈹€鈹€鈺?Finished. moon: ran 3 tasks, now up to date (2 warnings, 0 errors)

[pinyin/pinyin] test mutil_pinyin_dict_test.mbt:4 ("mutil_pinyin_dict_has_845_entries") failed
expect test failed at D:\CodeWorkspace\forMoonbit\pinyin\mutil_pinyin_dict_test.mbt:5:3-5:59
Diff: (- expected, + actual)
----
-845
+843
----

[pinyin/pinyin] test chinese_dict_test.mbt:4 ("chinese_dict_has_2543_entries") failed
expect test failed at D:\CodeWorkspace\forMoonbit\pinyin\chinese_dict_test.mbt:5:3-5:55
Diff: (- expected, + actual)
----
-2543
+2533
----

Total tests: 26, passed: 24, failed: 2.
```
