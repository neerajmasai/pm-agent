---
name: pm-retro
description: >
  Sprint retrospective for any GitHub project — completion stats, carried-over
  items, scope creep detection, per-team breakdown, and cross-repo split. Use
  this skill when the user says "retro", "retrospective", "sprint review",
  "how did the sprint go", "sprint summary", "post-mortem", "sprint wrap-up",
  "what got done last sprint", "sprint completion", "review last iteration",
  or any request to analyze a completed sprint's performance. Also trigger for
  "pm retro", "sprint report", "end of sprint review", or "what carried over".
---

# PM Sprint Retrospective

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules.

If no `iteration` field:
> Retrospectives require an Iteration field. Add one in project settings and run `/pm-setup`.

## On Trigger

If the user names a specific iteration, use that. Otherwise, default to the **most recently completed iteration**.

### 1. Query Iterations

Fetch iteration config. Select target from `completedIterations` (most recent, or matching user's name).

### 2. Fetch Items for That Iteration

Query all project items, filter to those where iteration title matches the target.

### 3. Generate Report

Categorize:
- **Completed**: status = last entry in `statusFlow`
- **Carried Over**: status != done
- **Scope Creep**: issue `createdAt` > iteration `startDate`

```
## Retrospective: <Iteration Name> (<start> – <end>)

### Completed (N)
(grouped by team if team field exists)
**<Team> (N)**
- <repo>#<num> <title> — @<assignee>

### Carried Over (N)
- <repo>#<num> <title> — @<assignee> — was: <status>

### Scope Creep (N added mid-sprint)
- <repo>#<num> <title> — created <date> (sprint started <start>)

### Metrics
| Metric | Value |
|---|---|
| Total | N |
| Completed | N (X%) |
| Carried Over | N |
| Scope Creep | N |
| <Team> | N/N completed |
| Cross-repo | N <repo1> / N <repo2> |
```

Team rows only if team field exists. Cross-repo only if multiple repos.

## Error Handling
- No iteration field → explain
- No completed iterations → "First iteration hasn't ended yet"
- Name not found → show available iterations
- Config missing → `/pm-setup`
