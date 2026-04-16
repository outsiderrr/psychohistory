# 群体角色画像生成流程（phase-based methodology v1.1）

> **适用对象：** 没有单一决策中心的群体——选民群体、市场参与者、社会运动、人口群体等。
> **不适用于：** 个人（用 prompt-01）、有决策中心的组织（用 prompt-02）。
> **判断标准：** 如果你无法指出"谁来拍板"，它就是群体。
> **版本：** v1.1 — phase-based，包含 v1.1 新增的 `observable_state` 识别阶段。

---

## 方法论基础

群体卡和个人 / 组织卡的根本差异：**群体没有"心智"可蒸馏，只有利益分布和情绪反应函数**。

因此群体方法论的核心是**校准**（calibration），不是蒸馏：
- 不问"他们怎么想" → 问"什么样的冲击会让他们改变多少、多快"
- 所有 `sensitivity_map` 条目必须有**历史先例**校准
- 所有 `observable_state` 条目必须有可测量的指标和**有结构意义的**阈值

**5 条贯穿所有 Phase 的设计原则**（详见 `character-toolkit/README.md` §方法论原则）：

1. **两阶段最少**
2. **references.md 是主产物**
3. **证据强度分级**
4. **显式认知边界**（群体卡特别是内部异质性声明）
5. **历史先例优先**

## 使用方式

- **多阶段执行**（Claude Code）：每个 Phase 可让用户审阅
- **单次对话执行**：按顺序完成所有 Phase，不可跳步

---

# 提示词正文

请为下述群体生成一张心理史学群体角色画像。

**目标群体：** 【填写，例如：MAGA 选民 / 全球原油市场参与者 / 伊朗城市中产阶级】
**关联实体 agent：** 【填写这个群体会影响哪个实体 agent 的决策，例如 trump / iran-government】
**场景背景：** 【填写时间窗口和相关事件】

---

## Phase 0 — 前置确认

- 目标群体名称
- target_agent 的 agent_id
- 场景时间窗口
- 创建 `references.md` 文件

**Checkpoint 0**：输入完整，`references.md` 已创建。

---

## Phase 1 — 边界定义

群体建模的第一步是说清楚"这个群体是什么人"。边界模糊的群体无法建模。

### 1.1 准入标准
- 这个群体的定义是什么？（年龄、阶层、地域、职业、文化背景、政治立场）
- 准入是二元的还是程度性的？
- 边界可检验性：外部观察者能判断某人是否属于这个群体吗？

### 1.2 规模估计
- 绝对规模（人数）+ 数据来源
- 相对规模（占相关总体的比例）

### 1.3 内部异质性
- 群体内部是否有明显的子群？
- 子群的大致比例或重要程度
- 子群之间在核心议题上是否会分裂？

### 1.4 时效稳定性
- 在建模时间窗口内，群体的边界是否稳定？
- 人员流入/流出的速率如何？

**Checkpoint 1**：边界定义写入 `references.md §1 Group Boundary`。

---

## Phase 2 — 利益结构

群体没有 mental model，但有**利益排序**。利益排序不是意识形态，是"当被迫选择时真正会选哪个"。

### 2.1 核心利益识别（3-5 个）
- 这个群体最关心的议题有哪些？
- 每个议题的 driver 类型：`economic` / `ideological` / `security` / `cultural` / `historical`

### 2.2 优先级排序
- **排序依据必须是历史行为**，不是自我陈述
- 列出历史冲突案例：当议题 A 和议题 B 冲突时，这个群体选了哪个？
- 至少引用 2-3 个历史冲突案例

### 2.3 内部张力
- 不同利益之间是否存在结构性冲突？
- 例：MAGA 基本盘的"支持对外强硬"与"反对通胀压力"之间的张力

**Checkpoint 2**：利益结构 + 支撑案例写入 `references.md §2 Interest Structure`。

---

## Phase 3 — 当前态度测量

**关键原则：必须基于数据，不是推断**。

### 3.1 数据调研
- 最新民调（给出具体来源和日期）
- 市场行为数据（经济类群体）
- 投票行为（选民群体）
- 抗议 / 社会运动活动频次
- 社交媒体情绪数据（注意样本偏差）

### 3.2 立场判断
- 总体立场：`support` / `oppose` / `neutral` / `divided`
- 强度：`strong` / `medium` / `weak` / `fragile`
- 立场的分散度（如果子群立场不同，显式记录）

### 3.3 近期变化
- 过去 3-6 个月有无明显转向？
- 如有，触发事件是什么？

### 3.4 数据可靠性声明
- 数据来源的偏差（民调方法、样本偏差、"大声少数派"效应）
- `strength` 评级：基于数据量和质量

