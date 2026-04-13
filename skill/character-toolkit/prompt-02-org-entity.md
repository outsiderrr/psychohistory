# 组织实体角色卡生成提示词

> **适用对象：** 政府当局、央行、上市公司、军事组织、国际机构等有集中决策机制的组织。
> **不适用于：** 个人（用 prompt-01）、无决策中心的群体（用 prompt-03）。

---

## 使用方法

将以下内容完整复制，填入目标组织后发送。

---

## 提示词正文

请为以下组织生成一张心理史学组织实体角色卡。

**目标组织：【在此处填写，例如：美联储 / 伊朗伊斯兰革命卫队 / 苹果公司 / 伊朗政府】**

### 调研要求

请从以下六个维度对该组织进行深度调研，所有内容基于可查证的公开信息：

**1. 组织使命与核心目标**
- 该组织的法定使命或章程目标是什么？
- 实际运作中，它真正优先追求的目标是什么？（可能与法定使命有偏差）
- 当多个目标冲突时，历史上它倾向于牺牲哪个保哪个？

**2. 决策机制与权力结构**
- 最终决策权在谁手上？个人独裁、委员会投票、还是共识决策？
- 决策链条有多长？从信息输入到决策输出通常需要多少时间？
- 组织内部有哪些主要派系或立场分歧？

**3. 组织惯性与行为模式**
- 这个组织在过去20年中有哪些反复出现的行为模式？
- 面对外部冲击时，它的典型反应速度和方式是什么？（快速响应型 vs 缓慢官僚型）
- 它历史上最大的路径依赖是什么？（一旦开始就很难停下来的事）

**4. 对外沟通与信号释放**
- 它如何与外界沟通？（新闻发布会、官方声明、前瞻指引、模糊暗示）
- 它的公开表态与实际行动之间的一致性如何？
- 它有哪些标志性的措辞或"信号词"？

**5. 关键约束与依赖**
- 什么外部因素最能约束它的行为？（法律框架、上级授权、资金来源、盟友关系）
- 它最依赖什么资源？如果这个资源被切断会怎样？

**6. 历史关键决策案例**
- 列举3-5个该组织历史上最重要的决策节点
- 每个案例说明：当时面临的选择、最终的决定、决策背后的逻辑、事后的结果

---

### 格式转换规则

调研完成后，请将结果转换为以下严格的JSON格式。

**⚠️ 组织实体与个人实体使用相同的JSON顶层结构，但字段含义有所调整：**

```json
{
  "card_version": "1.0",
  "agent_id": "小写连字符格式，如 us-federal-reserve",
  "agent_type": "entity",
  "entity_subtype": "organization",
  "name": "组织全称英文",
  "role": "该组织在当前国际/商业体系中的角色定位",
  "affiliation": "所属国家或上级体系",

  "source": {
    "type": "system-derived",
    "created_at": "YYYY-MM-DD",
    "data_cutoff": "YYYY-MM-DD"
  },

  "decision_structure": {
    "type": "one of: autocratic / committee / consensus / hybrid",
    "key_decision_maker": "如果有明确的最终拍板人，写在这里；如果是委员会制，写委员会名称",
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
      "name": "组织级心智模型名称（英文，50字符内）",
      "description": "该组织如何看待世界、如何定义问题。至少20字符。",
      "source_evidence": "具体的历史决策、官方文件或反复出现的行为模式作为证据。"
    }
  ],

  "decision_heuristics": [
    {
      "id": "dh-01",
      "name": "组织级决策启发式名称（英文）",
      "description": "该组织在面对特定类型问题时的惯性反应模式。至少20字符。"
    }
  ],

  "organizational_inertia": {
    "current_trajectory": "如果不受任何新的外力，该组织目前的惯性方向是什么？",
    "change_resistance": "one of: very high / high / medium / low",
    "change_resistance_reasons": [
      "具体的阻力来源，如官僚结构、法律程序、内部分歧等"
    ]
  },

  "concession_triggers": [
    {
      "id": "ct-01",
      "description": "什么条件下该组织会偏离当前轨迹？",
      "current_status": "Not activated"
    }
  ],

  "red_lines": [
    "该组织绝对不会做的事"
  ],

  "communication_style": {
    "primary_channels": ["如 press conference, official statement, forward guidance"],
    "signal_words": ["该组织发出重大信号时使用的关键措辞"],
    "say_do_consistency": "one of: high / medium / low — 公开表态与实际行动的一致程度"
  },

  "key_dependencies": [
    {
      "resource": "该组织最依赖的外部资源",
      "impact_if_cut": "如果被切断的后果"
    }
  ],

  "historical_precedents": [
    {
      "event": "历史关键决策的简要描述",
      "year": "YYYY",
      "decision": "做了什么决定",
      "logic": "决策背后的逻辑",
      "outcome": "结果如何"
    }
  ],

  "values_hierarchy": [
    "组织的核心优先级排序（英文字符串数组）"
  ],

  "known_biases": [
    "该组织的已知系统性偏差（英文字符串数组）"
  ],

  "honesty_boundaries": [
    "这张卡做不到什么（英文字符串数组，至少1条）"
  ]
}
```

