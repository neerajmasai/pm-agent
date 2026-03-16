---
name: pm-risk
description: >
  Risk and dependency tracking for any GitHub project — identifies at-risk sprint
  items, cross-repo dependencies, and generates stakeholder status updates. Use
  this skill when the user says "risk report", "what's at risk", "blockers",
  "dependencies", "stakeholder update", "status update for leadership",
  "what's blocked", "what might slip", "sprint risks", "cross-repo dependencies",
  or any request to surface problems, generate executive summaries, or identify
  items that need attention. Also trigger for "pm risk", "risk assessment",
  "what needs escalation", or "write a status email".
---

# PM Risk & Dependency Tracking

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules.

### Risk Thresholds
- **Active status without PR**: >3 days → at risk
- **Review-like status**: >2 days → at risk
- **Target date approaching**: within 3 days → at risk
- **Unassigned in sprint**: always flagged

## Workflow

### 1. Fetch Current Sprint Items

Determine current iteration (if iteration field exists), fetch all project items, filter to current iteration. If no iteration field, use all non-done items.

Build the GraphQL query dynamically — only include fields that are non-null in config.

### 2. Check Linked PRs for Active Items

For items in active statuses (middle entries of `statusFlow`), check for PRs:
```bash
gh pr list --repo <repo> --search "<issue-number>" --json number,title,state,url --limit 5
```

### 3. Classify Risk

Determine which statuses are what from `statusFlow`:
- **First** = backlog/todo (not started)
- **Last** = done
- **Second-to-last** = review/QA-like (if 4+ statuses)
- **Middle** = active/in-progress

Flag items matching:
- Active status >3 days + no open/merged PR
- Review-like status >2 days
- Target date within 3 days + not done (only if `targetDate` field exists)
- No assignee on any sprint item

### 4. Cross-Repo Dependencies

Only run when `repos` has 2+ entries.

Scan issue bodies of current sprint items for:
- URLs matching `github.com/<owner>/.*/issues/\d+`
- Text like "depends on #<num>", "blocked by #<num>"

For each dependency found in a different repo, check if it's done. If not, flag it as blocking.

### 5. Present Risk Report

```
## Risk Report — <Iteration Name> (Day X of Y)

### At-Risk Items (N)

**Stale Active Items (no PR, >3 days)**
- <repo>#<num> <title> — @<assignee> — <days> days, no PR
  → Check with assignee on progress

**Stuck in Review (>2 days)**
- <repo>#<num> <title> — @<assignee> — PR #<n> open <days> days
  → Ping reviewer or reassign

**Approaching Deadline**
(only if targetDate field exists)
- <repo>#<num> <title> — due <date> (<days> days), status: <status>
  → Prioritize or adjust deadline

**Unassigned**
- <repo>#<num> <title> — in sprint, no assignee
  → Assign to team member

### Cross-Repo Dependencies (N)
(only if multiple repos)
- <repo1>#<num> depends on <repo2>#<num> (<status>)

### Stakeholder Update
(copy-paste ready)

---
**Sprint: <Iteration Name> — Day X/Y**
- Progress: N/M done (X%)
- Key wins: <completed items this week>
- Risks: <summary of flagged items>
- Shipping next: <items in review/QA>
---
```

## Error Handling
- No active sprint → "No active sprint — run `/pm-sprint start`"
- No risks found → "Sprint is on track — no at-risk items found."
- Single repo → skip cross-repo dependency section
- Config missing → `/pm-setup`
