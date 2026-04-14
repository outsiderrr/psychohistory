# 个人实体角色卡生成流程（phase-based methodology v1.1）

> **适用对象：** 具体的个人（特朗普、内塔尼亚胡、鲍威尔、马斯克等）。
> **不适用于：** 组织（用 prompt-02）、群体（用 prompt-03）、角色间关系（用 prompt-04）。
> **版本：** v1.1 — phase-based，委托 Nuwa.skill 做认知蒸馏，references.md 主产物工作流与 prompt-02/03/04 一致。

---

## 方法论基础

prompt-01 和 prompt-02/03/04 的关键差异：**prompt-01 把认知蒸馏的重活委托给 Nuwa.skill**，自身只做 "前置确认 → 调用女娲 → 整理 references.md → 编译 JSON → 验证" 这五步的编排工作。女娲内部有自己的 Phase 1-4 执行流程，prompt-01 不重复它。

但**5 条通用设计原则同样适用**（详见 `character-toolkit/README.md` §方法论原则）：

1. **两阶段最少** — 女娲自身的蒸馏是多阶段，prompt-01 再叠加一层"整理 → 编译"的后处理
2. **references.md 是主产物** — 女娲的原始输出首先被整理成结构化的 references.md，JSON 是从 references.md 压缩出来的
3. **证据强度分级** — 女娲在其 Phase 4 会做源材料质量评估；prompt-01 把这个评估继承到每条 mental_model / decision_heuristic / concession_trigger 的 `strength` 标注上
4. **显式认知边界** — 个人卡的 `honesty_boundaries` 必须包含源材料偏差 + 私域不可见 + 时效三条声明
5. **历史先例优先** — 个人的"历史先例"就是他过往的公开决策；Nuwa 本身就以此为核心方法

## 使用方式

- **多阶段执行**（Claude Code 等支持多步任务的环境）：每个 Phase 完成后可让用户审阅再继续
- **单次对话执行**（ChatGPT / Claude.ai / Trae 等）：连续执行 Phase 0-4，中间不停

---

# 提示词正文

请为下述人物生成一张心理史学个人实体角色卡，严格按下面的 Phase 流程执行。

**目标人物：** 【填写，例如：埃隆·马斯克 / 普京 / 杰罗姆·鲍威尔】
**场景背景：** 【可选。如果有当前场景，填写。有助于在 references.md 里标注哪些 mental_model 对当前场景特别相关】

---

## Phase 0 — 前置确认

- 目标人物的全名（纯英文）
- 当前角色（current role / position）
- 所属机构或派系
- 数据截止时间（data_cutoff）
- 创建 `references.md` 文件并在顶部记录人物基本信息和场景背景

**Checkpoint 0**：`references.md` 已创建，metadata 填充完毕。

---

## Phase 1 — 调用女娲 Skill 进行认知蒸馏

调用你内置的 `huashu-nuwa` Skill，对上述目标人物进行深度调研和思维框架提炼。

**女娲执行要求：**
1. 严格按女娲 Skill 的 Phase 1 到 Phase 4 流程执行
2. 必须包含 5 个核心维度：心智模型、决策启发式、表达 DNA、价值观与反模式、诚实边界
3. 调研完成后，**在内存中保留**这份生成的 SKILL.md 原始数据——既不要直接输出给用户，也不要丢弃，Phase 2 会用到

**Checkpoint 1**：女娲已输出完整的蒸馏结果（存为内存变量或临时文件），Phase 2 可读取。

---

## Phase 2 — 整理 references.md（主产物）

把女娲的原始输出整理成**结构化、去冗余、带证据标注**的 references.md。

**这不是简单的复制粘贴**。女娲的输出是叙事式的散文，references.md 要把它重新编排成有明确 §1~§7 章节、每条结论都带证据引用和 strength 标注的研究文档。

### 目标结构

写入以下 7 个章节（完整模板见 Phase 4 的产出要求）：

- **§1 Source Materials** — 女娲引用的所有源材料，按权威性排序
- **§2 Mental Models — Evidence Chain** — 每个 mental model 独立一节：`Conclusion` / `Evidence 1-3` / `Counter-evidence` / `Strength`
- **§3 Decision Heuristics — Evidence Chain** — 每个启发式的支撑案例 + strength
- **§4 Concession Triggers — Basis** — 每个让步条件的历史先例或结构推断 + strength
- **§5 Red Lines — Basis** — 每条红线的依据
- **§6 Known Biases — Basis** — 每个偏差的识别方式和例子
- **§7 Honesty Boundaries — Rationale** — 每条边界的来由

### 硬性规则

