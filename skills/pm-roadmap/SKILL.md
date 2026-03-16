---
name: pm-roadmap
description: >
  Roadmap and release planning for any GitHub project — view items by quarter,
  generate release plans with changelogs, and track milestone progress. Use this
  skill when the user says "roadmap", "release plan", "what's shipping",
  "changelog", "milestone progress", "quarterly view", "what's planned for Q2",
  "release notes", "what's ready to ship", "draft changelog", "release
  candidate", "what's in the next release", or any request for long-term planning,
  release preparation, or milestone tracking. Also trigger for "pm roadmap",
  "upcoming releases", "version planning", or "epic progress".
---

# PM Roadmap & Release Planning

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules.

## On Trigger

Ask or infer:
> What would you like to see?
> 1. **Roadmap** — items grouped by quarter with progress
> 2. **Release plan** — what's ready to ship + draft changelog
> 3. **Milestones** — progress by epic/milestone

## Workflow: Roadmap View

If no `quarter` field in config:
> No Quarter/Roadmap field found. Showing items grouped by iteration instead (or ungrouped if no iteration field either).

Query items with quarter and status fields. Group by quarter, show progress per quarter with target date warnings.

## Workflow: Release Plan

### 1. Get last release per repo

```bash
gh api repos/<repo>/releases/latest --jq '.tag_name + " " + .published_at' 2>/dev/null || echo "No releases"
```

### 2. Find done items since last release

Filter project items where status = done and issue `closedAt` > last release date.

### 3. Present release plan

Categorize by labels:
- Look for labels containing "enhancement", "feature" → **Features**
- "bug" → **Bug Fixes**
- "security" → **Security**
- Everything else → **Other**

```
## Release Plan

### <repo> (last: <version>, <date>)

**Ready to Ship (N)**
Features: ...
Bug Fixes: ...
Security: ...

**Blockers** (not yet done)
- <repo>#<num> <status>: <title>

### Draft Changelog
#### <repo> vX.X.X
**Features**
- <title> (#<num>)
**Bug Fixes**
- <title> (#<num>)
```

## Workflow: Milestones

Group items by label prefix (`epic: <name>`) or by label category. Show progress bars.

```
### <Name> (N items)
████████░░ X% (N/M done)
- Done: #101, #102
- Active: #106
- Todo: #107
```

## Error Handling
- No releases → show all done items
- No quarter field → group by iteration or show flat
- Config missing → `/pm-setup`
