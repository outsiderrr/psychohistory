# 角色间关系生成提示词

> **适用场景：** 当你已经有了两个或多个角色卡，需要定义它们在特定场景中的互动关系时使用。
> **前置条件：** 相关角色卡（个人/组织/群体）必须已经生成。
> **注意：** 关系是场景相关的——同样两个角色在不同场景下可能有不同的关系参数。

---

## 使用方法

将以下内容完整复制，填入相关信息后发送。

---

## 提示词正文

请为以下两个角色在指定场景下生成一份关系定义。

**角色A：【填写 agent_id，如 iran-government】**
**角色B：【填写 agent_id，如 irgc-leadership】**
**场景背景：【简要描述当前场景，如"2026年4月美伊谈判破裂后的局势"】**

### 调研要求

请基于公开信息分析以下内容：

**1. 从属关系判断**
- A和B是否属于同一个更大的共同体？（如都属于"伊朗"、都属于"美国政府"）
- 如果是，谁在名义上的层级更高？
- 这个名义上的层级关系在实际运作中被遵守的程度如何？

**2. 忠诚度评估**
- 在当前场景下，B对A的服从程度如何？（或反过来）
- 这个服从是基于什么？（制度约束、个人关系、共同利益、恐惧）
- 当前有没有公开的分歧或摩擦？具体在哪些议题上？

**3. 模式判断**
- 当前是"忠诚模式"（B服从A的决策方向，但A需要考虑B的倾向）还是"独立模式"（B自行其是）？
- 如果是忠诚模式，A在做决策时必须避免什么才能维持B的忠诚？
- 如果是独立模式，A和B之间还有什么共同利益在约束双方行为？

**4. 忠诚度修正因子**
- 在当前场景下，什么事件会增加B对A的忠诚度？
- 什么事件会降低B对A的忠诚度？
- 有没有"一击致命"的事件——发生了就直接触发模式切换？

**5. 如果是群体对实体的关系**
- 群体的态度变化通过什么渠道传导到实体？
- 实体对这个群体的态度有多敏感？
- 实体是否有能力主动塑造群体的态度？（如通过宣传、政策让利）

---

### 格式转换规则

分析完成后，转换为以下JSON格式：

```json
{
  "relationship_id": "rel-[三位数字]，如 rel-001",
  "scenario_context": "这段关系所属的场景描述（英文）",
  "agent_a": "层级较高或被影响的角色的 agent_id",
  "agent_b": "层级较低或施加影响的角色的 agent_id",
  "affiliation": "共同所属的更大共同体，如 iran、us-government。如无共同体则写 none",

  "relationship_type": "one of: loyalty / influence / alliance / rivalry / dependency",

  "loyalty": {
    "direction": "B → A 表示B服从A，A ← B 表示A受B影响",
    "current_value": "0-100的整数，100为绝对忠诚/影响力",
    "threshold": "0-100的整数，低于此值触发模式切换",
    "current_mode": "one of: loyal / independent",
    "basis": "忠诚/影响力的基础是什么（英文），如 institutional hierarchy / personal relationship / shared interests / fear",
    "description": "当前关系状态的描述（英文，至少20字符）"
  },

  "mode_definitions": {
    "loyal": {
      "description": "在忠诚模式下，这段关系如何运作（英文）",
      "constraint_on_agent_a": "A在做决策时必须避免什么以维持这段关系（英文）"
    },
    "independent": {
      "description": "在独立模式下，双方如何互动（英文）",
      "trigger": "什么条件触发模式切换（英文）",
      "residual_cooperation": "即使独立，双方还有什么共同利益约束行为（英文）"
    }
  },

  "loyalty_modifiers": [
    {
      "event_type": "什么类型的事件（英文）",
      "impact": "整数，正数为增加忠诚度，负数为减少。绝对值5-30之间。",
      "description": "为什么这个事件会影响忠诚度（英文，至少20字符）",
      "could_trigger_switch": "boolean — 这个事件单独是否就能触发模式切换"
    }
  ],

  "source": {
    "type": "system-derived",
    "created_at": "YYYY-MM-DD",
    "scenario_specific": true
  },

  "honesty_boundaries": [
    "这份关系定义做不到什么（英文字符串数组，至少1条）"
  ]
}
```