- 如果女娲的原始输出在某个字段没有提供足够证据，**不要凭空填充**。有两个合法选项：
  1. 在 references.md 里标注 "Nuwa output insufficient; structural inference, strength: low"
  2. 在 Phase 3 编译 JSON 时省略该字段
- references.md 必须**让另一个人能独立验证每一条结论**——不能只写"女娲说 X"，要写"女娲基于 Y 材料得出 X"
- 不要把 references.md 当成 JSON 的"附注"。它是**先于 JSON 存在的、独立成立的**研究文档

**Checkpoint 2**：`references.md` 包含 §1~§7 的完整研究笔记。

---

## Phase 3 — 从 references.md 编译 JSON

**这是压缩步骤，不是新的调研**。每个 JSON 字段必须能指回 references.md 的对应段落。如果你发现某个字段找不到证据段，回到 Phase 2 补充——不要跳过、不要猜。

### 转换映射规则

**严格遵循以下规则。所有字段名和结构必须与示例完全一致，不得自行添加嵌套层级或重命名字段。**

#### 1. 基础信息（顶层字段）

| 字段 | 规则 | 示例 |
|---|---|---|
| `card_version` | 固定 `"1.0"` | `"1.0"` |
| `card_type` | 固定 `"personal-entity"` | `"personal-entity"` |
| `agent_id` | 英文名小写 + 连字符，姓在后 | `"elon-musk"`, `"benjamin-netanyahu"` |
| `name` | 全名 | `"Elon Musk"` |
| `role` | 当前核心职位 | `"CEO of Tesla & SpaceX"` |
| `affiliation` | 所属机构/国家/派系 | `"us-government"`, `"Likud / State of Israel"` |

#### 2. 来源信息（`source` 对象）

```json
"source": {
  "type": "nuwa-skill",
  "nuwa_skill_ref": "alchaincyf/[agent_id]-skill",
  "created_at": "YYYY-MM-DD",
  "data_cutoff": "YYYY-MM-DD"
}
```

`data_cutoff` 必须是完整的 `YYYY-MM-DD`，不能写 `"2026-04"` 这种不完整日期。

#### 3. 心智模型（`mental_models` 数组，顶层字段）

从 references.md §2 提取 2-10 个。每个元素：

```json
{
  "id": "mm-01",
  "name": "模型名称（英文，≤50 字符）",
  "description": "详细描述（英文，≥20 字符），说明此人用什么'镜片'看世界",
  "source_evidence": "指回 references.md §2 中对应的证据编号或简短描述",
  "strength": "high / medium / low"
}
```

**注意**：`name` 字段只写英文名称。不要写成 `"Permanent Siege Mentality (永久围城心态)"` 这种中英混用格式。

#### 4. 决策启发式（`decision_heuristics` 数组，顶层字段）

从 references.md §3 提取 2-12 条：

```json
{
  "id": "dh-01",
  "name": "启发式名称（英文，≤50 字符）",
  "description": "详细描述（英文，≥20 字符），可表述为 'if X then Y' 的快速判断规则",
  "strength": "high / medium / low"
}
```

#### 5. 让步触发器（`concession_triggers` 数组，顶层字段）

从 references.md §4 提取。至少 1 条。

```json
{
  "id": "ct-01",
  "description": "英文描述触发条件",
  "current_status": "Not activated",
  "historical_precedent": "§4 中的历史案例或标注 'Structural inference'",
  "strength": "high / medium / low"
}
```

`current_status` 默认填 `"Not activated"`，只在具体场景推演中才会被更新。

#### 6. 绝对红线（`red_lines` 字符串数组，顶层字段）

从 references.md §5 提取。至少 1 条。全英文。

```json
"red_lines": [
  "Will never publicly admit a policy was a mistake.",
  "Will never accept a deal framed as surrender."
]
```

#### 7. 表达 DNA（`expression_dna` 对象，顶层字段）

```json
"expression_dna": {
  "rhetorical_style": "英文描述句式偏好和修辞特征",
  "signature_phrases": ["phrase1", "phrase2"],
  "certainty_style": "英文描述确定性表达风格"
}
```

#### 8. 价值观层级（`values_hierarchy` 字符串数组，顶层字段）

**⚠️ 关键：此字段直接放在 JSON 顶层，不得包裹在任何父对象中。**

```json
"values_hierarchy": [
  "Value 1 (highest priority)",
  "Value 2",
  "Value 3"
]
```

#### 9. 已知偏差（`known_biases` 字符串数组，顶层字段）

**⚠️ 关键：此字段直接放在 JSON 顶层，不得包裹在任何父对象中。**