**Checkpoint 3**：当前态度 + 数据来源 + 可靠性声明写入 `references.md §3 Current Disposition`。

---

## Phase 4 — 敏感度校准（核心阶段，最难）

这是整份卡最容易出错的地方。**泛泛而谈的"他们会非常在意"没有任何价值**。必须给出可校准的具体值。

### 4.1 列出触发事件类型
该群体会被哪些类型的事件触动？至少 3-5 类。

### 4.2 对每类事件做历史校准

每个 `sensitivity_map` 条目必须包含：
- `event_type`：具体的事件类别
- **历史先例（至少 1 个）**：历史上类似冲击作用于类似群体的案例
  - 当时的背景
  - 冲击的具体形态
  - 群体态度变化的幅度（给出具体百分比或行为指标）
  - 变化的时间延迟
- `expected_shift`：基于先例推断当前场景的变化
- `time_lag`：`immediate` / `days` / `weeks` / `months`
- `strength`：
  - `high`：有 ≥2 个结构相似的历史先例
  - `medium`：只有 1 个先例，或先例结构相似度中等
  - `low`：无先例，纯结构推测（允许但必须标出）

### 4.3 反例检查
- 是否有"本以为会触发反应但实际没有"的历史案例？
- 这些反例说明敏感度可能被高估，记录在 references.md 的"预期失效先例"段

**Checkpoint 4**：敏感度映射 + 每个条目的先例校准写入 `references.md §4 Sensitivity Calibration`。

---

## Phase 5 — 影响路径追溯

群体只有在能影响到实体 agent 时才有建模价值。这一步说清楚影响是怎么传导的。

### 5.1 传导机制
- 通过什么渠道？`polls` / `votes` / `market_prices` / `street_protests` / `media_pressure` / `lobbying` / `other`
- 每条渠道的具体机制（例："polls → Trump 的 Scorecard Test heuristic → 决策重新评估"）

### 5.2 时间延迟
- 从群体态度变化到实体感受到压力的延迟是多少？
- 这个延迟是否可以被缩短（例如通过媒体放大）？

### 5.3 历史路径验证
- 历史上这条传导路径是否真的起过作用？至少 1 个先例

### 5.4 断链条件
- 什么情况下这条传导路径会失效？
- 例：如果 Trump 决定"忽略民调"，则 polls → decision 这条链断裂

**Checkpoint 5**：影响路径写入 `references.md §5 Influence Pathway`。

---

## Phase 6 — Observable State 识别（v1.1 新增，本 prompt 的核心扩展）

群体的某些状态是**可测量的宏观指标**（民调平均、市场价格、情绪指数、投票意向）。当这些状态跨越战略相关阈值时，状态变化本身应当成为 `possibility_tree` 上的一等 Event 节点，而不是藏在实体 agent 的决策函数里。

这一步把群体从"实体 agent 决策函数内部的变量"升级为"可以独立生成树上事件节点的因果源"。

### 6.1 列出可观测指标

每个指标需要：
- `state_id`：唯一标识符，如 `maga-approval-rating`
- `description`：是什么，测什么
- `measurement_method`：怎么测（例："7-day rolling average of major polls"）
- `current_value`：当前值 + 来源日期

### 6.2 阈值识别（关键）

对每个指标列出 `thresholds_of_interest`。每个阈值的核心问题是："**跨越这个数值会触发战略相关的后果吗？**"

每个阈值需要：
- `threshold`：具体数值或区间（例："below 50%"）
- `strategic_implication`：跨越会触发什么？通常指向某个实体 agent 的 concession_trigger、mental model 状态切换、或 Phase 5 中的某条传导路径

**阈值不是随便选的**。至少满足下面一条才有资格进入 JSON：
- **有历史先例**：某次类似指标跨越时确实引发了战略性后果
- **或**：实体 agent 的 concession_trigger 明确引用了这个阈值（例：`trump.ct-04: "base erodes — MAGA approval drops below comfort threshold"`，"below 50%" 是对这条 trigger 的具体化）

如果一个阈值只是"整数值感觉重要"（如 50% 心理关口），但没有上面两个结构性来源之一，**它不应进 JSON**。

### 6.3 promotable_to_event 判断

对每个 observable_state 条目判断 `promotable_to_event`：
- `true`：这个指标的阈值跨越本身可以作为树上的 Event 节点（engine 阶段将实际执行这个提升）
- `false`：这个指标只是内部参数，不应作为一等 Event

**判断标准**：如果阈值跨越能改变**多个**实体 agent 的决策计算，则 `true`；如果只影响一个 agent 的内部状态，则 `false`（藏在那个 agent 的 concession_trigger 里就够了）。

