# 组织实体角色卡生成流程（phase-based methodology v1.1）

> **适用对象：** 政府、央行、上市公司、军事组织、国际机构等有集中决策机制的组织。
> **不适用于：** 个人（用 prompt-01）、无决策中心的群体（用 prompt-03）。
> **版本：** v1.1 — phase-based，从空白到 JSON 严格分阶段执行。

---

## 方法论基础

这不是一份一次性填空的模板。这是一份**分阶段执行**的生成流程。每个 Phase 都有独立的调研目标和 checkpoint 产出。先完成一个 Phase，再进入下一个；绝不允许跳步。

**5 条贯穿所有 Phase 的设计原则**（详见 `character-toolkit/README.md` §方法论原则）：

1. **两阶段最少** — 研究阶段先行，结构化阶段在后。绝不允许从空白直接跳 JSON
2. **references.md 是主产物** — JSON 是它的压缩索引。先写笔记 → 按它编译 JSON → 验证每个字段有证据
3. **证据强度分级** — 每条结论标注 `strength: high / medium / low`
4. **显式认知边界** — `honesty_boundaries` 必须包含组织特有声明（派系分化、决策机制盲区、源材料偏差）
5. **历史先例优先** — 有历史案例支撑的推理排在纯理论推理前面

## 使用方式

- **多阶段执行**（Claude Code 或类似环境）：按 Phase 顺序推进，每个 checkpoint 可以让用户审阅后再继续
- **单次对话执行**（ChatGPT / Claude.ai / Trae 等）：在一次响应里完成所有 Phase，但**必须按顺序推进**，不可跳步，不可省略 checkpoint 产出

---

# 提示词正文

请为下述组织生成一张心理史学组织实体角色卡，严格按下面的 Phase 流程执行。

**目标组织：** 【填写，例如：伊朗伊斯兰革命卫队 / 美联储 / 欧洲央行】
**场景背景：** 【填写，例如："2026 年 4 月美伊停火期即将到期"】
**建模粒度：** 【整体组织 / 特定部门】
**关联个人卡：** 【如果该组织的关键决策人物已有个人卡，列出其 agent_id；没有则留空】

---

## Phase 0 — 前置确认

在开始调研前，明确以下内容并记录在 `references.md` 的开头：

- 目标组织的正式名称 + 隶属
- 场景时间窗口（影响调研的时效范围）
- 建模粒度确认
- 如果有关联个人卡，记录其 agent_id 以便 Phase 3/4 引用

**Checkpoint 0**：输入完整，`references.md` 已创建并包含目标和场景描述。

---

## Phase 1 — 结构扫描

从以下六个子维度调研，每个维度的分析写入 `references.md §1 Structural Scan`：

### 1.1 组织使命与核心目标
- 法定使命 / 章程目标是什么？（引用可查证的官方文件）
- 实际运作中的真实优先级（可能与法定偏离）
- 当多个目标冲突时，历史上它倾向于牺牲哪个保哪个？

### 1.2 决策机制与权力结构
- 最终决策类型：`autocratic` / `committee` / `consensus` / `hybrid`
- 最终拍板人是谁？（个人或委员会名称）
- 从信息输入到决策输出通常需要多长时间？
- 内部主要派系及立场差异

### 1.3 对外沟通模式
- 主要对外渠道（新闻发布会 / 前瞻指引 / 模糊暗示）
- 标志性措辞或"信号词"
- 公开表态与实际行动的一致性程度

### 1.4 关键约束与依赖
- 最能约束其行为的外部因素（法律框架 / 上级授权 / 资金来源 / 盟友关系）
- 最依赖的资源，以及被切断的后果

### 1.5 组织惯性
- 如果不受新的外力，当前的惯性方向是什么？
- 改变方向的阻力来源（官僚结构 / 法律程序 / 内部分歧 / 路径依赖）
- 阻力量级：`very high` / `high` / `medium` / `low`

### 1.6 当前状态快照
- 场景时点下该组织正在做什么？
- 当前规模（人员 / 预算 / 覆盖范围等，按组织性质取合适的维度）
- 最近有无重要人事变动或战略转向？

**Checkpoint 1**：六个维度的分析全部写入 `references.md §1`，每个子维度独立小标题。

---

## Phase 2 — 历史决策案例收集（核心阶段）

收集 **5-10 个**该组织历史上的重要决策案例。每个案例必须包含：