```json
"known_biases": [
  "Sunk cost fallacy on public commitments.",
  "Confirmation bias towards information that supports existing worldview."
]
```

#### 10. 诚实边界（`honesty_boundaries` 字符串数组，顶层字段）

**⚠️ 关键：此字段直接放在 JSON 顶层，不得包裹在任何父对象中。**

从 references.md §7 提取。至少 1 条。全英文。**个人卡的 `honesty_boundaries` 必须包含三条**：
- **源材料偏差声明**（"based on public / secondary sources"）
- **私域不可见声明**（"cannot capture private deliberation"）
- **数据时效声明**（"snapshot as of data_cutoff; beliefs may shift rapidly"）

```json
"honesty_boundaries": [
  "Public statements may diverge significantly from actual policy intentions.",
  "Cannot capture private deliberation process or undisclosed personal/financial interests.",
  "This card is a snapshot as of data_cutoff; beliefs and strategies may shift rapidly."
]
```

### 完整 JSON 顶层结构参考

生成的 JSON 必须严格遵循以下顶层结构，不多不少：

```
{
  "card_version": ...,
  "card_type": "personal-entity",
  "agent_id": ...,
  "name": ...,
  "role": ...,
  "affiliation": ...,
  "source": { ... },
  "mental_models": [ ... ],
  "decision_heuristics": [ ... ],
  "concession_triggers": [ ... ],
  "red_lines": [ ... ],
  "expression_dna": { ... },
  "values_hierarchy": [ ... ],
  "known_biases": [ ... ],
  "honesty_boundaries": [ ... ]
}
```

**禁止：**
- 不得在上述字段外添加额外的顶层字段
- 不得将 `values_hierarchy`、`known_biases`、`honesty_boundaries` 包裹在 `values_and_blind_spots` 或任何其他父对象中
- 不得在 `name` 字段中混用中英文（如 `"Permanent Siege Mentality (永久围城心态)"`）
- 不得使用不完整的日期格式

**Checkpoint 3**：JSON 已编译，每个非空字段都能指回 references.md 的对应段落。

---

## Phase 4 — 验证与产出

### 验证清单

- [ ] Schema 层校验：通过 character-schema v1.1 的 `personal-entity` oneOf 分支
- [ ] `card_version` 是 `"1.0"`
- [ ] `card_type` 是 `"personal-entity"`
- [ ] `agent_id` 符合 `^[a-z0-9-]+$`
- [ ] `source.data_cutoff` 是完整的 `YYYY-MM-DD`
- [ ] `mental_models` 有 2-10 个，每个 `description` ≥20 字符，每个有 `source_evidence` 和 `strength`
- [ ] `decision_heuristics` 有 2-12 个，每个有 `strength`
- [ ] `concession_triggers` 至少 1 个，每个有 `historical_precedent` 和 `strength`
- [ ] `red_lines` 至少 1 个
- [ ] `honesty_boundaries` **必须包含源材料偏差 + 私域不可见 + 时效三条声明**
- [ ] `values_hierarchy` / `known_biases` / `honesty_boundaries` 都在 JSON 顶层
- [ ] 所有 `name` 字段都是纯英文，没有中文括号注释
- [ ] JSON 可通过标准 JSON 解析器
- [ ] references.md 的 §1~§7 每节都有实质内容，不是空壳
- [ ] 每个 JSON 字段都能在 references.md 里找到对应证据段

### 产出文件（三份）

1. **`skill/characters/nuwa/[agent_id].md`**
   女娲原始蒸馏输出，保留作为审计记录。

2. **`skill/characters/psychohistory/[agent_id].references.md`**
   **主产物**。按以下结构组织：

```markdown
# [Person Name] — Character Card References

> Comprehensive research notes on [Person Name]. This is the primary artifact;
> the accompanying [agent_id].json is a compressed index compiled from this document.
> Every field in the JSON traces back to a specific section here.

**Data cutoff**: YYYY-MM-DD
**Nuwa skill reference**: alchaincyf/[agent_id]-skill
**Scenario relevance** (if applicable): [brief note on how this card maps to current scenario]

## §1 Source Materials

- [List of all reference materials used by Nuwa: books, interviews, memoirs, psychological analyses, decision records, etc. Ranked by authority.]

## §2 Mental Models — Evidence Chain

### mm-01: [Model Name]
- **Conclusion:** [one-sentence summary]
- **Evidence 1:** [specific quote / decision / behavior with source attribution]
- **Evidence 2:** [...]
- **Evidence 3:** [...]
- **Counter-evidence / Limitations:** [contradicting evidence or known scope limits]
- **Strength:** high / medium / low

(Repeat for each mental model)

## §3 Decision Heuristics — Evidence Chain

### dh-01: [Heuristic Name]
- **Conclusion:** [one-sentence summary]
- **Supporting cases:** [specific historical cases demonstrating this pattern]
- **Strength:** high / medium / low

(Repeat for each heuristic)

## §4 Concession Triggers — Basis

### ct-01: [Trigger description]
- **Historical precedent:** [when has this been triggered before? if never, explain the structural reasoning]
- **Strength:** high / medium / low

(Repeat for each trigger)

## §5 Red Lines — Basis

- [Evidence basis for each red line, citing cases where this person refused despite pressure]

## §6 Known Biases — Basis

- [How each bias was identified, with specific examples]

## §7 Honesty Boundaries — Rationale

- **Source material bias:** [why public/secondary sources are limited for this person]
- **Private deliberation invisibility:** [why the card cannot reach into private decision-making]
- **Data staleness:** [why the card is a snapshot and not a live model]
- [Any additional boundaries specific to this person]
```

