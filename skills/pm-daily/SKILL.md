---
name: pm-daily
description: >
  Daily standup briefing for Presto Player project — sprint status, items by
  status column, blockers, new issues, and action items. Run each morning to
  get your daily PM overview.
---

# PM Daily Briefing

## Context

- **Org**: prestomade
- **Project**: #5 — "Presto Player Project" (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`
- **Status flow**: Todo -> In progress -> In Review -> QA -> Done
- **Teams**: Squad 1, Squad 2, Squad 3

### Field IDs

| Field | ID |
|---|---|
| Status | `PVTSSF_lADOBL-zrs4BPoD9zg9-yn0` |
| Team | `PVTSSF_lADOBL-zrs4BPoD9zg9-yv8` |
| Iteration | `PVTIF_lADOBL-zrs4BPoD9zg9-ywA` |

### Status Option IDs

| Status | ID |
|---|---|
| Todo | `f75ad846` |
| In progress | `47fc9ee4` |
| In Review | `6d3695e4` |
| QA | `d0502a34` |
| Done | `98236657` |

## Workflow

### Step 1: Verify GitHub CLI auth

Run `gh auth status` and check for `project` scope. If missing, tell the user:
> Run `gh auth refresh -h github.com -s read:project -s project` to add project scopes.

### Step 2: Determine the current iteration

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

Find the current iteration: `startDate <= today < startDate + duration days`.
If no current iteration exists, display available iterations and suggest the user create one in the GitHub UI.

### Step 3: Fetch all project items

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
            ... on ProjectV2ItemFieldSingleSelectValue { name optionId }
          }
          team: fieldValueByName(name: "Team") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          iteration: fieldValueByName(name: "Iteration") {
            ... on ProjectV2ItemFieldIterationValue { title startDate duration iterationId }
          }
          targetDate: fieldValueByName(name: "Target date") {
            ... on ProjectV2ItemFieldDateValue { date }
          }
          content {
            ... on Issue {
              number title url createdAt state
              repository { name }
              assignees(first: 5) { nodes { login } }
              labels(first: 10) { nodes { name } }
            }
            ... on PullRequest {
              number title url state
              repository { name }
            }
          }
        }
      }
    }
  }
}'
```

Filter items to only those in the current iteration.

### Step 4: Fetch new issues from last 24 hours

Run for both repos:
```bash
gh issue list --repo prestomade/presto-player --state open --json number,title,createdAt,labels,assignees --limit 50
gh issue list --repo prestomade/presto-player-pro --state open --json number,title,createdAt,labels,assignees --limit 50
```

Filter to issues created in the last 24 hours. Cross-reference with project items to find issues NOT yet on the project.

### Step 5: For "In Progress" and "In Review" items, check for linked PRs

For each item in "In Progress" or "In Review" status, check for linked PRs:
```bash
gh pr list --repo prestomade/<repo> --search "<issue-number>" --json number,title,state,url
```

### Step 6: Present the briefing

Format and display:

```
## Sprint: <Iteration Name> (<start> - <end>) — Day X of Y

### Status Breakdown
**In Progress (N)**
- #<num> <title> — @<assignee> (<team>) — <days> days [, PR #<n>] [, no PR yet ⚠️]

**In Review (N)**
- #<num> <title> — @<assignee> (<team>) — PR #<n> [open <days> days]

**QA (N)**
- #<num> <title> — @<assignee> (<team>)

**Todo (N)**
- #<num> <title> — @<assignee> (<team>) [unassigned ⚠️]

**Done (N)**
- #<num> <title> — @<assignee>

### Blockers & At-Risk
- Items "In Progress" >3 days with no linked PR
- Items "In Review" >2 days
- Items with target date within 3 days and not Done
- Unassigned items in sprint

### New Issues (last 24h)
- <repo> #<num>: "<title>" — [on project / not on project yet]

### Your Action Items
- Summarize: unassigned items to assign, stale items to check, new issues to triage, PRs to review
```

## Error Handling
- If the GraphQL query returns empty items, display: "No items in current sprint — run `/pm-sprint plan` to add items"
- If no current iteration found, display available iterations and dates
- If `gh auth status` fails, prompt the user to re-authenticate
