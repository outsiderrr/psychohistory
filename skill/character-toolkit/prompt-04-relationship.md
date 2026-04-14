# 角色间关系生成流程（phase-based methodology v1.1）

> **适用场景：** 当你已有两个或多个角色卡，需要定义它们在特定场景中的互动关系时使用。
> **前置条件：** 相关角色卡必须已生成且通过 schema 校验。
> **关键特性：** 关系是**场景相关**的——同样两个角色在不同场景下可能有不同的关系参数。
> **版本：** v1.1 — phase-based with mandatory precondition gate。

---

## 方法论基础

关系卡是**派生物，不是原生产物**。它的质量上限由两张端点卡决定。核心原则：

- **前置检查优先**：端点卡都存在且有效，才开始关系分析
- **互动历史挖掘**：基于端点卡之间真实发生过的互动推导关系参数
- **场景时效声明**：明确这份关系定义只在当前场景成立

**5 条通用设计原则**同样适用（详见 `character-toolkit/README.md` §方法论原则）。

## 使用方式

- **多阶段执行**：按 Phase 顺序推进，Phase 0 必须作为硬门槛
- **单次对话执行**：一次完成所有 Phase，但 Phase 0 失败则必须立即终止

---

# 提示词正文

请为下面两个角色在指定场景下生成一份关系定义。

**角色 A：** 【填写 agent_id，例如 iran-government】
**角色 B：** 【填写 agent_id，例如 irgc-leadership】
**场景背景：** 【简要描述，例如 "2026 年 4 月美伊停火期即将到期的局势"】

---

## Phase 0 — 前置检查（强制 gate）

在做任何调研之前，必须确认以下内容。**任何一项不满足，流程终止**，要求用户先生成或修复端点卡。

- [ ] `skill/characters/psychohistory/[agent_a_id].json` 存在
- [ ] `skill/characters/psychohistory/[agent_b_id].json` 存在
- [ ] 两张卡都通过 character-schema v1.1 校验
- [ ] 两张卡的 `affiliation` 字段可以推出"是否同属一个共同体"
- [ ] 两张卡的 `data_cutoff` 与场景时间窗口不冲突（如果卡是 6 个月前生成的但场景是本周，必须警告用户）

**如果不满足**：输出具体缺失项并终止流程。不要"凑合着生成"。

**Checkpoint 0**：前置条件全部通过，创建 `references.md`。

---

## Phase 1 — 场景定位

### 1.1 当前场景
- 完整的场景背景描述
- 关系最相关的议题是什么？
- 为什么需要在这个场景下建模这段关系？

### 1.2 历史版本
- 这对关系过去是否被建模过？
- 如有，当时的参数和现在的差异
- 什么事件推动了参数变化？

**Checkpoint 1**：场景写入 `references.md §1 Scenario Context`。

---

## Phase 2 — 互动历史挖掘（核心阶段）

收集 **至少 5 个**该对 agent 直接互动的历史案例。

每个案例需要：
- **日期 + 情境**
- **互动类型**：冲突 / 一致 / 模糊
- **场面话 vs 实质行动**：区分公开表态和实际行为
- **A 和 B 各自的选择**：面对同一情境两边做了什么
- **后续效应**：这次互动对后续关系的影响

**关键寻找**：
- **模式切换时刻**：B 曾经脱离 A 的控制过吗？如果有，发生在什么时候？恢复了吗？
- **相互威胁的可信度**：双方威胁过对方吗？威胁被兑现了吗？
- **外部危机下的对齐/分裂**：面对共同敌人时，关系加强还是暴露裂痕？

**选择案例的标准**：
- 优先选**高张力**时刻（平时的合作看不出关系本质）
- 覆盖不同议题领域
- 至少 2 个是近 24 个月的

**Checkpoint 2**：案例和分析写入 `references.md §2 Interaction History`，每个案例独立编号（interaction-01~interaction-05+）。

---

## Phase 3 — 结构性判断

### 3.1 共同体判断
- A 和 B 是否属于同一个更大的共同体？
- 如果是，哪一方在名义上层级更高？
- 这个层级在实际运作中被遵守的程度？（引用 §2 案例）

### 3.2 关系类型选择

从以下五种中选一种：

