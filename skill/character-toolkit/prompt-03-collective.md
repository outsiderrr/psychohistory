# 群体角色画像生成提示词

> **适用对象：** 没有单一决策中心的群体——选民群体、市场参与者、社会运动、人口群体等。
> **不适用于：** 个人（用 prompt-01）、有决策中心的组织（用 prompt-02）。
> **判断标准：** 如果你无法指出"谁来拍板"，它就是群体。

---

## 使用方法

将以下内容完整复制，填入目标群体后发送。

---

## 提示词正文

请为以下群体生成一张心理史学群体角色画像。

**目标群体：【在此处填写，例如：MAGA选民 / 全球原油市场参与者 / 伊朗城市中产阶级 / 美国反战运动群体】**

**关联的实体角色：【填写这个群体会影响哪个实体角色的决策，例如：trump / iran-government。如不确定可留空】**

### 调研要求

请从以下五个维度调研该群体。注意：群体没有"心智模型"，它有的是**利益结构**和**情绪分布**。

**1. 群体构成**
- 这个群体的核心人口特征是什么？（年龄、阶层、地域、职业、文化背景）
- 群体规模大约多大？
- 群体内部有没有明显的子群体或分化？

**2. 核心利益**
- 这个群体最关心的3-5个议题是什么？请按优先级排列。
- 每个议题为什么重要？（直接影响生活、意识形态驱动、历史传统、还是经济利益）
- 不同议题之间有没有冲突？（例如"支持战争"和"反对油价上涨"之间的张力）

**3. 当前倾向**
- 在当前最相关的具体议题上，这个群体的总体立场是什么？（支持/反对/中立）
- 这个立场有多坚定？（强烈/中等/脆弱）
- 最近有没有发生过立场的明显变化？

**4. 敏感度映射**
- 什么类型的事件会大幅改变这个群体的倾向？
- 什么类型的事件他们基本不关心？
- 变化是即时的还是有延迟的？（如油价上涨要累积几周才影响政治态度）

**5. 影响力传导**
- 这个群体的态度变化通过什么机制影响到实体决策者？
- 是通过民调数字？选票？市场价格？街头抗议？舆论压力？
- 从群体态度变化到决策者感受到压力，通常有多长的时间延迟？

---

### 格式转换规则

调研完成后，请将结果转换为以下严格的JSON格式：

```json
{
  "card_version": "1.0",
  "agent_id": "小写连字符格式，如 maga-base 或 global-oil-traders",
  "agent_type": "collective",
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
    "estimated_size": "规模估计，如 '~74 million (2024 Trump voters)' 或 'thousands of institutional traders'",
    "internal_segments": [
      {
        "name": "子群体名称",
        "description": "这个子群体的特点",
        "share": "在整体中的大致比例或重要程度"
      }
    ]
  },

  "core_interests": [
    {
      "interest": "利益议题名称（英文）",
      "priority": 1,
      "description": "为什么这个议题对他们重要（英文，至少20字符）",
      "driver": "one of: economic / ideological / security / cultural / historical"
    }
  ],

  "current_disposition": {
    "issue": "当前最相关的具体议题",
    "stance": "one of: support / oppose / neutral / divided",
    "intensity": "one of: strong / medium / weak / fragile",
    "recent_shift": "最近有没有明显的立场变化？如有，描述变化方向和原因。如没有，写 'No significant recent shift'",
    "internal_tension": "群体内部在这个议题上有没有张力？如有，描述张力的性质。"
  },

  "sensitivity_map": [
    {
      "event_type": "什么类型的事件（英文）",
      "sensitivity": "one of: extreme / high / medium / low / negligible",
      "expected_shift": "预期的倾向变化方向和幅度（英文）",
      "time_lag": "从事件发生到态度变化的时间延迟，如 'immediate'、'days'、'weeks'、'months'",
      "description": "为什么这类事件会或不会影响他们（英文，至少20字符）"
    }
  ],

  "influence_pathway": {
    "target_agent": "被影响的实体角色的 agent_id",
    "mechanism": "传导机制描述（英文），如 'approval ratings → Trump scorecard test heuristic'",
    "channel": "one of: polls / votes / market_prices / street_protests / media_pressure / lobbying / other",
    "time_lag": "从群体态度变化到决策者感受到压力的延迟",
    "description": "完整的传导链条描述（英文，至少20字符）"
  },

  "historical_behavior": [
    {
      "event": "历史上什么事件曾大幅改变这个群体的态度",
      "year": "YYYY",
      "shift": "态度发生了什么变化",
      "mechanism": "变化是通过什么机制发生的"
    }
  ],

  "honesty_boundaries": [
    "这张群体画像做不到什么（英文字符串数组，至少1条）"
  ]
}
```

