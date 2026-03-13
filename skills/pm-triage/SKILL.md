---
name: pm-triage
description: >
  Backlog refinement and grooming for Presto Player — deduplicate issues across
  repos, groom unscheduled items one by one, create issues, split epics into
  sub-issues, and bulk-close stale issues. Works at the project level across
  both presto-player and presto-player-pro.
---

# PM Triage — Backlog Refinement

## Context

- **Org**: prestomade
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`

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
| Done | `98236657` |

### Team Option IDs

| Team | ID |
|---|---|
| Squad 1 | `9282166a` |
| Squad 2 | `8a5d08e5` |
| Squad 3 | `478d0b17` |

### Quick Label Reference

| Label | Use for |
|---|---|
| `High Priority` | Urgent bugs or key features |
| `enhancement` | New features |
| `bug` | Something broken |
| `security` | Security vulnerabilities |
| `research` | Investigation/feasibility tasks |

## On Trigger

Ask the user what they want to do:
> How would you like to refine the backlog?
> 1. **Full triage** — deduplicate then groom one by one
> 2. **Groom only** — skip dedup, go straight to grooming
> 3. **Create issue** — quickly create a new issue
> 4. **Split epic** — break a large issue into sub-issues
> 5. **Close stale** — bulk-close old inactive issues

## Phase 1: Deduplicate (if selected)

### 1. Fetch all open issues from both repos

```bash
gh issue list --repo prestomade/presto-player --limit 200 --state open \
  --json number,title,labels,createdAt \
  --jq 'sort_by(.createdAt) | .[] | "#\(.number) | \(.title) | \(.createdAt[:10])"'
```

```bash
gh issue list --repo prestomade/presto-player-pro --limit 200 --state open \
  --json number,title,labels,createdAt \
  --jq 'sort_by(.createdAt) | .[] | "#\(.number) | \(.title) | \(.createdAt[:10])"'
```

### 2. Dispatch parallel agents to find duplicates

Split the combined issue list into 3 chunks (oldest / middle / newest). Launch 3 parallel agents using the Agent tool. Each agent receives the **full issue list** and is assigned one chunk to focus on.

Agent prompt template:
> You are checking for duplicate GitHub issues. Here is the full list of open issues across presto-player and presto-player-pro:
> <full list>
>
> Focus on issues in your assigned range: #<start> to #<end>
> A duplicate = same topic/bug/feature filed twice. The older/unlabeled one is the duplicate.
> Use `gh issue view <n> --repo prestomade/<repo>` to verify ambiguous cases.
> Return: `CLOSE #<older> (duplicate of #<newer>) — <reason>`
> If no duplicates found in your range, say "No duplicates found."

### 3. Present duplicates for confirmation

Show each proposed duplicate closure to the user. For each:
> **Close #<older> as duplicate of #<newer>?**
> Older: #<n> — <title>
> Newer: #<n> — <title>
> Reason: <agent's reason>
> -> Confirm / Skip?

If confirmed:
```bash
gh issue close <number> --repo prestomade/<repo> --comment "Duplicate of #<canonical>. Closing."
```

## Phase 2: Groom Backlog

### 1. Fetch ungroomed items

Get all project items with no iteration assigned:

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
          iteration: fieldValueByName(name: "Iteration") {
            ... on ProjectV2ItemFieldIterationValue { title }
          }
          team: fieldValueByName(name: "Team") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          content {
            ... on Issue {
              number title url createdAt state body
              repository { name }
              assignees(first: 5) { nodes { login } }
              labels(first: 10) { nodes { name } }
              comments { totalCount }
            }
          }
        }
      }
    }
  }
}'
```

Filter to items where:
- iteration is null (no sprint assigned)
- status is NOT "Done"
- content is an Issue (not a PR)

Sort by `createdAt` ascending (oldest first).

### 2. Also check for open issues NOT on the project

```bash
gh issue list --repo prestomade/presto-player --state open --json number,title,createdAt,labels --limit 100
gh issue list --repo prestomade/presto-player-pro --state open --json number,title,createdAt,labels --limit 100
```

Cross-reference with project items. Issues not found in the project items list are "orphaned."

### 3. Present each item for triage

For each ungroomed item, present:
```
### #<num> <title> (<repo>)
**Age**: <days> days | **Labels**: <labels> | **Comments**: <count>
**Assignee**: <assignee or "none">
**Summary**: <first 2-3 lines of body, or "No description">

