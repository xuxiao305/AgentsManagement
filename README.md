# Agent Repo

这个仓库用于集中管理和迭代个人 agent 资产，当前以 `C:\Users\xuxiao02\.claude\agents` 为主要运行目录，并为 VS Code 相关自定义预留扩展空间。

## 目标

- 把 agent 定义当作长期可迭代资产纳入 Git 管理。
- 让仓库成为唯一源，运行目录通过脚本同步生成。
- 为后续纳入 prompts、instructions、skills 等配置资产预留统一结构。

## 目录结构

```text
agent-repo/
├── claude/
│   └── agents/                # Claude 运行时 agent 定义的唯一源
├── vscode/
│   ├── prompts/               # VS Code 用户级 prompts 预留目录
│   └── instructions/          # VS Code 用户级 instructions 预留目录
├── skills/                    # 通用技能或说明资产预留目录
├── scripts/
│   └── sync-agent-assets.ps1  # 同步仓库资产到运行目录
└── .gitignore
```

## 当前同步策略

- `claude/agents/*` 同步到 `C:\Users\xuxiao02\.claude\agents\`
- `vscode/prompts/*` 同步到 `C:\Users\xuxiao02\AppData\Roaming\Code\User\prompts\`
- `vscode/instructions/*` 同步到 `C:\Users\xuxiao02\AppData\Roaming\Code\User\instructions\`

默认只覆盖同名文件，不主动删除运行目录里多余文件；如果需要清理陈旧文件，可使用 `-RemoveStale`。

## 单向修改约定

- 所有 agent 资产修改必须先在仓库中完成，再同步到用户级运行目录。
- 用户级运行目录视为发布目标，不作为日常编辑入口。
- 如果发现用户级文件和仓库文件不一致，应先以仓库为基准进行核对，再决定是否回收用户级改动，避免两边同时修改后被覆盖导致数据丢失。
- 推荐流程是：先修改仓库，再执行同步脚本，最后做运行目录验证。

## 团队盘点约定

当用户要求“盘点一下团队情况”或“检查一下团队情况”时，默认至少检查以下内容：

- 当前 agent 是否已经纳入仓库管理。
- 仓库工作区是否存在未提交改动。
- 仓库定义与用户级运行目录是否已经同步。
- 如果已经配置远端仓库，当前本地分支是否已推送。

## 使用方式

初始化或每次修改后执行：

```powershell
pwsh -File .\scripts\sync-agent-assets.ps1
```

预览将发生什么变化：

```powershell
pwsh -File .\scripts\sync-agent-assets.ps1 -WhatIf
```

同步并清理运行目录中的陈旧文件：

```powershell
pwsh -File .\scripts\sync-agent-assets.ps1 -RemoveStale
```

盘点当前 agent 资产状态：

```powershell
pwsh -File .\scripts\audit-agent-assets.ps1
```

## 建议工作流

1. 在仓库里编辑 agent 定义和相关配置。
2. 运行同步脚本，把仓库内容推送到实际生效目录。
3. 验证 agent 行为。
4. 用 Git 记录每次调整，按主题提交。

## 后续可扩展项

- 增加 `CHANGELOG.md` 记录关键 agent 行为变化。
- 为常见 agent 增加回归检查清单。
- 为 prompts、instructions、skills 增加模板和命名约定。