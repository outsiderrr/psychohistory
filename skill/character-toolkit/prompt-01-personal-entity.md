# 心理史学人物卡生成流水线 Prompt

> **使用说明：** 这是一个两步走的流水线 Prompt。将以下内容完整复制，填入目标人物后发送即可。

---

## 目标人物

**【在此处填写你要蒸馏的人物，例如：埃隆·马斯克 / 普京 / 杰罗姆·鲍威尔】**

---

## 阶段一：调用女娲 Skill 生成原始人物卡

请使用你内置的 huashu-nuwa Skill，对上述目标人物进行深度调研和思维框架提炼。

**女娲执行要求：**
1. 严格按照女娲 Skill 的 Phase 1 到 Phase 4 流程执行。
2. 必须包含核心的 5 个维度：心智模型、决策启发式、表达 DNA、价值观与反模式、诚实边界。
3. 调研完成后，请在内存中保留这份生成的 SKILL.md 原始数据，不要直接输出给用户，直接进入阶段二。

---

## 阶段二：格式转换为 Psychohistory JSON

拿到女娲生成的原始人物卡数据后，请立即将其转换为心理史学引擎所需的严格 JSON 格式。

### 转换映射规则

**请严格遵循以下规则。所有字段名和结构必须与示例完全一致，不得自行添加嵌套层级或重命名字段。**

#### 1. 基础信息（顶层字段）

| 字段 | 规则 | 示例 |
|------|------|------|
| `card_version` | 固定 `"1.0"` | `"1.0"` |
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

注意：`data_cutoff` 必须是完整的 YYYY-MM-DD 格式，不能写 "2026-04" 这种不完整日期。

#### 3. 心智模型（`mental_models` 数组，顶层字段）

从女娲的心智模型中提取 3-7 个。每个元素结构：

```json
{
  "id": "mm-01",
  "name": "模型名称（英文，50字符内）",
  "description": "详细描述，英文，至少20个字符。说明此人用什么'镜片'看世界。",
  "source_evidence": "具体支撑证据：引用哪些决策、言论或行为证明此模型存在。"
}
```

**注意：** `name` 字段只写英文名称。如需中文对照，放在 `description` 里。不要写成 `"Permanent Siege Mentality (永久围城心态)"` 这种格式。

#### 4. 决策启发式（`decision_heuristics` 数组，顶层字段）

从女娲的决策启发式中提取 5-10 条。每个元素结构：

```json
{
  "id": "dh-01",
  "name": "启发式名称（英文，50字符内）",
  "description": "详细描述，英文，至少20个字符。可表述为 'if X then Y' 的快速判断规则。"
}
```

#### 5. 让步触发器（`concession_triggers` 数组，顶层字段）

从女娲的分析中提炼：什么极端条件下此人会妥协、退让或改变立场？至少 1 条。

```json
{
  "id": "ct-01",
  "description": "英文描述触发条件",
  "current_status": "Not activated"
}
```

`current_status` 一律默认设为 `"Not activated"`，在具体推演场景中才会更新。

#### 6. 绝对红线（`red_lines` 字符串数组，顶层字段）

从女娲的"反模式/绝对不会做的事"中提取。至少 1 条。全英文。

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

直接映射女娲的"诚实边界"。至少 1 条。全英文。

```json
"honesty_boundaries": [
  "Public statements may diverge significantly from actual policy intentions.",
  "This card is a snapshot as of data_cutoff date; beliefs may shift rapidly."
]
```

---

### 完整 JSON 顶层结构参考

生成的 JSON 必须严格遵循以下顶层结构，不多不少：

```
{
  "card_version": ...,
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
- 不得使用不完整的日期格式（如 `"2026-04"`，必须写 `"2026-04-13"`）

---

### 自检清单

生成 JSON 后，请逐项检查：

- [ ] `card_version` 是 `"1.0"`？
- [ ] `agent_id` 是纯小写字母 + 连字符？
- [ ] `source.data_cutoff` 是完整的 YYYY-MM-DD 格式？
- [ ] `mental_models` 有 2-10 个，每个 `description` 至少 20 字符？
- [ ] `decision_heuristics` 有 2-12 个？
- [ ] `concession_triggers` 至少 1 个？
- [ ] `red_lines` 至少 1 个？
- [ ] `honesty_boundaries` 至少 1 个？
- [ ] `values_hierarchy`、`known_biases`、`honesty_boundaries` 都在 JSON 顶层，没有被包裹在其他对象中？
- [ ] 所有 `name` 字段都是纯英文，没有中文括号注释？
- [ ] 整个 JSON 可以通过标准 JSON 解析器验证？

---

### 输出要求

1. **保存女娲原始数据：** 将阶段一生成的原始 Markdown 保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/nuwa/[agent_id].md`

2. **保存心理史学人物卡：** 将转换后的 JSON 保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/psychohistory/[agent_id].json`

3. **保存索引文件（论证过程）：** 生成一份 Markdown 索引文件，记录每个结论的推导依据，保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/psychohistory/[agent_id].references.md`

索引文件必须包含以下结构：

```markdown
# [Person Name] — Character Card References

> Evidence chain behind each field in [agent_id].json.
> For users who want to verify, challenge, or refine the conclusions.

## Source Materials
- [List all reference materials: books, interviews, memoirs, psychological analyses, decision records, etc.]

## Mental Models — Evidence Chain
### mm-01: [Model Name]
- **Conclusion:** [One-sentence summary]
- **Evidence 1:** [Specific evidence with source attribution]
- **Evidence 2:** [Specific evidence with source attribution]
- **Counter-evidence / Limitations:** [Any contradicting evidence or known limitations]

(Repeat for each mental model)

## Decision Heuristics — Evidence Chain
### dh-01: [Heuristic Name]
- **Conclusion:** [One-sentence summary]
- **Supporting cases:** [Specific historical cases that demonstrate this pattern]

(Repeat for each heuristic)

## Concession Triggers — Basis
### ct-01: [Trigger description]
- **Historical precedent:** [When has this been triggered before? If never, explain the reasoning]

## Red Lines — Basis
- [Evidence basis for each red line]

## Known Biases — Basis
- [How each bias was identified, with examples]
```

4. **不要输出任何中间解释，直接执行保存操作。** 如果自检清单有任何一项未通过，先修复再保存。三个文件必须同时生成。