- **日期 + 情境**：当时面临什么？
- **决策内容**：做了什么？
- **公开理由 vs 推测的真实理由**：两者可能不同，都记录
- **执行结果**：决定后发生了什么？
- **事后路径修正**：该组织有没有承认错误、调整方向，还是坚持到底？

**选择案例的标准**：
- 优先选**争议性 / 高风险**决策（平时的常规决策看不出性格）
- 覆盖不同领域（不要 5 个都是经济决策）
- 至少 2 个是近 5 年的（保证模式仍然成立）

**Checkpoint 2**：所有案例写入 `references.md §2 Historical Decision Cases`，每个案例独立小标题并编号（如 case-01~case-10）。**这是整个方法论的证据基础，后续 Phase 所有结论都要指回这里的案例编号**。

---

## Phase 3 — 模式提炼

基于 Phase 2 的案例做**横向对比**。**不允许**凭想象或意识形态推断模式——所有结论必须能指回 Phase 2 的具体案例编号。

### 3.1 提炼 mental_models（2-10 个）
- 反复出现的认知倾向 → 组织级 mental model
- 每个 mental model 必须引用 ≥2 个案例支撑
- 单案例支撑的模式标 `strength: medium`
- **无案例支撑的纯理论推导不写入 JSON**，记录在 references.md 的"未采信的假说"段

### 3.2 提炼 decision_heuristics（2-12 条）
- 对特定类型输入的反射性反应 → decision heuristic
- 表述为 "if X then Y" 形式
- 每条引用支撑案例

### 3.3 提炼 concession_triggers（≥1 条）
- 历史上让步的条件（必须有真实先例）
- 如果没有历史先例但结构上必然存在（例如"如果被上级直接下令取消"），标 `strength: low` 并注明是结构性推测

### 3.4 提炼 red_lines（≥1 条）
- 从未跨越的线——哪怕压力极大也没做
- 引用对应案例证明"面对 X 压力仍未跨越"

**Case concentration check**: if more than half of the extracted mental_models or decision_heuristics share the same supporting cases (e.g., case-01 appears in 4 out of 6 conclusions), add a **case-concentration note** in §3 alerting reviewers that the evidence base is narrow. Consider whether Phase 2 should be re-run with a request for more diverse cases (especially domestic/economic cases if the current set is military-heavy).

**Checkpoint 3**：提炼结果写入 `references.md §3 Pattern Extraction`，每条结论都标注证据来源（指回 §2 的案例编号）和 strength 等级。

---

## Phase 4 — 派系与惯性分析

### 4.1 当前派系结构
- 主导派系是哪个？
- 其他主要派系及立场
- 派系间的权力消长趋势（过去 12-36 个月）

### 4.2 组织惯性（在 Phase 1.5 基础上深化）
- 当前的惯性行为链
- 改变需要什么量级的外部冲击
- 历史上有没有惯性被打破的先例？

### 4.3 派系 → `alternative_frameworks`（可选，条件触发）

**只在派系间存在显著认知框架差异时做这一步**。区分两种差异：
- **立场差异**（不需要 alternative_frameworks）：同一个 mental model 下对具体问题给出不同答案。例：美联储鸽派和鹰派都接受"双重使命"，只是对当前哪个更紧迫有不同判断
- **认知框架差异**（适合 alternative_frameworks）：不同的 mental model 本身——看世界的方式不同。例：IRGC 强硬派认为"反抗美以是组织合法性的根基"，实用派认为"经济帝国才是 IRGC 的实际基石"——这是两套不同的心智框架

如果判断为"认知框架差异"：
- 主 JSON 的 `mental_models` / `decision_heuristics` 反映**当前主导派系**
- 在 `alternative_frameworks` 数组里添加一条：
  - `framework_id`: `alt-[faction-name]`（例：`alt-irgc-pragmatist`）
  - `name`: 该派系名称
  - `description`: 这个替代框架与主框架的核心差异（≥20 字符）
  - `mental_models_override`: 该派系的替代 mental_models
  - `decision_heuristics_override`: 该派系的替代 heuristics
  - `proposed_by`: `system-derived`
  - `rationale`: 什么观察激发了这个替代假设

**判断标准**：如果不确定是立场差异还是框架差异，**默认不做**（跳过 alternative_frameworks）。只对那些"一旦主导派系切换、组织行为会结构性变化"的组织使用。

**Checkpoint 4**：派系和惯性分析写入 `references.md §4 Factional Analysis & Inertia`；如果产出了 alternative_frameworks 条目，在 §4.3 独立记录其证据链。