### 关系类型说明

| 类型 | 适用场景 | 示例 |
|------|---------|------|
| `loyalty` | 同一共同体内的上下级或核心-外围关系 | 伊朗政府 ↔ 革命卫队，特朗普 ↔ 万斯 |
| `influence` | 群体对实体的影响力关系 | MAGA选民 → 特朗普，华尔街 → 美联储 |
| `alliance` | 不同共同体之间的合作关系 | 美国 ↔ 以色列，中国 ↔ 巴基斯坦 |
| `rivalry` | 对手关系 | 美国 ↔ 伊朗，以色列 ↔ 真主党 |
| `dependency` | 单向依赖关系 | 以色列 → 美国（武器供应），伊朗 → 中国（石油出口） |

### 关于忠诚度数值的标定

| 数值范围 | 含义 | 现实对应 |
|---------|------|---------|
| 90-100 | 绝对忠诚/无条件服从 | 极罕见，通常只在危机初期短暂出现 |
| 70-89 | 高度忠诚/基本服从 | 有分歧但服从整体方向 |
| 50-69 | 中等忠诚/有条件服从 | 在某些议题上公开表示不同意见 |
| 30-49 | 低忠诚/勉强维持 | 频繁的公开分歧，接近模式切换 |
| 0-29 | 独立模式/事实上的对抗 | 自行其是，可能暗中破坏对方决策 |

### 自检清单

- [ ] `relationship_id` 格式为 `rel-XXX`？
- [ ] `agent_a` 和 `agent_b` 都是已存在的角色卡的 `agent_id`？
- [ ] `relationship_type` 是五个选项之一？
- [ ] `loyalty.current_value` 和 `loyalty.threshold` 都是0-100的整数？
- [ ] `loyalty.current_mode` 与 `current_value` 和 `threshold` 的数值逻辑一致？（current_value > threshold → loyal；current_value ≤ threshold → independent）
- [ ] `loyalty_modifiers` 至少2个？
- [ ] 每个 `loyalty_modifiers.impact` 的绝对值在5-30之间？
- [ ] `honesty_boundaries` 至少1条？
- [ ] 所有文本是英文？
- [ ] JSON可通过标准解析器验证？

### 输出要求

1. **保存关系定义：** 将生成的JSON保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/relationships/[relationship_id].json`

2. **保存索引文件（论证过程）：** 生成一份 Markdown 索引文件，保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/relationships/[relationship_id].references.md`

索引文件必须包含以下结构：

```markdown
# [Agent A] ↔ [Agent B] — Relationship References

> Evidence chain behind each field in [relationship_id].json.
> For users who want to verify, challenge, or refine the conclusions.

## Source Materials
- [List all references: news reports, official statements, academic analyses, leaked documents, historical records, etc.]

## Subordination / Affiliation — Evidence
- **Common affiliation basis:** [Evidence that both belong to the same larger entity]
- **Hierarchy basis:** [Evidence for the stated power hierarchy between A and B]

## Loyalty Assessment — Evidence
- **Current value justification:** [Why the loyalty is rated at X out of 100]
- **Basis of loyalty:** [Evidence for the stated basis — institutional/personal/shared interests/fear]
- **Known public disagreements:** [Specific instances of friction, with dates and sources]

## Mode Determination — Evidence
- **Current mode justification:** [Why classified as loyal vs independent]
- **Constraint on Agent A:** [Evidence that A must avoid certain actions to maintain B's loyalty]

## Loyalty Modifiers — Evidence Chain
### [Event Type 1]: impact [+/-X]
- **Basis:** [Why this event would change loyalty by this amount]
- **Historical example:** [Past instance where a similar event affected this relationship]
- **Switch risk:** [Why this could/couldn't trigger a mode switch on its own]

(Repeat for each modifier)

## Scenario-Specific Context
- **Current situation:** [How the specific scenario affects this relationship right now]
- **Key uncertainties:** [What we don't know that could change the assessment]
```

3. **不要输出中间解释，直接执行保存。** 如果自检清单有未通过项，先修复再保存。两个文件必须同时生成。
