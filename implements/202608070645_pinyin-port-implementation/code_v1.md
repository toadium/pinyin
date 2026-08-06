# 实现报告（v1）

## 概述

按详细设计 v1 创建 pinyin4cj → MoonBit 移植的模块空骨架：模块根元数据 `moon.mod`、主包配置 `moon.pkg`、数据子包配置 `data/moon.pkg`、占位 `README.mbt.md`。本任务不涉及任何 `.mbt` 源文件、类型定义、方法签名或算法实现，仅产出配置文件与占位 README，为后续任务提供可编译的工具链与包边界基础。

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|---------|------|
| 新建 | moon.mod | 模块根元数据：name=`pinyin/pinyin`，version=`0.1.0`，license=MIT，零外部依赖，无 options/supported_targets |
| 新建 | moon.pkg | 主包配置：单向 import `pinyin/pinyin/data`，库包（不设置 is-main） |
| 新建 | data/moon.pkg | 数据子包配置：纯数据包，零 import，仅含注释说明包职责 |
| 新建 | README.mbt.md | 占位 README：一级标题 + 一行简介，无 `mbt check` 代码块 |
| 新建 | data/ | 数据子包目录（由创建 `data/moon.pkg` 隐式建立） |

## 编译验证

执行命令：`moon check`（工作目录：`D:\CodeWorkspace\forMoonbit\pinyin`）

结果：**成功**（exit code 0，1 warnings, 0 errors）

输出：
```
Warning: [0029]
   ╭─[ D:\CodeWorkspace\forMoonbit\pinyin\moon.pkg:2:3 ]
   │
 2 │   "pinyin/pinyin/data",
   │   ──────────┬─────────
   │             ╰─────────── Warning (unused_package): Unused package 'pinyin/pinyin/data'
───╯
Finished. moon: ran 1 task, now up to date (1 warnings, 0 errors)
```

### 警告治理（针对 `unused_package`）

- (a) 警告类型与消息文本：`Warning (0029) (unused_package): Unused package 'pinyin/pinyin/data'`
- (b) 根因：主包零源文件 → import 的数据子包未被引用
- (c) 处置决策：接受为预期警告，不阻断本任务验收（与设计 §E 完全一致）
- (d) 消除条件：后续任务添加使用 `@data.xxx` 的源文件（如 `pinyin_helper.mbt`）后警告自动消除；若后续任务完成后警告仍存在则视为缺陷
- (e) 记录方式：本报告编译验证小节记录警告原文与处置决策

## 设计偏差说明

无偏差。四个文件内容均按设计 §A-§D "精确到字节" 契约照抄，字段顺序、import 路径、注释文本、README 标题与简介均与设计一致。`moon check` 产生的 `unused_package` 警告与设计 §E 预期输出完全一致。