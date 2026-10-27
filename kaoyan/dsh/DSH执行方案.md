# DSH 督学执行方案

> 目标：让 DeepSeek Harness 成为一个**每天会自动进入状态、只认数据、会落盘、会重排**的督学系统。
> 本文只讲「怎么跑」，学科内容在 `kaoyan/plans/百日总作战计划.md`。

---

## 1. 系统组成（已全部落地）

| 组件 | 路径 | 依赖的 DSH 机制 | 作用 |
|---|---|---|---|
| 督学宪法 | `AGENTS.md`（工作区根） | 项目级 `AGENTS.md` 自动注入 | 每次新会话第一件事就是加载督学身份与铁律 |
| 督学协议 | `.dsh/skills/kaoyan-supervisor/SKILL.md` | `.dsh/skills/` 本地 skill 发现 | 六套可执行流程（A 开工 / B 中检 / C 收工 / D 周复盘 / E 抽查 / F 崩盘 / G 重排） |
| 事实来源 | `kaoyan/state/state.yaml` | 文件即记忆 | 倒计时、阶段、KPI、进度、欠账、streak、模式 |
| 每日作战单 | `kaoyan/state/今日作战单.md` | 文件即记忆 | 每天覆盖重写的时间盒 |
| 路线图 | `kaoyan/plans/百日总作战计划.md` | 文件即记忆 | 四阶段 + 里程碑 M1-M8 + 各科打法 |
| 学习日志 | `kaoyan/logs/<日期>.md` | 文件即记忆 | 机器可读块（`key=value`），供看板统计 |
| 错题本 | `kaoyan/mistakes/mistakes.md` | 文件即记忆 | 抽查与复盘产物，按错因分类 |
| 口令集 | `kaoyan/prompts.md` | — | 直接复制的触发语 |
| 看板 | `kaoyan/tools/dashboard.ps1` + `dashboard.cmd` | pwsh 工具 | 倒计时 / streak / 近 N 日时长 / 里程碑 |
| 可选预设 | `kaoyan/dsh/preset/kaoyan-supervisor/` | `$DSH_HOME/.agent-presets` 用户预设根 | 在 GUI 里出现「考研督学」一级模式 |

**已经验证生效**（本会话实测）：写入 `AGENTS.md` 后立刻被系统作为 workspace instructions 注入；`kaoyan-supervisor` 立刻出现在会话的 skill 目录里。也就是说**不需要重启、不需要改配置**，这套东西现在就在生效。

---

## 2. 为什么把状态放文件里，而不是靠一个超长会话

DSH 的会话是无状态推导（历史 + 压缩）。一个聊 82 天的会话会被 compaction 反复裁剪，细节必然丢失。
所以：**跨天记忆放文件（`state.yaml` / `logs/` / `mistakes.md`），会话只是执行器。**
每天开新会话 → `AGENTS.md` 自动注入 → 第一条指令就是「读 state.yaml 报到」。

---

## 3. 日常执行回路

| 时间 | 你说 | Agent 做 | 落盘产物 |
|---|---|---|---|
| 08:00 | `开工` | 协议 A：读状态 → 跑看板 → 生成时间盒作战单 | 覆盖 `kaoyan/state/今日作战单.md` |
| 12:00 / 15:30 | `中检：...` | 协议 B：算偏差 → 砍任务或加压力（可选起番茄钟后台任务） | 无（会话内） |
| 21:30 | `收工：数学240 408180 英语45 政治30` | 协议 C：逼出数据 → 写日志 → 更新状态 → 抽查 3-5 题 | 新建 `logs/<日期>.md`、改 `state.yaml`、追加 `mistakes.md` |
| 周日 20:00 | `周复盘` | 协议 D：4 个子代理分科分析 → 汇总偏差表 → 下周作战单 | 改 `state.yaml`，必要时重排计划 |
| 任意 | `抽查我` | 协议 E：出题 → 判分 → 入错题本 | 追加 `mistakes.md` |
| 崩了 | `我崩了` | 协议 F：保底线 + 砍任务 + `backlog` | 改 `state.yaml` 的 `flags.mode` |
| 落后 >20% | `重新排计划` | 协议 G：只砍范围不砍时长 | 改写计划文件 + 里程碑顺延 |

**唯一的"人肉接口"**：你必须每天打开会话说「开工」。DSH 不会主动叫你起床（原因见第 6 节）。

---

## 4. 会话怎么组织（三选一，推荐 A）

**A. 每天新会话（推荐）**
新建会话 → 宪法自动注入 → 说「开工」。上下文干净、token 便宜、不会因为压缩丢状态。
代价：没有跨天聊天记忆（但状态在文件里，这正是我们要的）。

**B. 单会话长跑**
优点：连续性好。缺点：上下文膨胀、后期每次请求都贵、压缩后容易忘记早期的约束。
若选 B：每天开工时也要求它重新 `read kaoyan/state/state.yaml`，不要依赖记忆。

**C. 会话 + Goal（当天任务重时用）**
开工时让 agent `create_goal("今日最低交付：数学180min + 408180min + 英语1篇阅读")`，
它会在这一个会话里自主多轮推进，收工时 `complete`。
注意：Goal 是**同一会话内**的完成目标，不是跨天记忆；跨天记忆仍然只认文件。

