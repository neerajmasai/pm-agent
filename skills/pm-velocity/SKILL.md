---
name: pm-velocity
description: >
  Velocity metrics and team reporting for any GitHub project — completion rates
  across sprints, per-team velocity trends, individual workload, scope creep
  tracking, and cross-repo split. Use this skill when the user says "velocity",
  "metrics", "team performance", "sprint stats", "how fast are we going",
  "completion rate", "burndown", "scope creep", "workload", "capacity",
  "throughput", "how many items did we finish", "team report", or any request
  for historical sprint data, productivity trends, or team workload analysis.
  Also trigger for "pm velocity", "sprint metrics", "performance report", or
  "are we improving".
---

# PM Velocity & Metrics

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules.

If no `iteration` field:
> Velocity tracking requires an Iteration field to measure sprint-over-sprint trends. Add one in project settings and run `/pm-setup`.

## Workflow

### 1. Fetch All Iterations and Items

Query iteration config to get completed + current iterations. Then fetch all project items with status, team (if exists), iteration, and content fields.

### 2. Compute Metrics Per Iteration

For each iteration:
- **Planned**: total items assigned to that iteration
- **Completed**: items where status = last entry in `statusFlow`
- **Per Team**: completed grouped by team (if team field exists)
- **Per Repo**: completed grouped by repo (if multiple repos)
- **Scope Creep**: items where `createdAt` > iteration `startDate` (added mid-sprint)

### 3. Display Report

```
## Velocity Report

### Sprint Velocity Trend
| Sprint | Dates | Planned | Done | Rate | <Team columns if applicable> |
|--------|-------|---------|------|------|-----|
| <name> | <dates> | N | N | X% | ... |

*Current sprint in progress

### Team Workload — Current Sprint: <name>
(only if team field exists)
| Team | Total | <each status> |
|------|-------|------|
| <team> | N | ... |

### Individual Workload
| Assignee | Items | Done | Active |
|----------|-------|------|--------|
| @dev | N | N | N |
| Unassigned | N | N | N |

### Scope Creep Trend
| Sprint | Originally Planned | Added Mid-Sprint | Creep % |
|--------|-------------------|------------------|---------|

### Cross-Repo Split
(only if multiple repos)
| Sprint | <repo1> | <repo2> |
|--------|---------|---------|
```

## Error Handling
- No iteration field → explain that velocity needs iterations
- No completed iterations → "Complete at least one sprint to see trends"
- One iteration → show data, note "Need 2+ sprints for trend analysis"
- No team field → skip team columns
- Single repo → skip cross-repo split