| 类型 | 适用场景 |
|---|---|
| `loyalty` | 同一共同体内的上下级 |
| `influence` | 群体对实体的影响力 |
| `alliance` | 不同共同体之间的合作 |
| `rivalry` | 对手关系 |
| `dependency` | 单向依赖 |

**类型判断必须引用 §2 的具体案例**作为依据。

### 3.3 当前模式（仅 loyalty 类型需要）
- 当前是 `loyal` 模式还是 `independent` 模式？
- 判断依据必须引用 §2 的具体案例

**Checkpoint 3**：结构判断写入 `references.md §3 Structural Classification`。

---

## Phase 4 — 数值校准

### 4.1 current_value（0-100）

标定参考表：

| 数值范围 | 含义 | 现实对应 |
|---|---|---|
| 90-100 | 绝对忠诚 / 无条件服从 | 极罕见，通常只在危机初期短暂出现 |
| 70-89 | 高度忠诚，有分歧但服从 | 有分歧但服从整体方向 |
| 50-69 | 中等忠诚，有条件服从 | 某些议题上公开表示不同意见 |
| 30-49 | 低忠诚，接近模式切换 | 频繁公开分歧 |
| 0-29 | 独立模式 / 事实上的对抗 | 自行其是，可能暗中破坏对方决策 |

**必须引用具体 §2 案例证明数值**。避免"中等偏上"这种无依据的填值。

### 4.2 threshold
- 基于场景压力环境校准
- 高压力场景下应该设低一些（更容易切换到 independent），低压力下高一些
- 必须给出 threshold 背后的推理

### 4.3 loyalty_modifiers（3-5 个）

对每个会影响忠诚度的事件类型：
- `event_type`：事件描述
- `impact`：整数，+5 到 +30 或 -5 到 -30
- `description`：为什么这个事件会影响忠诚度
- `historical_parallel`：历史上类似事件发生时忠诚度实际变化的案例（§2 或外部引用）
- `could_trigger_switch`：这个事件单独是否就能触发模式切换
- `strength`：`high` / `medium` / `low`

**Checkpoint 4**：校准和 modifiers 写入 `references.md §4 Calibration`。

---

## Phase 5 — 场景时效声明

### 5.1 时效边界
- 这份关系定义在什么时间范围内成立？
- 什么外部变化会让它失效？
- 如果主导派系切换、关键决策人物更换，参数会如何变化？

### 5.2 honesty_boundaries（必需）
**必须包含**：
- **场景绑定声明**："This relationship definition is scoped to scenario X; other scenarios may yield different parameters"
- **数据时效声明**
- **模式切换的不可预测性**："Mode switching threshold is calibrated, but triggering events are stochastic"
- **端点卡依赖声明**："Quality of this relationship card is upper-bounded by the quality of the two endpoint cards"

**Checkpoint 5**：声明写入 `references.md §5 Scope & Boundaries`。

---

## Phase 6 — JSON 结构化与产出

### JSON 结构

```json
{
  "relationship_id": "rel-[三位数字]，如 rel-001",
  "scenario_context": "这段关系所属的场景描述（英文）",
  "agent_a": "层级较高或被影响的角色的 agent_id",
  "agent_b": "层级较低或施加影响的角色的 agent_id",
  "affiliation": "共同所属的更大共同体，如 iran；如无共同体写 'none'",

  "relationship_type": "one of: loyalty / influence / alliance / rivalry / dependency",

  "loyalty": {
    "direction": "B → A 表示 B 服从 A，A ← B 表示 A 受 B 影响",
    "current_value": 70,
    "threshold": 40,
    "current_mode": "loyal / independent",
    "basis": "institutional hierarchy / personal relationship / shared interests / fear",
    "description": "当前关系状态的描述（英文，≥20 字符）",
    "supporting_evidence": "引用 §2 案例编号"
  },

  "mode_definitions": {
    "loyal": {
      "description": "忠诚模式下这段关系如何运作（英文）",
      "constraint_on_agent_a": "A 在做决策时必须避免什么"
    },
    "independent": {
      "description": "独立模式下双方如何互动",
      "trigger": "什么条件触发模式切换",
      "residual_cooperation": "即使独立，双方还有什么共同利益约束行为"
    }
  },

  "loyalty_modifiers": [
    {
      "event_type": "事件类型（英文）",
      "impact": -30,
      "description": "为什么这个事件会影响忠诚度（英文，≥20 字符）",
      "historical_parallel": "§2 中的类似案例或外部引用",
      "could_trigger_switch": true,
      "strength": "high / medium / low"
    }
  ],

  "source": {
    "type": "system-derived",
    "created_at": "YYYY-MM-DD",
    "scenario_specific": true
  },

  "honesty_boundaries": [
    "(REQUIRED) Scenario-binding disclaimer",
    "(REQUIRED) Data staleness disclaimer",
    "Mode switching stochasticity disclaimer",
    "Endpoint card dependency disclaimer"
  ]
}
```

