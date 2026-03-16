---
name: pm-sprint
description: >
  Full sprint lifecycle management for any GitHub project — start sprint, end
  sprint, plan sprint, check status, add/remove items. Use this skill when the
  user says "start sprint", "end sprint", "plan sprint", "sprint status",
  "add to sprint", "remove from sprint", "carry over items", "sprint planning",
  "next sprint", "close sprint", "sprint health", "what's left in the sprint",
  "sprint burndown", or any request to manage iteration-based work. Also trigger
  for "pm sprint", "manage sprint", "sprint capacity", or "assign to sprint".
---

# PM Sprint Management

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules.

If config has no `iteration` field:
> This project has no Iteration field — sprint management requires one. Add an Iteration field in your project settings, then run `/pm-setup` to refresh.

## On Trigger

Infer intent from the user's message, or ask:
> What would you like to do?
> 1. **Start sprint** — set up the next iteration with items
> 2. **End sprint** — close current, carry over incomplete items
> 3. **Plan sprint** — add backlog items to current/next sprint
> 4. **Status** — sprint health and burndown
> 5. **Add/remove items** — manage items in current sprint

## Shared: Query Iterations

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

Compute:
- **Current**: `startDate <= today < startDate + duration`
- **Next**: earliest with `startDate > today`
- **Previous**: most recent in `completedIterations`

## Shared: Fetch Project Items

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
          # Include only if fields.team is not null:
          team: fieldValueByName(name: "<fields.team.name>") {
            ... on ProjectV2ItemFieldSingleSelectValue { name }
          }
          iteration: fieldValueByName(name: "<fields.iteration.name>") {
            ... on ProjectV2ItemFieldIterationValue { title startDate duration iterationId }
          }
          content {
            ... on Issue {
              number title url createdAt state body
              repository { name nameWithOwner }
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

## Workflow: Start Sprint

1. Find the next upcoming iteration. If none:
   > No upcoming iteration. Create one in GitHub: Project Settings → Iteration field → Add iteration.

2. Show carried-over items (already assigned to next iteration).

3. Ask: "Want to add more items from the backlog?" → enter Plan Sprint if yes.

## Workflow: End Sprint

1. Show current iteration completion stats.

2. For each incomplete item, ask one at a time:
   > **<repo>#<num> <title>** (<status>, @<assignee>)
   > → Carry to next sprint / Move to backlog / Close?

3. Mutations:
   - **Carry**: `updateProjectV2ItemFieldValue` — set iteration to next iteration's ID
   - **Backlog**: `clearProjectV2ItemFieldValue` — clear the iteration field
   - **Close**: `gh issue close <number> --repo <repo> --comment "Closed during sprint end — not carried forward."`

   ```bash
   # Set iteration
   gh api graphql -f query='mutation {
     updateProjectV2ItemFieldValue(input: {
       projectId: "<projectId>"
       itemId: "<ITEM_ID>"
       fieldId: "<fields.iteration.id>"
       value: { iterationId: "<NEXT_ITERATION_ID>" }
     }) { projectV2Item { id } }
   }'
   ```

4. Show summary: completed / carried / backlogged / closed counts + completion rate.

## Workflow: Plan Sprint

1. Show current sprint items grouped by team (if team field exists) or just as a flat list.

2. Fetch backlog: items on the project with no iteration set, not in done status. Sort by priority labels first, then `createdAt` oldest first.

3. Present each backlog item for triage — user decides: add to sprint (pick team + assignee) or skip.

4. After all reviewed, show sprint plan summary with team breakdown (if applicable).

## Workflow: Status

```
## Sprint: <Iteration Name> — Day X of Y

### Burndown
Done: N/M (X%) — on track / at risk / behind

### By Status
<each status>: N items

### By Team (if team field exists)
<team>: N total (N done, N active, N todo)

### At Risk
- Todo items untouched >5 days
- Active items >3 days with no PR
- Unassigned items
```

## Workflow: Add/Remove

**Add**: Search → confirm → add to project if needed → set iteration/team/assignee.
**Remove**: Find item → clear iteration field.

## Error Handling
- No iteration field → explain and suggest adding one
- No current/next iteration → show available ones
- Empty backlog → "All items are assigned to iterations"
- Auth failure → `gh auth refresh -h github.com -s read:project -s project`
