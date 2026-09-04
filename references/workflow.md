# Project Evolution Workflow

## 1. 最小闭环

```text
读取项目、页面和已落盘任务
→ 自动形成项目画像
→ 自动区分活动/待执行/最近完成任务
→ 自动提取目的候选、当前需求和固定流程
→ 建立业务功能地图
→ 自动生成研究计划、Opportunity、Hypothesis 和首轮报告草稿
→ 选择一个主焦点
→ 找到一个差距
→ 研究适用参考
→ 建立改进假设和基线
→ 报告并停止
→ 下一次读取用户决定和项目变化
→ 前后验证
→ 学习或撤销
```

## 2. 项目画像与功能地图

`ProjectProfile` 至少记录：项目类型、语言、框架/建站工具、运行环境、部署方式、服务器、数据库、能力清单和适配器状态。每项允许 `unknown`、`not_applicable` 或 `not_verified`。

`FeatureMap` 的每个功能记录：`featureId`、名称、服务的用户任务、是否存在、可用性、易用性、成熟度、证据、成熟参考、已知缺口和下一次复查时间。优先从页面入口、路由、任务记录和数据结构提取业务功能；目录名只能作为补充线索。可用、好用、成熟必须分开记录。

项目已有表单和已落盘任务是正式上下文来源。每次需求不同不代表流程不同：Skill 应读取本轮需求，复用固定流程，只把当前需求值作为本轮变量。任务必须拆分为 `activeJobId`、`pendingJobId` 和 `latestCompletedJobId`，不能用最近完成任务冒充当前任务。浏览器中尚未提交、项目文件中没有落盘的内容不能臆测；若调用方能提供显式浏览器快照，可作为 `browser_snapshot` 来源读取。

## 3. 用户自然语言映射

只把用户话语映射为事件，不把模糊话语当成已执行：

解析脚本必须保留原始文本、解析时间、匹配规则、置信度和 `transitionAllowed`。`transitionAllowed=false` 时只记录事件，不改变持久化状态。缺少复查日期的“暂缓”不得进入正式 `deferred` 记录；缺少执行范围的“改了一部分”不得开始局部验证；“改后有效”和“升级通用规则”都必须等待证据，不能凭一句话直接结论。

| 用户表达 | 记录事件 | 状态结果 |
|---|---|---|
| “看到了/我看过了” | `report_seen` | 保持 `awaiting-user-decision` |
| “先不做/以后再说” | `defer` | `deferred`，必须有复查时间 |
| “不适合/不要这个” | `reject` | `rejected`，停止该建议监控 |
| “我改好了/已经处理” | `claim_executed` | `change-candidate-detected`，等待证据 |
| “我只改了一部分” | `claim_partial_execution` | 只对 `executedScope` 验证，其余继续等待 |
| “需要更多依据” | `request_more_evidence` | `awaiting-more-evidence` |
| “确认问题存在” | `confirm_problem_exists` | 不批准执行，不升级规则 |
| “值得试试” | `confirm_trial_worthwhile` | 不代表已执行或有效 |
| “改后确实有效” | `confirm_change_effective` | 进入规则评估，不自动升级 |
| “以后作为通用规则” | `approve_rule_promotion` | 仅在证据门槛已满足时升级 |

无法可靠匹配时记录 `ambiguous_user_input`，报告中要求用户选择，不自行猜。

## 4. 状态机

持久化状态只使用以下值：

```text
discovered → reported → awaiting-user-decision
awaiting-user-decision → approved-awaiting-execution | deferred | rejected | awaiting-more-evidence
approved-awaiting-execution → change-candidate-detected → verifying
verifying → supported | failed | inconclusive
deferred → awaiting-user-decision（到期后只复查，不自动批准）
rejected → reopened（用户重新提出或有重大新证据）
failed → reopened
```

同一个 `runId` 重试必须幂等；每完成一个状态写 checkpoint；报告、台账或 Schema 写入失败时停止并报告 `partial-write`。

静态适配器只产生 L0 静态证据，输出 `adapterStatus=partial`，并保存扫描时间、扫描范围、排除目录、命中文件、扫描版本和限制说明。它不能把目录存在性写成“功能可用”或“用户体验通过”。

## 5. 体验验收

任务由项目实际能力动态生成。没有登录就不测试登录；没有写入隔离环境就跳过写入任务并标记 `not_verified`。真实任务记录：任务目标、参与者类型、首次/熟练身份、步骤、耗时、错误、卡住、误解、绕路、放弃、是否成功和 1-5 主观评分。多个参与者冲突时保留原始结果，结论标记 `conflicting` 或 `inconclusive`，不取平均掩盖问题。

## 6. 验证与学习

多指标按预先声明的优先级综合：关键安全/数据完整性失败即 `failed`；核心任务指标全部达到通过条件且无关键副作用才 `supported`；指标冲突、样本不足或环境不一致为 `inconclusive`。

规则升级需要区分四类人工确认，并满足对应证据门槛；单次“问题存在”或“值得尝试”不得升级为通用规则。
