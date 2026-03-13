---
name: pm-sprint
description: >
  Full sprint lifecycle management for Presto Player — start sprint, end sprint,
  plan sprint, check status, add/remove items. Manages iterations, assignments,
  and squad capacity on GitHub Project #5.
---

# PM Sprint Management

## Context

- **Org**: prestomade
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
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

### Team Option IDs

| Team | ID |
|---|---|
| Squad 1 | `9282166a` |
| Squad 2 | `8a5d08e5` |
| Squad 3 | `478d0b17` |

## On Trigger

Ask the user what they want to do:
> What would you like to do?
> 1. **Start sprint** — set up the next sprint with items
> 2. **End sprint** — close current sprint, carry over incomplete items
> 3. **Plan sprint** — add backlog items to current/next sprint
> 4. **Status** — current sprint health and burndown
> 5. **Add/remove items** — manage items in the current sprint

Or infer from their message if they said something like "start the next sprint" or "how's the sprint going".

## Shared: Determine Iterations

Always start by querying iteration config:

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

Compute:
- **Current**: `startDate <= today < startDate + duration`
- **Next**: earliest with `startDate > today`
- **Previous**: most recent in `completedIterations`

## Shared: Fetch All Project Items

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

## Workflow: Start Sprint

1. Find the next upcoming iteration. If none exists:
   > No upcoming iteration found. Please create one in the GitHub UI:
   > https://github.com/orgs/prestomade/projects/5/settings → Iteration field → Add iteration

2. Show the next iteration details:
   ```
   ## Starting: <Iteration Name> (<start> - <end>)
   ```

3. List items already assigned to this iteration (carried over):
   ```
   ### Carried Over (N items)
   - #<num> <title> — @<assignee> (<team>) — was: <previous status>
   ```

4. Ask: "Want to add more items from the backlog?"
   - If yes, enter the **Plan Sprint** workflow below

## Workflow: End Sprint

1. Show current iteration stats:
   ```
   ## Ending: <Iteration Name> (<start> - <end>)

   ### Summary
   - Done: N items
   - Not Done: N items (M in progress, K todo)
   ```

2. For each incomplete item, ask:
   > **#<num> <title>** (<status>, @<assignee>)
   > → Carry to next sprint / Move to backlog / Close?

   - **Carry**: Update iteration field to the next iteration's ID
   - **Backlog**: Clear the iteration field using `clearProjectV2ItemFieldValue`
   - **Close**: `gh issue close <number> --repo prestomade/<repo> --comment "Closed during sprint end — not carried forward."`

3. After all items processed, show completion summary:
   ```
   ### Sprint Complete
   - Completed: N items
   - Carried to <Next Iteration>: N items
   - Moved to backlog: N items
   - Closed: N items
   - Completion rate: X%
   ```

## Workflow: Plan Sprint

1. Show current sprint items grouped by squad:
   ```
   ### Current Sprint: <Iteration Name>
   **Squad 1 (N items)**: #1, #2, #3
   **Squad 2 (N items)**: #4, #5
   **Squad 3 (N items)**: #6
   **Unassigned (N items)**: #7, #8
   ```

2. Fetch backlog items (on project, no iteration set, status != Done). Sort by:
   - Priority labels first (`High Priority` at top)
   - Then by `createdAt` oldest first

3. Present each backlog item one at a time:
   ```
   ### Backlog Item: #<num> <title>
   **Repo**: presto-player | **Age**: 45 days | **Labels**: enhancement
   **Description**: <first 2-3 lines of body>

   → Add to sprint? (yes/no/skip)
   ```

4. If user says yes, ask:
   > Assign to which team? (Squad 1 / Squad 2 / Squad 3)
   > Assign to? (enter GitHub username or skip)

5. Execute mutations:
   - Set iteration:
     ```bash
     gh api graphql -f query='mutation {
       updateProjectV2ItemFieldValue(input: {
         projectId: "PVT_kwDOBL-zrs4BPoD9"
         itemId: "<ITEM_ID>"
         fieldId: "PVTIF_lADOBL-zrs4BPoD9zg9-ywA"
         value: { iterationId: "<ITERATION_ID>" }
       }) { projectV2Item { id } }
     }'
     ```
   - Set team:
     ```bash
     gh api graphql -f query='mutation {
       updateProjectV2ItemFieldValue(input: {
         projectId: "PVT_kwDOBL-zrs4BPoD9"
         itemId: "<ITEM_ID>"
         fieldId: "PVTSSF_lADOBL-zrs4BPoD9zg9-yv8"
         value: { singleSelectOptionId: "<TEAM_OPTION_ID>" }
       }) { projectV2Item { id } }
     }'
     ```
   - Set assignee (if provided): `gh issue edit <number> --repo prestomade/<repo> --add-assignee <username>`

6. After all items reviewed, show sprint plan summary:
   ```
   ### Sprint Plan Summary: <Iteration Name>
   **Squad 1**: N items (list)
   **Squad 2**: N items (list)
   **Squad 3**: N items (list)
   **Total**: N items
   ```

## Workflow: Status

1. Fetch current iteration items (same as daily briefing)
2. Display:
   ```
   ## Sprint Status: <Iteration Name> — Day X of Y

   ### Burndown
   Done: N/M (X%) — projected: on track / at risk / behind

   ### By Status
   - Todo: N | In Progress: N | In Review: N | QA: N | Done: N

   ### By Squad
   - Squad 1: N total (N done, N in progress, N todo)
   - Squad 2: ...
   - Squad 3: ...

   ### At Risk
   - Items with no progress (todo for >5 days)
   - Items in progress >3 days with no PR
   - Unassigned items
   ```

## Workflow: Add/Remove Items

### Add
1. Ask: "Enter issue number or search term"
2. If number: `gh issue view <number> --repo prestomade/<repo> --json number,title,state,labels`
3. If search: `gh search issues "<term>" --repo prestomade/presto-player --repo prestomade/presto-player-pro --json number,title,repository --limit 10`
4. Confirm the item, then:
   - If not on project: add it first
     ```bash
     # Get the issue's node ID
     gh issue view <number> --repo prestomade/<repo> --json id --jq .id
     # Add to project
     gh api graphql -f query='mutation {
       addProjectV2ItemById(input: {
         projectId: "PVT_kwDOBL-zrs4BPoD9"
         contentId: "<ISSUE_NODE_ID>"
       }) { item { id } }
     }'
     ```
   - Set iteration, team, status, assignee as prompted

### Remove
1. Ask: "Enter issue number to remove from sprint"
2. Find the project item ID for that issue
3. Clear iteration field:
   ```bash
   gh api graphql -f query='mutation {
     clearProjectV2ItemFieldValue(input: {
       projectId: "PVT_kwDOBL-zrs4BPoD9"
       itemId: "<ITEM_ID>"
       fieldId: "PVTIF_lADOBL-zrs4BPoD9zg9-ywA"
     }) { projectV2Item { id } }
   }'
   ```

## Error Handling
- No current iteration: show available iterations, suggest creating one in the UI
- No next iteration (for End Sprint carry-over): warn user and suggest creating one first
- Empty backlog: "No unscheduled items in backlog. All items are assigned to iterations."
- Auth failure: prompt `gh auth refresh -h github.com -s read:project -s project`