**Checkpoint 6**：观测状态写入 `references.md §6 Observable State`，每个指标有 measurement_method、current_value、thresholds_of_interest、promotable_to_event 判断及依据。

---

## Phase 7 — 诚实边界与验证

### 7.1 必需的 honesty_boundaries

群体卡的 `honesty_boundaries` **必须包含**：
- **内部异质性声明**：例 "This profile reflects mean disposition; sub-group X (~20%) diverges on issue Y"
- **数据时效声明**：民调和市场数据都会过期
- **尾部效应声明**："Mean values mask tail behavior; extreme events can come from small sub-populations"
- **传导链失效声明**：`influence_pathway` 在什么情况下会失效

### 7.2 自检清单

- [ ] **无** `mental_models` 或 `decision_heuristics` 字段（群体卡不应有这些）
- [ ] `core_interests` 的排序有历史案例支撑
- [ ] `current_disposition` 有数据来源和时效声明
- [ ] `sensitivity_map` 每条有历史先例（或明确标 `strength: low`）
- [ ] `influence_pathway` 指向具体的 `target_agent`
- [ ] `observable_state` 至少 1 个条目，每个条目的 `thresholds_of_interest` 有结构性依据（不是随意选的心理关口）
- [ ] `honesty_boundaries` 包含**内部异质性**声明
- [ ] JSON 通过 character-schema v1.1 的 `collective` 分支校验
- [ ] 日期字段完整 `YYYY-MM-DD`
- [ ] 所有文本使用英文

---

## Phase 8 — JSON 结构化与产出

### JSON 结构（character-schema v1.1 collective 分支）

```json
{
  "card_version": "1.0",
  "card_type": "collective",
  "agent_id": "小写连字符格式，如 maga-base",
  "name": "群体名称（英文）",
  "description": "一句话描述这个群体是谁（英文）",
  "affiliation": "所属国家或领域，如 us-domestic 或 global-energy-market",

  "source": {
    "type": "system-derived",
    "created_at": "YYYY-MM-DD",
    "data_cutoff": "YYYY-MM-DD"
  },

  "composition": {
    "core_demographics": "核心人口特征描述（英文）",
    "estimated_size": "规模估计",
    "internal_segments": [
      {
        "name": "子群体名称",
        "description": "子群体特点",
        "share": "整体中的大致比例"
      }
    ]
  },

  "core_interests": [
    {
      "interest": "利益议题名称（英文）",
      "priority": 1,
      "description": "为什么这个议题对他们重要（英文，≥20 字符）",
      "driver": "one of: economic / ideological / security / cultural / historical",
      "supporting_cases": "references.md §2 中支撑这个优先级的案例编号",
      "strength": "high / medium / low"
    }
  ],

  "current_disposition": {
    "issue": "当前最相关的具体议题",
    "stance": "one of: support / oppose / neutral / divided",
    "intensity": "one of: strong / medium / weak / fragile",
    "data_source": "民调 / 市场数据 / 其他来源 + 采集日期",
    "recent_shift": "最近有无明显变化；无则写 'No significant recent shift'",
    "internal_tension": "群体内部在这个议题上的张力",
    "strength": "high / medium / low"
  },

  "sensitivity_map": [
    {
      "event_type": "什么类型的事件（英文）",
      "sensitivity": "one of: extreme / high / medium / low / negligible",
      "expected_shift": "预期的倾向变化方向和幅度（英文）",
      "time_lag": "immediate / days / weeks / months",
      "historical_precedent": "引用 references.md §4 中的先例案例编号或描述",
      "strength": "high / medium / low"
    }
  ],

  "influence_pathway": {
    "target_agent": "被影响的实体角色的 agent_id",
    "mechanism": "传导机制描述（英文）",
    "channel": "one of: polls / votes / market_prices / street_protests / media_pressure / lobbying / other",
    "time_lag": "从群体态度变化到决策者感受到压力的延迟",
    "historical_verification": "references.md §5 中验证这条路径起过作用的案例",
    "breakpoints": ["什么情况下这条路径会失效"]
  },

  "observable_state": [
    {
      "state_id": "maga-approval-rating",
      "description": "MAGA base approval rating for Trump (rolling polling average)",
      "measurement_method": "7-day rolling average of major polls",
      "current_value": "approx 58% approve",
      "thresholds_of_interest": [
        {
          "threshold": "below 50%",
          "strategic_implication": "Trump's concession_trigger ct-04 activates; retreat threshold on Iran confrontation drops significantly",
          "justification": "trump card ct-04 explicitly references this threshold"
        }
      ],
      "promotable_to_event": true
    }
  ],

  "historical_behavior": [
    {
      "event": "历史上什么事件曾大幅改变这个群体的态度",
      "year": "YYYY",
      "shift": "态度发生了什么变化",
      "mechanism": "变化通过什么机制发生"
    }
  ],

  "honesty_boundaries": [
    "(REQUIRED) Internal heterogeneity disclaimer",
    "Data staleness disclaimer",
    "Tail-behavior disclaimer",
    "Influence pathway breakpoint disclaimer"
  ]
}
```