### 自检清单

- [ ] Phase 0 前置检查通过
- [ ] ≥5 个互动历史案例已收集并编号
- [ ] `relationship_type` 是五个选项之一
- [ ] `current_value` 引用了具体 §2 案例
- [ ] `current_mode` 与 `current_value` / `threshold` 的数值逻辑一致（current_value > threshold → loyal；current_value ≤ threshold → independent）
- [ ] `loyalty_modifiers` ≥3 个，每个有 `historical_parallel`
- [ ] 每个 modifier 的 `impact` 绝对值在 5-30 之间
- [ ] `honesty_boundaries` 包含场景绑定和数据时效两条声明
- [ ] JSON 可解析
- [ ] 日期格式 `YYYY-MM-DD`
- [ ] 所有文本英文

### 产出文件

1. **`skill/characters/relationships/[relationship_id].references.md`** — 主产物
2. **`skill/characters/relationships/[relationship_id].json`** — 压缩索引

不要输出中间解释。按 Phase 顺序执行到产出两份文件为止。

---

## Appendix: Research Hand-off Template

This template is used by `character-toolkit/SKILL.md` during the **Research Hand-off protocol** when Phase 2 (interaction history mining) needs external research.

### Placeholders

- `{AGENT_A_NAME}` — display name of first agent
- `{AGENT_B_NAME}` — display name of second agent
- `{TIME_WINDOW_START}` / `{TIME_WINDOW_END}`
- `{SCENARIO_CONTEXT}`

### Template

```
You are researching the historical and current relationship between {AGENT_A_NAME} and {AGENT_B_NAME} for a Psychohistory scenario inter-agent relationship card.

The goal is to find **direct interactions** between these two agents — public statements about each other, joint actions, moments of tension, moments of alignment, and any instances where one broke from the other's control or expected direction.

Use your search capability to find: news reports of direct interactions, official statements, leaked communications (if any), and historical analyses of the relationship.

**Time focus**: {TIME_WINDOW_START} through {TIME_WINDOW_END}.
**Scenario context**: {SCENARIO_CONTEXT}

Return your findings in the following EXACT markdown format.

## §1 Source Materials
Ranked list of sources: major news outlets, think tanks, academic analyses, primary statements.

## §2 Interaction History (at least 5 cases)
For each direct-interaction case:

### interaction-01 (YYYY-MM-DD): [brief descriptive title]
- **Interaction type**: conflict / alignment / ambiguous
- **Context**: the situation both agents were responding to
- **{AGENT_A_NAME}'s public statement or action**
- **{AGENT_B_NAME}'s public statement or action**
- **Public-vs-actual behavior divergence** (if any)
- **Outcome on the relationship**: strengthened / weakened / unchanged

Prioritize high-tension moments. Routine cooperation reveals little about relationship character.

## §3 Common Affiliation
- **Do A and B belong to a common larger community?** Yes / No
- **If yes**: which one is nominally higher in the hierarchy?
- **Actual adherence to hierarchy**: is the nominal hierarchy respected in practice? Evidence?

## §4 Mode Switching History
- **Has B ever broken from A's expected direction?** Yes / No
- **If yes**: what was the trigger? Was the break recovered?
- **What would it take to break the relationship again?** (based on patterns in §2)

## §5 Public Threats and Credibility
- **Has either agent publicly threatened the other?**
- **If yes**: were the threats carried out? How did the other side respond?

## §6 External Crisis Response
- **How does the relationship behave when facing a common adversary?** Does it strengthen the bond or expose cracks? Give examples from the past 5 years.

---

Once complete, paste the entire output above back into Claude Code and say "integrate this research for {AGENT_A_NAME}-{AGENT_B_NAME}" so the character-toolkit skill can integrate it into the relationship card's references.md.
```
