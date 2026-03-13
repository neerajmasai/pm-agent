---
name: pm-risk
description: >
  Risk and dependency tracking for Presto Player — identifies at-risk sprint
  items, cross-repo dependencies, and generates stakeholder status updates.
---

# PM Risk & Dependency Tracking

## Context

- **Org**: prestomade
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`

### Risk Thresholds
- **In Progress without PR**: >3 days = at risk
- **In Review**: >2 days = at risk
- **Target date approaching**: within 3 days = at risk
- **Unassigned in sprint**: always flagged

## On Trigger

Run all three analyses and present results:

### 1. Fetch current sprint items

Determine current iteration (see iteration query pattern from other skills), then fetch all project items and filter to current iteration.

```bash
gh api graphql --paginate -f query='
query($endCursor: String) {
  organization(login: "prestomade") {
    projectV2(number: 5) {
      items(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          status: fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          team: fieldValueByName(name: "Team") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          iteration: fieldValueByName(name: "Iteration") {
            ... on ProjectV2ItemFieldIterationValue { title startDate duration }
          }
          targetDate: fieldValueByName(name: "Target date") {
            ... on ProjectV2ItemFieldDateValue { date }
          }
          content {
            ... on Issue {
              number title url createdAt state body
              repository { name }
              assignees(first: 5) { nodes { login } }
              labels(first: 10) { nodes { name } }
            }
          }
        }
      }
    }
  }
}'
```

### 2. Check for linked PRs on at-risk items

For items "In Progress" or "In Review", check for PRs:
```bash
gh pr list --repo prestomade/<repo> --search "<issue-number>" --json number,title,state,url --limit 5
```

### 3. Analyze at-risk items

Flag items matching risk criteria:
- "In Progress" >3 days and no linked open/merged PR
- "In Review" >2 days
- Target date within 3 days and status != Done
- No assignee

### 4. Detect cross-repo dependencies

Scan issue bodies of current sprint items for:
- URLs matching `github.com/prestomade/(presto-player|presto-player-pro)/issues/\d+`
- Explicit text like "depends on #<num> in presto-player"

For each dependency found, check if the referenced issue is Done. If not, flag it.

### 5. Display risk report

```
## Risk Report — <Iteration Name> (Day X of Y)

### At-Risk Items (N)

**Stale In Progress (no PR, >3 days)**
- #<num> <title> — @<assignee> (<team>) — <days> days, no PR
  Action: Check with assignee on progress

**Stuck In Review (>2 days)**
- #<num> <title> — @<assignee> — PR #<n> open <days> days
  Action: Ping reviewer or reassign

**Approaching Deadline**
- #<num> <title> — target: <date> (<days> days away), status: <status>
  Action: Prioritize or adjust deadline

**Unassigned**
- #<num> <title> — in sprint but no assignee
  Action: Assign to a squad member

### Cross-Repo Dependencies (N)

- presto-player-pro #<num> depends on presto-player #<num> (<status>)
  Blocking: dependency not yet Done

### Stakeholder Update

Copy-paste ready update:

---
**Sprint: <Iteration Name> — Day X/Y**
- Progress: N/M items done (X%)
- Key wins: <list completed items this week>
- Risks: <N items at risk — summarize>
- Shipping next: <items in QA or Review>
---
```

## Error Handling
- No current sprint: "No active sprint. Run `/pm-sprint start` to begin one."
- No at-risk items: "No at-risk items found. Sprint is on track!"
- No cross-repo dependencies: "No cross-repo dependencies detected in current sprint items."