---

## 5. DSH 原生自动化（能自动的部分）

### 5.1 番茄钟 / 限时提醒（已验证可用）
让 agent 起一个后台任务：
```powershell
Start-Sleep -Seconds 2700; Write-Output "番茄钟结束：45 分钟到，报本段产出"
```
（用 `pwsh` 工具 + `run_in_background: true`）
任务结束时 DSH 会通知 agent，agent 再转达你 → 实现"45 分钟一检"。
**边界**：只在会话存活时有效；不要用它做跨天闹钟。

### 5.2 定时提醒 Schedule（可选，需启用 overlay）
当前 profile **没有**启用 Schedule（`ui-schedule` 在 web 组合里是 `disabled: true`，host 的 `@deepseek-ai/dsh-schedule` 行未被插入）。
启用方式：编辑 `C:\Users\asus\.dsh\profiles\web\cordis.patch.yml`（当前是空数组 `[]`），改为：

```yaml
# 需要写 ~/.dsh，属于工作区外，DSH 会先向你申请权限
- insert:
    - id: schedule
      name: '@deepseek-ai/dsh-schedule'
    - id: time-context
      name: '@deepseek-ai/dsh-time-context'
- id: ui-schedule
  disabled: false
```
然后重启 `dsh web`，在会话里说「每小时提醒我汇报一次」。
**说明**：上面的覆写模板**未在本机验证**（本会话沙箱不能写 `~/.dsh`）。
验证方法：普通终端执行 `dsh --profile web --dump-config` 看组合树里是否出现 `schedule` 行。
**边界**：Schedule 只在会话存活时投递；不是邮件/推送/日历；重复提醒只能是固定间隔（≥5 分钟），不支持 cron。
→ 如果你要"每天 08:00 开工提醒"，更可靠的做法是用 Windows 计划任务打开 `http://127.0.0.1:3080` 并复制一句「开工」。

### 5.3 周复盘并行子代理（已验证可用）
协议 D 会让 agent 同时发起 4 个 `subagent`（数学 / 408 / 英语 / 政治），每个读近 7 天日志做偏差分析，再汇总。这是把"一周复盘"从 40 分钟压到 5 分钟的关键。

### 5.4 大规模重排 workflow（可选）
当需要"重排整个阶段 + 让每科各自出一份新计划"时，用 `workflow` 扇出：每科一个 agent 读计划与日志 → 输出砍/留决策 → 主脚本合成。适用于阶段末（10/25、11/22、12/12）。

### 5.5 把「考研督学」做成 GUI 一级预设（可选）
DSH 的用户预设根是 `C:\Users\asus\.dsh\.agent-presets`（`agent-presets` 行 `includeUserRoot` 默认开启）。
预设文件已备好：`kaoyan/dsh/preset/kaoyan-supervisor/`（`preset.yml` + 改过 persona 的 `agent.cordis.yml`）。

安装（需要写工作区外目录，DSH 会在你批准后执行，或你自己在终端跑）：
```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.dsh\.agent-presets" | Out-Null
Copy-Item -Recurse -Force "D:\deepseek_dsh\kaoyan\dsh\preset\kaoyan-supervisor" "$env:USERPROFILE\.dsh\.agent-presets\"
```
重启 `dsh web` → 新建会话时预设选择器里出现「考研督学」。
**边界**：会话一旦产生过任何消息就不能再切预设；改预设文件后，只有新会话生效。

### 5.6 把 skill 装到全局（可选）
```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.dsh\skills" | Out-Null
Copy-Item -Recurse -Force "D:\deepseek_dsh\.dsh\skills\kaoyan-supervisor" "$env:USERPROFILE\.dsh\skills\"
```
之后**任何**工作区都能调用该 skill（但督学宪法只在 `D:\deepseek_dsh` 生效）。

---

## 6. 已知边界（诚实清单）

1. **没有系统级推送**：会话不跑 = 没有提醒。DSH 的 Schedule 也只在会话存活时投递。
2. **每天必须有人肉握手**：08:00 打开会话说「开工」。这一步没有任何技术手段能替你完成。
3. **状态滞后风险**：`state.yaml` 由 agent 写。若某天没收工，状态就停在昨天 → 每晚检查 `kaoyan/logs/` 是否有当天文件。
4. **脚本执行策略**：本机 PowerShell 执行策略为 Restricted（脚本文件默认被拒）。
   `dashboard.ps1` 已按 UTF-8 **带 BOM** 保存，且必须用 `-ExecutionPolicy Bypass` 运行：
   ```
   kaoyan\tools\dashboard.cmd            # 推荐，已封装
   powershell -NoProfile -ExecutionPolicy Bypass -File kaoyan\tools\dashboard.ps1
   ```
   直接 `& .\dashboard.ps1` 会报 `running scripts is disabled`，这是策略问题不是脚本问题。
