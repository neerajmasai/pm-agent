---
name: pm-daily
description: >
  Daily standup briefing for any GitHub project — sprint status, items by status
  column, blockers, new issues, and action items. Use this skill when the user
  says "daily standup", "morning briefing", "sprint status", "what's happening
  today", "daily update", "standup", "how's the sprint", "project status",
  "what's in progress", "show me the board", or any request for a current
  snapshot of sprint/project health. Also trigger for "pm daily", "daily
  briefing", "what should I focus on today", or "any blockers".
---

# PM Daily Briefing

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules about optional fields and GraphQL query construction.

## Step 1: Verify Auth

```bash
gh auth status
```
Check for `project` scope. If missing, tell the user to run `gh auth refresh -h github.com -s read:project -s project`.

## Step 2: Determine Current Iteration

Skip if config has no `iteration` field.

Query iterations using the config's `ownerType`, `owner`, `projectNumber`, and `fields.iteration.name`. Find the current one where `startDate <= today < startDate + duration days`.

If no current iteration exists, show available ones and suggest creating one in GitHub UI.

```bash
gh api graphql -f query='
{
  <ownerType>(login: "<owner>") {
    projectV2(number: <projectNumber>) {
      field(name: "<fields.iteration.name>") {
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

## Step 3: Fetch All Project Items

Build the query dynamically based on which fields exist in config. Only include fields that are non-null:

```bash
gh api graphql --paginate -f query='
query($endCursor: String) {
  <ownerType>(login: "<owner>") {
    projectV2(number: <projectNumber>) {
      items(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          status: fieldValueByName(name: "<fields.status.name>") {
            ... on ProjectV2ItemFieldSingleSelectValue { name optionId }
          }
          # Include ONLY if fields.team is not null:
          team: fieldValueByName(name: "<fields.team.name>") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          # Include ONLY if fields.iteration is not null:
          iteration: fieldValueByName(name: "<fields.iteration.name>") {
            ... on ProjectV2ItemFieldIterationValue { title startDate duration iterationId }
          }
          # Include ONLY if fields.targetDate is not null:
          targetDate: fieldValueByName(name: "<fields.targetDate.name>") {
            ... on ProjectV2ItemFieldDateValue { date }
          }
          content {
            ... on Issue {
              number title url createdAt state
              repository { name nameWithOwner }
              assignees(first: 5) { nodes { login } }
              labels(first: 10) { nodes { name } }
            }
            ... on PullRequest {
              number title url state
              repository { name nameWithOwner }
            }
          }
        }
      }
    }
  }
}'
```

**Pagination note**: `--paginate` may return multiple JSON objects concatenated. When parsing, split by `}{` or handle as JSON stream.

**Filtering**:
- If iterations exist: filter to items in the current iteration
- If no iteration field: show all items where status is NOT the last entry in `statusFlow`

## Step 4: Fetch New Issues (Last 24h)

For each repo in config's `repos` array:
```bash
gh issue list --repo <repo> --state open --json number,title,createdAt,labels,assignees --limit 50
```

Filter to issues created in the last 24 hours. Cross-reference with project items to flag issues NOT yet on the project board.

## Step 5: Check for Linked PRs

For items in active statuses (not the first or last status in `statusFlow`), look for PRs:
```bash
gh pr list --repo <repo> --search "<issue-number>" --json number,title,state,url
```

Also check `--state all` to catch recently merged PRs — items may show "In Review" but the PR is already merged.

## Step 6: Present the Briefing

Use the actual status names from `statusFlow`. Adapt the format based on what fields exist.

```
## Sprint: <Iteration Name> (<start> – <end>) — Day X of Y
(or "## Project Status — <date>" if no iteration field)

### Status Breakdown

**<Status 1 — e.g. "In progress"> (N)**
- <repo>#<num> <title> — @<assignee> (<team>) [— PR #<n>] [— no PR ⚠️]

**<Status 2 — e.g. "In Review"> (N)**
- <repo>#<num> <title> — @<assignee> (<team>) — PR #<n> [merged ✓ | open <days>d]

(repeat for each status in statusFlow)

### Blockers & At-Risk
- Items in active statuses >3 days with no linked PR
- Items in review-like statuses >2 days
- Items with target date within 3 days and not done
- Unassigned items in sprint

### New Issues (last 24h)
- <repo>#<num>: "<title>" — [on project | not on project ⚠️]

### Action Items
- Unassigned items to assign
- Stale items to check on
- New issues to triage
- PRs to review
- Items with merged PRs that should move to next status
```

**Team column**: only show `(<team>)` if the project has a team field.
**Repo prefix**: only show `<repo>#` if there are multiple repos. For single-repo projects, just use `#<num>`.

## Error Handling
- Config missing → prompt `/pm-setup`
- Empty project → "No items found — add issues to your project board or run `/pm-sprint plan`"
- No current iteration → show available iterations with dates
- GraphQL failure → check if config is stale, suggest `/pm-setup` refresh
