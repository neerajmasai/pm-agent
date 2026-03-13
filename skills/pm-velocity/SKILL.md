---
name: pm-velocity
description: >
  Velocity metrics and team reporting for Presto Player — completion rates
  across sprints, per-squad velocity trends, team workload, scope creep
  tracking, and cross-repo split.
---

# PM Velocity & Metrics

## Context

- **Org**: prestomade
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`
- **Teams**: Squad 1, Squad 2, Squad 3
- **Capacity**: MVP uses raw item count (no story points)
- **Scope creep heuristic**: items whose `createdAt` > sprint `startDate`

## Workflow

### 1. Fetch iteration config

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

Collect all completed iterations + the current iteration.

### 2. Fetch all project items

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
            ... on ProjectV2ItemFieldIterationValue { title startDate }
          }
          content {
            ... on Issue {
              number title createdAt state
              repository { name }
              assignees(first: 5) { nodes { login } }
            }
          }
        }
      }
    }
  }
}'
```

### 3. Compute metrics per iteration

For each iteration, count:
- **Planned**: total items in that iteration
- **Completed**: items with status = "Done"
- **Per Squad**: completed items grouped by team field
- **Per Repo**: completed items grouped by repository name
- **Scope Creep**: items where `createdAt` > iteration `startDate`

### 4. Display velocity report

```
## Velocity Report

### Sprint Velocity Trend
| Sprint | Dates | Planned | Done | Rate | S1 | S2 | S3 |
|--------|-------|---------|------|------|----|----|-----|
| Iter 1 | Feb 19 - Mar 4 | 15 | 12 | 80% | 5 | 4 | 3 |
| Iter 2 | Mar 5 - Mar 18 | 12 | 4 | 33%* | 2 | 1 | 1 |

*Current sprint — in progress

### Team Workload (Current Sprint: <name>)
| Squad | Total | Done | In Progress | In Review | QA | Todo |
|-------|-------|------|-------------|-----------|-----|------|
| Squad 1 | 6 | 2 | 2 | 1 | 0 | 1 |
| Squad 2 | 4 | 1 | 1 | 0 | 0 | 2 |
| Squad 3 | 3 | 1 | 0 | 0 | 1 | 1 |

### Individual Workload
| Assignee | Items | Done | In Progress |
|----------|-------|------|-------------|
| @dev1 | 3 | 1 | 1 |
| @dev2 | 2 | 1 | 1 |
| Unassigned | 2 | 0 | 0 |

### Scope Creep Trend
| Sprint | Originally Planned | Added Mid-Sprint | Creep % |
|--------|-------------------|------------------|---------|
| Iter 1 | 13 | 2 | 15% |

### Cross-Repo Split
| Sprint | Free (presto-player) | Pro (presto-player-pro) |
|--------|---------------------|------------------------|
| Iter 1 | 9 (75%) | 3 (25%) |
| Iter 2 | 8 (67%) | 4 (33%) |
```

## Error Handling
- No completed iterations: "Not enough data yet. Complete at least one sprint to see velocity trends."
- Only one iteration: show the data but note "Need 2+ sprints for trend analysis"