5. **沙箱**：当前文件策略 `workspace-write`，只能改 `D:\deepseek_dsh`；写 `~/.dsh`（5.2 / 5.5 / 5.6）需要你批准。
6. **零虚构原则**：日志与错题本只写真实发生的事。**不要**为了让看板好看而补写日志 —— 那会让整套监督失效。

---

## 7. 验收清单（确认系统在跑）

- [ ] **新建会话**，问「现在 D-几？」→ 应自动读 `state.yaml` 给出 D-xx 与阶段（不依赖上一个会话）
- [ ] 输入 `开工` → `kaoyan/state/今日作战单.md` 被改写为今天
- [ ] 输入 `收工：数学240 408180 英语60 政治0` → 生成 `kaoyan/logs/<今天>.md` 并更新 `state.yaml`
- [ ] 运行 `kaoyan\tools\dashboard.cmd` → 输出今日各科达标情况与睡眠行
- [ ] 输入 `抽查我` → **从你自己的习题 / 错题本里抽 1-2 题**（≤5 min），判分写入 `mistakes.md`
- [ ] （可选）装好预设后，新建会话能在预设里选到「考研督学」

---

## 8. 上下文预算与会话生命周期（怎么保证 80 天不崩）

**核心事实：会话无状态，状态在文件里。** 所以"聊久了上下文会满"不是系统风险 —— 只要按下面的规则开会话。

### 8.1 单次会话的真实成本（2026-09-29 实测文件体积）

| 内容 | 体积 | 何时进入上下文 |
|---|---|---|
| `AGENTS.md` | 7.0 KB | **每次新会话自动注入**（不可省，也不该省） |
| `state.yaml` | 13.1 KB | 开场读一次（唯一事实来源） |
| `今日作战单.md` | 2.3 KB | 开场读一次 |
| 昨天的日志 | ≈3.5 KB | 开场读一次 |
| `SKILL.md` | 12.2 KB | **仅在该会话真正执行某个协议时按需加载** |
| `百日总作战计划.md` | **27.1 KB** | ⚠️ **只读当前阶段那一节（约 3-4 KB），禁止全文读** |

→ 一个干净会话的固定开销 ≈ **26 KB（约 9 千汉字 ≈ 1-1.5 万 token）**；之后每天的对话增量通常 1-3 万 token。
→ 推算：单会话可连续用 **3-5 天**才接近压缩边缘，但**没有必要**——因为文件才是记忆。

### 8.2 三条硬规则

1. **一天一会话（最重要）**：每天开新会话说「开工」。跨天记忆不靠聊天记录，靠文件。**不要把 80 天塞进一个会话** —— 压缩会丢细节，且越到后期越贵。
2. **不读全文，只读需要的段落**：计划只读当前阶段；历史日志用 `grep` 按日期/关键词查（例：找出所有 `math_min` < 180 的日子），不要每天把 `logs/` 全读一遍。
3. **大分析走子代理**：周复盘（协议 D）用 4 个 subagent 分科读日志，**只把偏差表摘要回主会话** —— 原始日志不进主上下文。这是省上下文最有效的一招。

### 8.3 什么时候该放弃当前会话

出现任一条就落盘后另开会话：
- 上下文超过 ~60%
- 开始"记不住"前面报过的数字（已在压缩边缘）
- 话题从"督学"漂移成"闲聊"（闲聊最占上下文且零收益）

### 8.4 三条固定开场语

| 场景 | 一句话 | 读入 |
|---|---|---|
| 日常督学 | `开工` | 宪法 + `state.yaml` + 作战单 + 昨天日志 |
| 只看态势 | `态势` | 宪法 + `state.yaml` + 看板（不读计划与日志） |
| 改制度 / 重排 | `系统维护：<要改什么>` | 宪法 + 对应文件 |

> 本次会话之所以到 35%，是因为它同时承担了**系统搭建**（建 14 个文件、多次联网取数、读整份计划与多个包的 README）。日常督学会话的消耗约为它的 1/5。**明天请开新会话。**

### 8.5 会话所有权（防互相覆盖）

可能同时存在两类会话，**文件所有权必须分清**，否则互相覆盖：

| 会话类型 | 拥有（可覆盖） | 只读（禁止改） |
|---|---|---|
| **日常督学会话**（每天新建，说「开工」） | `logs/<日期>.md`、`state.yaml`、`今日作战单.md`、`mistakes.md` | `AGENTS.md`、`SKILL.md`、`plans/`、`tools/` |
| **系统维护会话**（长期保留，说「系统维护：…」） | `AGENTS.md`、`SKILL.md`、`plans/`、`tools/`、`dsh/` | 当天的 `今日作战单.md` 与当天 `logs/` |

- 维护会话**不许改当天的作战单** —— 那是日常会话的现场台账，覆盖一次就等于把它当天排的计划清掉。
- 两边都要写 `state.yaml` 时：**以日常会话为准**，维护会话只追加字段、不改写已有数值。
- 判断本会话身份：开场先看今天有没有 `logs/<今天>.md`；有 → 日常会话在跑，本会话按**维护会话**行事。
- 同日两会话并行时，**不要在两边同时讨论同一件事**（会产生两份互相矛盾的口头结论，而文件只留一份）。