---

## Phase 5 — JSON 结构化

**这是把 references.md 压缩成可执行索引的步骤，不是新的调研**。每个字段必须在 references.md 里有对应的证据段。

### JSON 结构（character-schema v1.1 组织实体分支）

```json
{
  "card_version": "1.0",
  "card_type": "organization-entity",
  "agent_id": "小写连字符格式，如 irgc 或 us-federal-reserve",
  "name": "组织全称英文",
  "role": "组织在当前国际/行业体系中的角色定位",
  "affiliation": "所属国家或上级体系",

  "source": {
    "type": "system-derived",
    "created_at": "YYYY-MM-DD",
    "data_cutoff": "YYYY-MM-DD"
  },

  "decision_structure": {
    "type": "one of: autocratic / committee / consensus / hybrid",
    "key_decision_maker": "最终拍板人的名字或委员会名称",
    "decision_speed": "one of: fast (days) / medium (weeks) / slow (months)",
    "internal_factions": [
      {
        "name": "派系名称",
        "stance": "该派系的总体倾向",
        "influence": "one of: dominant / significant / marginal"
      }
    ]
  },

  "mental_models": [
    {
      "id": "mm-01",
      "name": "组织级心智模型名称（英文，≤50 字符）",
      "description": "该组织如何看待世界、如何定义问题（英文，≥20 字符）",
      "source_evidence": "引用 references.md §2 的具体案例编号及简短理由",
      "strength": "high / medium / low"
    }
  ],

  "decision_heuristics": [
    {
      "id": "dh-01",
      "name": "组织级决策启发式名称（英文）",
      "description": "反射性反应规则（≥20 字符），表述为 'if X then Y' 形式",
      "strength": "high / medium / low"
    }
  ],

  "organizational_inertia": {
    "current_trajectory": "当前惯性方向（英文）",
    "change_resistance": "very high / high / medium / low",
    "change_resistance_reasons": ["具体阻力来源（英文数组）"]
  },

  "concession_triggers": [
    {
      "id": "ct-01",
      "description": "什么条件下该组织会偏离当前轨迹",
      "current_status": "Not activated",
      "historical_precedent": "引用 §2 案例编号，或标注 'No precedent, structural inference'",
      "strength": "high / medium / low"
    }
  ],

  "red_lines": [
    "该组织绝对不会做的事（每条附带 §2 中的反例案例引用）"
  ],

  "communication_style": {
    "primary_channels": ["press conference / official statement / forward guidance 等"],
    "signal_words": ["重大信号时的关键措辞"],
    "say_do_consistency": "high / medium / low"
  },

  "key_dependencies": [
    {
      "resource": "关键外部资源",
      "impact_if_cut": "被切断的后果"
    }
  ],

  "historical_precedents": [
    {
      "event": "案例简要描述",
      "year": "YYYY",
      "decision": "做了什么",
      "logic": "决策逻辑",
      "outcome": "结果"
    }
  ],

  "values_hierarchy": ["核心优先级排序"],
  "known_biases": ["已知系统性偏差"],

  "honesty_boundaries": [
    "(REQUIRED) Factional disclaimer: e.g. 'This card reflects the dominant faction X at data_cutoff; non-dominant factions would diverge on fields A, B, C'",
    "组织决策机制的盲区",
    "源材料偏差声明"
  ],

  "alternative_frameworks": [
    // 可选；仅 Phase 4.3 识别出派系认知框架差异时填充
  ]
}
```

**Checkpoint 5**：JSON 已编译，每个非空字段都能指回 references.md 的对应段。

---

## Phase 6 — 验证与产出

### 验证清单

执行以下检查，**任何一项不通过都不允许产出**：

- [ ] Schema 层校验：通过 character-schema v1.1 的 `organization-entity` oneOf 分支
- [ ] 每个 mental_model 的 source_evidence 指向 §2 中的具体案例编号（high 要 ≥2 个）
- [ ] 每个 concession_trigger 要么有历史先例，要么明确标 `strength: low`
- [ ] `honesty_boundaries` 包含**派系分化声明**
- [ ] mental_models 之间没有直接矛盾（或矛盾被 Phase 4.3 的 alternative_frameworks 吸收）
- [ ] JSON 可通过标准 JSON 解析器
- [ ] 所有 name / description / 字段值使用英文
- [ ] 所有日期字段使用完整 `YYYY-MM-DD` 格式
- [ ] `agent_id` 符合 `^[a-z0-9-]+$`

