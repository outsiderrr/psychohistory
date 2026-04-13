# Psychohistory (心理史学)

[English](./README.md) · **中文**

基于复杂系统和多 Agent 行为建模的宏观推演与模拟沙盒。

不同于传统的确定性预测工具，Psychohistory 动态地建模不同实体和群体在物理/经济硬约束下的互动，为未来事件生成多层次的**可能性树（Tree of Possibilities）**。

## 仓库结构（Monorepo）

- `/skill` — **[当前重点]** 核心 Agent 配置、Prompt 链和初始工作流定义
- `/engine` — *（规划中）* 核心多 Agent 编排与模拟逻辑
- `/web` — *（规划中）* 用于渲染动态可能性树的前端界面
- `/docs` — 系统本体论、行为模型和理论基础

## 当前阶段

**第一阶段：** 搭建 Skill 工作流和核心本体论，为后续模拟引擎奠定基础。

## 模块导航

| 模块 | 说明 | 入口 |
|---|---|---|
| `skill/` | 跨平台的 Skill 版本（markdown 指令），是当前可用的完整形态 | [skill/README_CN.md](./skill/README_CN.md) |
| `skill/character-toolkit/` | 角色卡生成工具包（Skill 的子模块） | [skill/character-toolkit/README_CN.md](./skill/character-toolkit/README_CN.md) |
| `engine/` | 模拟引擎（规划中） | — |
| `web/` | Web 可视化前端（规划中） | — |
| `docs/` | 理论基础与本体论文档 | — |