### 自检清单

生成JSON后，请逐项检查：

- [ ] `card_version` 是 `"1.0"`？
- [ ] `agent_id` 是纯小写字母+连字符？
- [ ] `entity_subtype` 是 `"organization"`？
- [ ] `source.data_cutoff` 是完整的 YYYY-MM-DD？
- [ ] `decision_structure.type` 是四个选项之一？
- [ ] `mental_models` 有 2-10 个，每个 `description` 至少20字符？
- [ ] `decision_heuristics` 有 2-12 个？
- [ ] `organizational_inertia` 已填写？
- [ ] `concession_triggers` 至少1个？
- [ ] `red_lines` 至少1个？
- [ ] `honesty_boundaries` 至少1个？
- [ ] `values_hierarchy`、`known_biases`、`honesty_boundaries` 都在JSON顶层？
- [ ] 所有文本内容是英文？
- [ ] JSON可通过标准解析器验证？

### 输出要求

1. **保存组织实体卡：** 将生成的JSON保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/psychohistory/[agent_id].json`

2. **保存索引文件（论证过程）：** 生成一份 Markdown 索引文件，保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/psychohistory/[agent_id].references.md`

索引文件必须包含以下结构：

```markdown
# [Organization Name] — Character Card References

> Evidence chain behind each field in [agent_id].json.
> For users who want to verify, challenge, or refine the conclusions.

## Source Materials
- [List all reference materials: official documents, policy statements, academic analyses, news reports, etc.]

## Decision Structure — Evidence
- **Type justification:** [Why classified as autocratic/committee/consensus/hybrid, with examples]
- **Internal factions:** [Evidence for each faction's existence and influence level]

## Mental Models — Evidence Chain
### mm-01: [Model Name]
- **Conclusion:** [One-sentence summary]
- **Evidence 1:** [Specific policy decision or institutional behavior with source]
- **Evidence 2:** [Additional evidence]
- **Counter-evidence / Limitations:** [Any contradicting patterns]

(Repeat for each mental model)

## Organizational Inertia — Evidence
- **Current trajectory basis:** [What evidence supports the stated inertial direction]
- **Change resistance basis:** [Historical examples of the organization resisting change]

## Decision Heuristics — Evidence Chain
### dh-01: [Heuristic Name]
- **Supporting cases:** [Specific historical decisions that demonstrate this pattern]

(Repeat for each heuristic)

## Historical Precedents — Detailed Analysis
### [Event Name, Year]
- **Context:** [What situation the organization faced]
- **Decision:** [What they decided]
- **Logic:** [Why, based on available evidence]
- **Outcome:** [What happened as a result]
- **Relevance to current card:** [Which mental models or heuristics does this case support]

## Concession Triggers — Basis
- [Evidence for each trigger, including historical instances if any]

## Key Dependencies — Basis
- [Evidence for each dependency relationship]
```

3. **不要输出中间解释，直接执行保存。** 如果自检清单有未通过项，先修复再保存。两个文件必须同时生成。