### 产出文件（两份）

1. **`skill/characters/psychohistory/[agent_id].references.md`** — 主产物
2. **`skill/characters/psychohistory/[agent_id].json`** — 压缩索引

不要输出中间解释。按 Phase 顺序执行到产出两份文件为止。

---

## Appendix: Research Hand-off Template

This template is used by `character-toolkit/SKILL.md` during the **Research Hand-off protocol** to collect raw data for **Phases 1-6** of the collective card generation flow. Output section numbering (**§0-§7**) matches the Phase Checkpoint structure for **direct 1:1 integration** into `references.md`.

### Placeholders

- `{TARGET_NAME}` — the collective (e.g., "MAGA base", "Global oil market participants")
- `{TARGET_AGENT_ID}` — the entity agent this collective affects (e.g., "trump")
- `{TIME_WINDOW_START}` / `{TIME_WINDOW_END}`
- `{SCENARIO_CONTEXT}`

### Template

```
You are researching {TARGET_NAME} for a structured collective agent profile in a Psychohistory scenario. This is a group without a single decision-maker, so you are looking for interest distribution, disposition data, and sensitivity to events — NOT unified cognition.

Use your search capability to find: polling data, demographic studies, market behavior data (if applicable), academic research on the group, and historical events that have shifted this group's attitudes.

**Time focus**: {TIME_WINDOW_START} through {TIME_WINDOW_END}.
**Target entity affected**: {TARGET_AGENT_ID}
**Scenario context**: {SCENARIO_CONTEXT}

Return your findings in the following EXACT markdown format.

## §0 Source Materials
Ranked list, prioritizing polling data, demographic studies, academic research, market data.

## §1 Group Boundary and Composition
- **Core demographics**: age, class, geography, occupation, culture
- **Estimated size**: with data source
- **Internal segments** (2-5): name, description, share of total
- **Boundary stability**: is group membership stable over the modeling time window?

## §2 Interest Structure (3-5, ranked by priority)
For each:
- **Interest**
- **Priority** (1 = highest)
- **Description** (why it matters, ≥20 chars)
- **Driver type**: economic / ideological / security / cultural / historical
- **Supporting cases**: historical instances where this group prioritized this interest over competing ones
- **Strength**: high / medium / low

## §3 Current Disposition
- **Most relevant issue** in the scenario
- **Stance**: support / oppose / neutral / divided
- **Intensity**: strong / medium / weak / fragile
- **Data source**: specific polls, market behavior, voting records, etc., with dates
- **Recent shift** (past 3-6 months): change direction + trigger, or "no significant recent shift"
- **Internal tension**: any split between sub-segments on this issue

## §4 Sensitivity Map (3-5 event types)
For each:
- **Event type**
- **Sensitivity**: extreme / high / medium / low / negligible
- **Expected shift**: magnitude and direction
- **Time lag**: immediate / days / weeks / months
- **Historical precedent**: 1-2 past cases where a similar shock hit a similar group, with observed shift magnitude
- **Strength**: high / medium / low

## §5 Influence Pathway
- **Target entity**: {TARGET_AGENT_ID}
- **Transmission mechanism**: e.g., "polls → Trump's Scorecard Test heuristic"
- **Channel**: polls / votes / market_prices / street_protests / media_pressure / lobbying / other
- **Time lag** from group shift to entity feeling pressure
- **Historical verification**: a past instance where this pathway actually operated
- **Break conditions**: when does this pathway fail?

## §6 Observable State Indicators (1-3)
For each measurable macro indicator:
- **Indicator name** (e.g., "MAGA approval rating for Trump")
- **Measurement method**: how it is actually measured
- **Current value** (with source date)
- **Strategically relevant thresholds**: value → strategic implication when crossed. Each threshold must have historical precedent OR an entity-agent concession_trigger referencing it.

## §7 Historical Behavior Cases (2-4, optional but recommended)
Past instances when this group's attitudes shifted significantly:
- **Event, year**
- **Attitude shift**
- **Transmission mechanism** (how the shift reached decision-makers)

These cases support §4 Sensitivity Map calibration.

---

Once complete, paste the entire output above back into Claude Code and say "integrate this research for {TARGET_NAME}" so the character-toolkit skill can integrate it into the collective card's references.md. The **§0-§7** numbering matches references.md's Phase 1-6 Checkpoint structure directly (§7 supports §4 calibration).
```