### 产出文件

1. **`skill/characters/psychohistory/[agent_id].references.md`** — 主产物。包含 Phase 0-4 所有调研笔记、案例、证据链
2. **`skill/characters/psychohistory/[agent_id].json`** — 压缩索引，按 Phase 5 的结构从 references.md 编译而成

不要输出中间解释。按 Phase 顺序执行到完成，产出两份文件后停止。

---

## Appendix: Research Hand-off Template

This template is used by `character-toolkit/SKILL.md` during the **Research Hand-off protocol** to collect raw data for **Phase 1** (structural scan) and **Phase 2** (historical decision cases). Output section numbering (**§0, §1.1-§1.6, §2**) matches the Phase 1/2 Checkpoint structure for **direct 1:1 integration** into `references.md`. Phase 3 (Pattern Extraction) and Phase 4 (Factional Analysis) are NOT in this research output — they are derived locally during skill execution from §1 + §2 data.

### Placeholders

- `{TARGET_NAME}` — the organization (e.g., "Islamic Revolutionary Guard Corps (IRGC)", "US Federal Reserve")
- `{TIME_WINDOW_START}` / `{TIME_WINDOW_END}` — typically 2-3 years ago through today
- `{SCENARIO_CONTEXT}` — brief scenario description

### Template

```
You are researching {TARGET_NAME} for a structured organization profile in a Psychohistory geopolitical scenario analysis. Use your search capability to find reputable sources: major news outlets (Reuters, AP, AFP, FT, WSJ, The Economist), think tanks (CSIS, Brookings, Chatham House, Atlantic Council, RAND), academic journals, and primary source documents where available.

**Time focus**: {TIME_WINDOW_START} through {TIME_WINDOW_END}.
**Scenario context**: {SCENARIO_CONTEXT}

Return your findings in the following EXACT markdown format. Do not add sections, do not rename sections, do not skip sections.

## §0 Source Materials
Ranked list of 5-10 sources consulted: publisher, title, date, URL.

## §1.1 Mission and Core Objectives
- **Formal mission / charter goal**: ...
- **Actual operational priorities** (may differ from the formal mission): ...
- **When objectives conflict, which does the organization historically sacrifice?**: ...

## §1.2 Decision Mechanism and Power Structure
- **Decision-making mechanism**: autocratic / committee / consensus / hybrid
- **Final decision-maker(s)**: ...
- **Decision speed**: fast (days) / medium (weeks) / slow (months)
- **Main internal factions**: list each with name, stance, relative influence (dominant / significant / marginal)

## §1.3 Communication Style
- **Primary channels**: press conference / official statement / forward guidance / leaks / etc.
- **Signature words or phrases**: distinctive signals when real shifts are coming
- **Say-do consistency**: high / medium / low, with examples

## §1.4 Key Dependencies and Constraints
3-5 items:
- [Resource or relationship] — [what it enables] — [consequence if cut or removed]

## §1.5 Organizational Inertia
- **Current trajectory**: what the organization will keep doing if unperturbed
- **Change resistance level**: very high / high / medium / low
- **Sources of resistance**: bureaucracy / legal procedures / internal factional deadlock / path dependence / etc.
- **Historical examples of inertia being broken**: any precedents in the past ~10 years

## §1.6 Current State Snapshot
- **Current size** (personnel / budget / coverage — whichever is most relevant for this organization type)
- What the organization is currently focused on
- Recent personnel changes or strategic shifts within the past 6 months

## §2 Historical Decision Cases (5-10)
For each case:

### case-01 (YYYY-MM-DD): [brief descriptive title]
- **Context**: the situation the organization was facing
- **Decision**: what the organization actually did (action, not rhetoric)
- **Stated rationale**: the official public reason
- **Inferred actual rationale**: what analysts read as the real driver (if different)
- **Outcome**: what happened in the weeks/months after
- **Subsequent correction**: did the organization adjust, reverse, or double down?

Prioritize contentious or high-stakes decisions. Routine decisions reveal little about organizational character.

---

Once complete, paste the entire output above back into Claude Code and say "integrate this research for {TARGET_NAME}" so the character-toolkit skill can integrate it into the organization card's references.md. The **§0 / §1.x / §2** numbering matches references.md's Phase 1 + Phase 2 Checkpoint structure directly.
```