-> What to do?
1. **Prioritize** — add High Priority label
2. **Label** — add/change labels
3. **Assign to sprint** — pick iteration + team
4. **Split** — break into sub-issues
5. **Close** — close with reason
6. **Skip** — move to next item
```

Execute the chosen action using the appropriate `gh` command or GraphQL mutation.

## Workflow: Create Issue

1. Ask: "Which repo? (presto-player / presto-player-pro)"
2. Ask: "Brief description of the issue"
3. Ask: "Type? (bug / enhancement / research)"
4. Generate a well-formed issue body:
   - For bugs: use the bug report template format (steps to reproduce, expected, actual)
   - For enhancements: use the feature request template format (description, use case, proposed solution)
5. Show the generated issue and ask for confirmation
6. Create:
   ```bash
   gh issue create --repo prestomade/<repo> --title "<title>" --body "<body>" --label "<type>"
   ```
7. Add to project:
   ```bash
   ISSUE_ID=$(gh issue view <number> --repo prestomade/<repo> --json id --jq .id)
   gh api graphql -f query="mutation {
     addProjectV2ItemById(input: {
       projectId: \"PVT_kwDOBL-zrs4BPoD9\"
       contentId: \"$ISSUE_ID\"
     }) { item { id } }
   }"
   ```
8. Optionally set fields (status, team, iteration) if user wants

## Workflow: Split Epic

1. Ask: "Enter the issue number to split"
2. Fetch the issue: `gh issue view <number> --repo prestomade/<repo> --json number,title,body,labels`
3. Analyze the issue body and suggest a breakdown into 3-7 sub-issues
4. Present the proposed sub-issues for user confirmation/editing
5. For each confirmed sub-issue:
   ```bash
   gh issue create --repo prestomade/<repo> --title "<sub-issue title>" --body "<body referencing parent #<num>>" --label "<labels>"
   ```
6. Update parent issue body to include task list:
   ```bash
   # Append task list to parent issue body
   gh issue edit <parent-number> --repo prestomade/<repo> --body "<original body>

   ## Sub-issues
   - [ ] #<sub1>
   - [ ] #<sub2>
   - [ ] #<sub3>"
   ```
7. Add all sub-issues to the project and optionally assign to sprint/team

## Workflow: Close Stale

1. Ask: "Close issues with no activity in how many months? (default: 6)"
2. Fetch issues updated before that cutoff:
   ```bash
   gh issue list --repo prestomade/presto-player --state open --json number,title,updatedAt,labels,assignees --limit 200
   gh issue list --repo prestomade/presto-player-pro --state open --json number,title,updatedAt,labels,assignees --limit 200
   ```
3. Filter to issues where `updatedAt` is older than the cutoff
4. Present the list:
   ```
   ### Stale Issues (N items, no activity in >6 months)
   - presto-player #<num>: <title> — last activity: <date>
   - ...

   -> Close all? / Review one by one? / Cancel?
   ```
5. If confirmed, bulk close:
   ```bash
   gh issue close <number> --repo prestomade/<repo> --comment "Closing — no activity in >6 months. Can be reopened if this resurfaces."
   ```

## Common Close Reasons
- `"Closing — no recent reports. Can be reopened if this resurfaces."`
- `"Closing — not a current priority. Can be reopened when this work resumes."`
- `"Closing — already handled as part of #<issue>."`
- `"Closing — old item no longer being actively worked on."`

## Error Handling
- Empty backlog: "All backlog items have been groomed! Nothing to triage."
- No orphaned issues: "All open issues are already on the project board."
- Auth failure: prompt `gh auth refresh -h github.com -s read:project -s project`
