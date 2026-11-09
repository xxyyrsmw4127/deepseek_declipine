# 督学口令 · 直接复制粘贴到 DSH 会话

> 会话工作区 = `D:\deepseek_dsh`，`AGENTS.md` 与 `kaoyan-supervisor` skill 自动生效。
> 每条口令都会先读 `state.yaml`（`macro_sandbox` + `psychoanalytic_profile`）和最近 7 天日志，再按四段式回复：
> **战局态势 → 阻抗解码 → 战略剪枝 → 最小切入点**。

---

## 0. 首次校准（只做一次，5 分钟）

```
校准。读 kaoyan/state/state.yaml 的 macro_sandbox 和 psychoanalytic_profile，向我确认三件事：
① 当前战略阶段与各科风险评级是否还成立；② 精力相位判断（冲刺/平台/冷却）准不准；
③ 有没有已经失效、但我还在用的干预方式。我答完你直接改 state.yaml。
```

## 1. 开工（每天，起床后）

```
开工。读 state.yaml + 最近 7 天 logs，跑 dashboard.ps1，按四段式给我：
① 现在处于进攻/相持/冷却哪一段；② 昨天和前天的阻抗信号；③ 今天砍掉什么、保留什么；
④ 一个零心理负担的启动动作。然后写今日作战单。
```

极简版：`开工`

## 2. 中检（12:00 或 15:30，状态掉了才用）

```
中检。现在 <时间>，做到 <讲次/题号>，卡在 <知识点/走神/疲惫>。
不用安慰，按阻抗解码：这是认知超载、防御性忙碌，还是单纯睡眠不够？然后只给我下一个最小动作。
```

极简版：`中检：卡在第 4 讲特征值`

## 3. 收工复盘（每天 21:30）

```
收工。数据：数学 <分钟> / 408 <分钟> / 英语 <分钟> / 政治 <分钟>；交付 <讲次/题号/正确率>。
按协议 C：写 kaoyan/logs/<今天>.md、更新 state.yaml 进度、同步 psychoanalytic_profile
（精力相位、今天的阻抗点、有效/无效干预），最后跑 dashboard.ps1 确认 +1。
```

极简版：`收工：数学240 408180 英语45 政治30`

## 4. 周复盘（每周日 20:00，或连续 3 天策略失效时）

```
周复盘。跑 dashboard.ps1，用 4 个子代理并行分析四科；汇总后做三件事：
① 更新 macro_sandbox 的风险评级与下周切入点；② 更新 psychoanalytic_profile 的精力周期证据；
③ 漂移检测——[MUTABLE HEURISTICS] 有没有该合并、替换或作废的条目，有就改并输出 [Self-Upgrade Log]。
```

## 5. 抽查（任意时间，一天最多 2 次）

```
抽查我。数学 2 题 + 408 3 题，限时 <分钟数>，我做完你判分并入错题本。
```

极简版：`抽查 408`

## 6. 崩盘急救（连续 0 产出 / 情绪崩了）

```
我崩了。按协议 F：今天只保一条底线，其余全部写进 backlog；不追责、不补欠账、不讲道理。
先判断这是睡眠债、认知超载还是全或无退行，然后只给一个 10 分钟内能完成的动作。
```

## 7. 阶段重排（进入新周期，或偏差 >20%）

```
重排。按协议 G：读当前阶段剩余任务，分「必做 / 可砍 / 延期」，明确砍哪些、里程碑怎么移；
同步改 macro_sandbox 的学科权重与容错阈值，改完输出 [Self-Upgrade Log]。
```

## 8. 状态速查（任何时候）

```
报态势：倒计时、战略阶段、精力相位、四科基准线风险、本周欠账、当前最高边际收益的一件事。
```

## 9. 自检与打补丁（每周或我明确说某句话不好用时）

```
自检。检查最近 7 天的对话与日志：哪类话术让我抵触、哪个切入点连续失效、有没有新的高效启动锚点。
只改 SKILL.md 的 [MUTABLE HEURISTICS]（≤10 条，合并替换）和 agent.cordis.yml 的 persona，
IMMUTABLE CORE 不动；改完输出 [Self-Upgrade Log]。
```

---

## 附：口令与协议、产物的对应关系

| 口令 | 协议 | 产物 |
|---|---|---|
| 校准 | 0 | 更新 `state.yaml` 的 `macro_sandbox` / `psychoanalytic_profile` |
| 开工 | A | 重写 `kaoyan/state/今日作战单.md` |
| 中检 | B | 会话内诊断 + 下一个最小动作 |
| 收工 | C | 新建 `kaoyan/logs/<日期>.md` + 更新 `state.yaml` + 同步画像 + dashboard 校验 |
| 周复盘 | D | 4 子代理分析 + 更新两个新模块 + 漂移检测 / 自升级 |
| 抽查 | E | 判分 + 追加 `kaoyan/mistakes/mistakes.md` |
| 崩盘 | F | 最小底线 + backlog + `flags.mode: degraded` |
| 重排 | G | 改 `kaoyan/plans/百日总作战计划.md` + 调 `macro_sandbox` 权重 |
| 自检 | S | 改 `SKILL.md` [MUTABLE HEURISTICS] + `agent.cordis.yml` persona + `[Self-Upgrade Log]` |
