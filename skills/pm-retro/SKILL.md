---
name: pm-retro
description: >
  Sprint retrospective for Presto Player — completion stats, carried-over items,
  scope creep detection, per-squad breakdown, and cross-repo split for any
  completed iteration.
---

# PM Sprint Retrospective

## Context

- **Org**: prestomade
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`
- **Scope creep heuristic**: items whose `createdAt` > sprint `startDate`

## On Trigger

If the user provides an iteration name, use that. Otherwise, default to the **last completed iteration**.

### 1. Determine which iteration to review

```bash
gh api graphql -f query='
{
  organization(login: "prestomade") {
    projectV2(number: 5) {
      field(name: "Iteration") {
        ... on ProjectV2IterationField {
          configuration {
            iterations { id title startDate duration }
            completedIterations { id title startDate duration }
          }
        }
      }
    }
  }
}'
```

Select the most recent `completedIterations` entry (or match by name if user specified).

### 2. Fetch all items in that iteration

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
          content {
            ... on Issue {
              number title url createdAt closedAt state
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

Filter to items where iteration title matches the target iteration.

### 3. Generate retrospective report

Categorize items:
- **Completed**: status = "Done"
- **Carried Over**: status != "Done" (still in progress, todo, review, QA)
- **Scope Creep**: issue `createdAt` > sprint `startDate` (added mid-sprint)

Display:
```
## Retrospective: <Iteration Name> (<start date> - <end date>)

### Completed (N items)
**Squad 1 (N)**
- #<num> <title> — @<assignee> (<repo>)

**Squad 2 (N)**
- #<num> <title> — @<assignee> (<repo>)

**Squad 3 (N)**
- #<num> <title> — @<assignee> (<repo>)

**No Team (N)**
- #<num> <title> — @<assignee> (<repo>)

### Carried Over (N items)
- #<num> <title> — @<assignee> — was: <status>
  Reason: <still in progress / blocked / moved to review late>

### Scope Creep (N items added mid-sprint)
- #<num> <title> — created <date> (sprint started <start date>)

### Metrics
| Metric | Value |
|---|---|
| Total Items | N |
| Completed | N (X%) |
| Carried Over | N |
| Scope Creep | N items added mid-sprint |
| Squad 1 | N completed / N total |
| Squad 2 | N completed / N total |
| Squad 3 | N completed / N total |
| Cross-repo | N free / N pro |
```

## Error Handling
- No completed iterations: "No completed iterations found. The first iteration hasn't ended yet."
- Iteration name not found: show available iterations and ask user to pick one
