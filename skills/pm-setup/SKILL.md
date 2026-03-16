---
name: pm-setup
description: >
  Configure PM skills for any GitHub project — auto-discovers fields, statuses,
  teams, iterations, and repos from a project URL. Run once to set up, re-run
  to reconfigure or switch projects. Use this skill when the user says "set up
  project", "configure PM", "switch project", "pm setup", provides a GitHub
  project URL, or when any other PM skill reports missing config. Also trigger
  when the user says "connect to my project", "track this project", or "use
  this GitHub project".
---

# PM Setup — Project Configuration

## What This Does

Takes a GitHub Projects V2 URL (org or user), introspects its fields and metadata via GraphQL, and writes `~/.claude/pm-config.json` — the shared config that all other PM skills (`/pm-daily`, `/pm-sprint`, `/pm-risk`, etc.) read from. Think of it as the one-time wiring step that makes everything else work.

## On Trigger

If the user provides a GitHub project URL (or says "setup" / "configure" / "switch project"), extract the owner and project number from it.

If no URL is provided, ask:
> Please provide your GitHub project URL.
> Examples:
> - `https://github.com/orgs/myorg/projects/5`
> - `https://github.com/users/myuser/projects/3`

If `~/.claude/pm-config.json` already exists, show the current project and ask:
> Currently configured: **<projectTitle>** (#<projectNumber>) by <owner>
> → Reconfigure with a new project? / Re-discover fields? / Keep current?

## Step 1: Verify GitHub CLI Auth

```bash
gh auth status
```

Check the output for `project` in the token scopes. If missing:
> You need the `project` scope. Run:
> ```
> gh auth refresh -h github.com -s read:project -s project
> ```

## Step 2: Parse the URL

Extract from the URL:
- **ownerType**: `organization` (from `/orgs/`) or `user` (from `/users/`)
- **owner**: the org or user login
- **projectNumber**: the integer after `/projects/`

Common URL patterns:
- `https://github.com/orgs/<owner>/projects/<number>`
- `https://github.com/users/<owner>/projects/<number>`
- `https://github.com/orgs/<owner>/projects/<number>/views/1` (strip the view suffix)

## Step 3: Discover Project Metadata and Fields

The GraphQL root field depends on `ownerType` — use `organization(login: "...")` for orgs, `user(login: "...")` for users:

```bash
gh api graphql -f query='
{
  <ownerType>(login: "<owner>") {
    projectV2(number: <projectNumber>) {
      id
      title
      fields(first: 50) {
        nodes {
          ... on ProjectV2Field {
            id name dataType
          }
          ... on ProjectV2SingleSelectField {
            id name
            options { id name }
          }
          ... on ProjectV2IterationField {
            id name
            configuration {
              iterations { id title startDate duration }
              completedIterations { id title startDate duration }
            }
          }
        }
      }
    }
  }
}'
```

From the response, extract:
- `projectId` — the project node ID (starts with `PVT_`)
- `projectTitle` — the human-readable project name
- All fields with their IDs, types, and option values

## Step 4: Discover Linked Repositories

Look at existing project items to find which repos are connected:

```bash
gh api graphql -f query='
{
  <ownerType>(login: "<owner>") {
    projectV2(number: <projectNumber>) {
      items(first: 100) {
        nodes {
          content {
            ... on Issue { repository { nameWithOwner } }
            ... on PullRequest { repository { nameWithOwner } }
          }
        }
      }
    }
  }
}'
```

Collect unique `nameWithOwner` values. If no items exist on the project yet, ask the user:
> No items found on this project yet. Which repositories should I track?
> Enter as comma-separated: `owner/repo1, owner/repo2`

## Step 5: Map Fields to Roles

Automatically match discovered fields to their roles:

| Role | Look for field named... | Type | Required? |
|------|------------------------|------|-----------|
| **status** | "Status" | SingleSelect | Yes — stop if missing |
| **team** | "Team", "Squad", "Group", "Assignee Group" | SingleSelect | No |
| **iteration** | "Iteration", "Sprint" | Iteration | No |
| **targetDate** | "Target date", "Due date", "Deadline" | Date | No |
| **quarter** | "Quarter", "Roadmap", "Phase" | Iteration or SingleSelect | No |

If a match is ambiguous (multiple candidates), ask the user to pick. If no Status field is found, that's a hard stop — every project needs one.

## Step 6: Confirm Status Flow

Present the Status field's options in the order they appear:
> I found these status columns: **Todo**, **In progress**, **In Review**, **QA**, **Done**
> Is this the correct flow from start → finish? (yes / reorder)

The order matters — the last entry is treated as "done" by all PM skills.

## Step 7: Write Config

Write to `~/.claude/pm-config.json`. See `references/config-loader.md` for the full schema. Fields that don't exist on the project should be set to `null`.

## Step 8: Confirm

```
## Project Configured!

**Project**: <title> (#<number>)
**Owner**: <owner> (<ownerType>)
**Repos**: <repo1>, <repo2>
**Status flow**: Todo → In progress → In Review → QA → Done
**Team field**: <name> (<N> teams) — or "none"
**Iteration field**: <name> — or "none"
**Target date field**: <name> — or "none"

Config saved to ~/.claude/pm-config.json
All PM skills will now use this project.
```

## Error Handling
- **Invalid URL format**: show examples and ask again
- **404 / not found**: check permissions — the user may need to be a project member, or the project may be private
- **No Status field**: "This project needs a Status field. Add one in project settings, then re-run `/pm-setup`."
- **GraphQL auth error**: prompt `gh auth refresh`
