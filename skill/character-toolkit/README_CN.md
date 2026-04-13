# 心理史学 · 角色卡生成工具包（总索引）

[English](./README.md) · **中文**

> 本工具包包含生成心理史学所有类型角色卡的标准提示词。
> 根据你要生成的角色类型，选择对应的提示词文件。

---

## 角色类型路由

```
你要生成什么？
│
├── 一个具体的人物？（特朗普、内塔尼亚胡、鲍威尔）
│   └── 👉 使用 prompt-01-personal-entity.md（调用女娲skill）
│
├── 一个组织/机构？（美联储、革命卫队、苹果公司、伊朗政府）
│   └── 👉 使用 prompt-02-org-entity.md
│
├── 一个群体？（MAGA选民、美股投资者、伊朗民众）
│   └── 👉 使用 prompt-03-collective.md
│
└── 角色之间的关系？（特朗普与万斯、伊朗政府与革命卫队）
    └── 👉 使用 prompt-04-relationship.md
```

---

## 文件清单

| 文件 | 用途 | 输出格式 |
|------|------|---------|
| `prompt-01-personal-entity.md` | 个人实体角色卡（调用女娲skill） | `[agent_id].json` |
| `prompt-02-org-entity.md` | 组织实体角色卡（政府/公司/军事组织） | `[agent_id].json` |
| `prompt-03-collective.md` | 群体角色画像 | `[agent_id].json` |
| `prompt-04-relationship.md` | 角色间关系定义 | `[rel_id].json` |

---

## 通用规则

以下规则适用于所有类型的角色卡：

1. **所有JSON必须通过标准解析器验证** — 不允许有语法错误
2. **所有文本内容使用英文** — name、description等字段一律英文
3. **日期格式一律 YYYY-MM-DD** — 不接受不完整日期
4. **agent_id 一律小写字母+连字符** — 如 `us-federal-reserve`、`maga-base`
5. **每张卡必须有 honesty_boundaries** — 明确说明这张卡做不到什么

---

## 保存路径

| 类型 | 路径 |
|------|------|
| 女娲原始数据 | `characters/nuwa/[agent_id].md` |
| 个人实体JSON | `characters/psychohistory/[agent_id].json` |
| 组织实体JSON | `characters/psychohistory/[agent_id].json` |
| 群体角色JSON | `characters/psychohistory/[agent_id].json` |
| 关系定义JSON | `characters/relationships/[rel_id].json` |
| 索引文件（论证过程） | 与对应JSON同目录，后缀为 `.references.md` |

每张角色卡和每份关系定义都必须同时生成一份索引文件（`.references.md`），记录每个结论的证据链条。索引文件是给需要验证或修改结论的用户看的，不影响引擎运行。

---

## 快速判断：这个角色是实体还是群体？

问自己一个问题：**这个角色有没有一个"最终拍板人"？**

- 有 → 实体（entity）。即使组织很大，只要有一个人或一个小班子能拍板，就是实体。
- 没有 → 群体（collective）。没有人能代表整体做出决定，行为是统计性的涌现结果。

**灰色地带怎么办？**

有些角色介于两者之间，比如"伊朗最高安全委员会"——它有集体决策机制但没有单一独裁者。这种情况下建议按**组织实体**建模，但在卡片中特别标注内部决策机制的特殊性。