3. **`skill/characters/psychohistory/[agent_id].json`**
   压缩索引，从 references.md 编译而成。

---

**不要输出中间解释**。按 Phase 顺序执行到完成，产出三份文件后停止。如果验证清单有任何一项不通过，先回到对应 Phase 修复再产出。

---

## Appendix: Research Hand-off Template (fallback for when Nuwa is unavailable)

This template is used by `character-toolkit/SKILL.md` in the **Research Hand-off protocol** when `Nuwa.skill` cannot be invoked. Nuwa remains the preferred research path for personal-entity cards; use this only as a fallback.

### Placeholders

- `{TARGET_NAME}` — person's full name
- `{TIME_WINDOW_START}` / `{TIME_WINDOW_END}` — research time window (typically 2-3 years ago through today)
- `{SCENARIO_CONTEXT}` — optional scenario description

### Template

```
You are researching {TARGET_NAME} for a cognitive profile in a Psychohistory scenario. The goal is to extract how this person thinks and decides — mental models, decision heuristics, concession conditions, red lines — NOT a biography.

Use your search capability to find: biographies, memoirs, interviews, psychological analyses, decision case studies, and examples of this person's actual behavior in high-stakes situations.

**Time focus for recent behavior**: {TIME_WINDOW_START} through {TIME_WINDOW_END}.
**Scenario context**: {SCENARIO_CONTEXT}

Return your findings in the following EXACT markdown format. Do not add sections, do not rename sections, do not skip sections.

## §1 Source Materials
Ranked list: biographies > autobiographies/memoirs > major interviews > decision case studies > psychological analyses > news profiles. For each: title, author, date, URL.

## §2 Mental Models (3-7)
For each cognitive lens this person uses to interpret the world:

### mm-01: [model name]
- **Description**: how this person fundamentally sees the world through this lens (≥20 chars)
- **Evidence 1**: specific quote, decision, or behavior with source attribution
- **Evidence 2**: ...
- **Counter-evidence / scope limits**: when this model doesn't apply
- **Strength**: high / medium / low

(Repeat for each mental model.)

## §3 Decision Heuristics (4-8)
Quick judgment rules this person repeatedly uses:

### dh-01: [heuristic name]
- **Rule**: can be stated as "if X then Y" (≥20 chars)
- **Supporting cases**: 2-3 historical decisions demonstrating the pattern
- **Strength**: high / medium / low

## §4 Concession Triggers (at least 2)
Conditions under which this person has historically changed position:

### ct-01: [trigger description]
- **Historical precedent**: when this trigger actually fired
- **Strength**: high / medium / low

## §5 Red Lines (at least 2)
Things this person has never done despite pressure:
- [red line] — with evidence of pressure applied but the line holding

## §6 Expression DNA
- **Rhetorical style**: direct / indirect, emotional / analytical, etc.
- **Signature phrases**: 3-5 distinctive verbal patterns
- **Certainty style**: "I believe" type vs "obviously" type vs "many people say" type

## §7 Values Hierarchy (3-5, ranked)
Core values in priority order. What does this person sacrifice when values conflict?

## §8 Known Biases
- [Bias name] with specific examples

## §9 Honesty Boundaries
What CANNOT this profile capture? Must include the following three required disclaimers:
- **Source material bias**: why public / secondary sources are limited for this person
- **Private deliberation invisibility**: why the profile cannot reach into private decision-making
- **Data staleness**: this is a snapshot; beliefs may shift
- [Any additional limitations specific to this person]

---

Once complete, paste the entire output above back into Claude Code and say "integrate this research for {TARGET_NAME}" so the character-toolkit skill can integrate it into the personal-entity card's references.md.
```