### 关键注意事项

1. **群体卡没有 `mental_models` 和 `decision_heuristics`** — 这是跟实体卡最大的区别。群体没有统一的"思考方式"，只有利益分布和情绪反应。
2. **`sensitivity_map` 是群体卡的核心** — 它替代了实体卡中心智模型的位置。对群体而言，"什么事件会改变他们的态度"比"他们怎么思考"更重要。
3. **`influence_pathway` 必须指向一个具体的实体角色** — 群体的价值在于它对决策者的影响力。如果你不能说清楚它影响谁、怎么影响，这个群体就不值得建模。
4. **`time_lag` 是容易被忽略但极其重要的字段** — 油价上涨不会立刻变成反战情绪，中间可能隔几周。这个延迟对推演的时间节奏至关重要。

### 自检清单

- [ ] `card_version` 是 `"1.0"`？
- [ ] `agent_type` 是 `"collective"`？
- [ ] `agent_id` 是纯小写字母+连字符？
- [ ] `source.data_cutoff` 是完整的 YYYY-MM-DD？
- [ ] `core_interests` 至少2个，每个有 `priority` 排序？
- [ ] `sensitivity_map` 至少2个条目？
- [ ] 每个 `sensitivity_map` 条目有 `time_lag` 字段？
- [ ] `influence_pathway` 指向了一个具体的 `target_agent`？
- [ ] `honesty_boundaries` 至少1条？
- [ ] 没有 `mental_models` 或 `decision_heuristics` 字段？（群体卡不应有这些）
- [ ] 所有文本是英文？
- [ ] JSON可通过标准解析器验证？

### 输出要求

1. **保存群体角色卡：** 将生成的JSON保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/psychohistory/[agent_id].json`

2. **保存索引文件（论证过程）：** 生成一份 Markdown 索引文件，保存到：
   `/Users/outsider/Desktop/psychohistory/skill/characters/psychohistory/[agent_id].references.md`

索引文件必须包含以下结构：

```markdown
# [Collective Name] — Collective Profile References

> Evidence chain behind each field in [agent_id].json.
> For users who want to verify, challenge, or refine the conclusions.

## Source Materials
- [List all references: polling data, demographic studies, media analyses, academic research, etc.]

## Composition — Evidence
- **Demographics basis:** [What data sources define this group's composition]
- **Size estimate basis:** [How the size estimate was derived]
- **Internal segments:** [Evidence for each sub-group's existence]

## Core Interests — Priority Ranking Evidence
### Interest 1: [Name]
- **Priority justification:** [Why this ranks highest]
- **Data sources:** [Polls, economic data, behavioral evidence]

(Repeat for each interest)

## Current Disposition — Evidence
- **Stance basis:** [What polls, protests, market behavior, or other signals support the stated stance]
- **Intensity basis:** [How the intensity level was determined]
- **Recent shift evidence:** [Data showing any recent change, or evidence of stability]

## Sensitivity Map — Evidence Chain
### [Event Type 1]
- **Sensitivity level justification:** [Why rated extreme/high/medium/low]
- **Historical example:** [When did a similar event cause this group to shift?]
- **Time lag basis:** [How the delay estimate was derived]

(Repeat for each sensitivity entry)

## Influence Pathway — Evidence
- **Mechanism basis:** [How we know this group influences the target agent through this channel]
- **Historical example:** [Past instance where this pathway was demonstrated]
- **Time lag basis:** [Evidence for the stated delay]

## Historical Behavior — Detailed Cases
### [Event, Year]
- **What happened:** [The triggering event]
- **Group response:** [How the group's attitude shifted]
- **Transmission:** [How this shift affected decision-makers]
- **Relevance:** [What this tells us about current sensitivity map entries]
```

3. **不要输出中间解释，直接执行保存。** 如果自检清单有未通过项，先修复再保存。两个文件必须同时生成。
