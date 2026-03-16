---
name: pm-triage
description: >
  Backlog refinement and grooming for any GitHub project — deduplicate issues,
  groom unscheduled items one by one, create issues, split epics into sub-issues,
  and bulk-close stale issues. Use this skill when the user says "triage",
  "groom backlog", "backlog refinement", "deduplicate issues", "find duplicates",
  "create issue", "split epic", "close stale issues", "clean up backlog",
  "prioritize backlog", "what's in the backlog", "unscheduled items", or any
  request to organize, prioritize, or clean up project issues. Also trigger for
  "pm triage", "issue cleanup", "bulk close", "new issue", or "break down this
  epic".
---

# PM Triage — Backlog Refinement

## Step 0: Load Config

Read `~/.claude/pm-config.json`. If missing, tell the user to run `/pm-setup` first and stop. See `../pm-setup/references/config-loader.md` for config shape and rules.

## On Trigger

Ask or infer:
> How would you like to refine the backlog?
> 1. **Full triage** — deduplicate, then groom one by one
> 2. **Groom only** — skip dedup, go straight to grooming
> 3. **Create issue** — quickly create and add a new issue
> 4. **Split epic** — break a large issue into sub-issues
> 5. **Close stale** — bulk-close old inactive issues

## Phase 1: Deduplicate

### 1. Fetch all open issues from each repo

```bash
gh issue list --repo <repo> --limit 200 --state open \
  --json number,title,labels,createdAt \
  --jq 'sort_by(.createdAt) | .[] | "#\(.number) | \(.title) | \(.createdAt[:10])"'
```

### 2. Find duplicates using parallel agents

Split issues into 3 chunks. Launch 3 parallel Agent subagents, each receiving the full list but focused on their chunk. They look for same-topic issues filed twice — the older/unlabeled one is the candidate for closure.

### 3. Confirm each duplicate with the user before closing

```bash
gh issue close <number> --repo <repo> --comment "Duplicate of #<canonical>. Closing."
```

## Phase 2: Groom Backlog

### 1. Fetch ungroomed items

Query project items where:
- Iteration is null (or all items if no iteration field)
- Status is NOT the done status (last in `statusFlow`)
- Content is an Issue (not a PR)

Sort by `createdAt` ascending (oldest first).

### 2. Check for orphaned issues

Fetch open issues from each repo and cross-reference with project items. Flag issues not on the project board.

### 3. Present each item for triage

```
### <repo>#<num> <title>
**Age**: <days> days | **Labels**: <labels> | **Comments**: <count>
**Assignee**: <assignee or "none">
**Summary**: <first 2-3 lines of body>

→ Prioritize / Label / Assign to sprint / Split / Close / Skip
```

## Workflow: Create Issue

1. Ask which repo (from config's `repos`)
2. Ask for description and type (bug / enhancement / research)
3. Generate issue body, confirm with user
4. Create with `gh issue create`, add to project with GraphQL mutation
5. Optionally set status/team/iteration

## Workflow: Split Epic

1. Fetch the issue
2. Propose 3-7 sub-issues based on the body
3. Create each, update parent with task list, add all to project

## Workflow: Close Stale

1. Ask cutoff (default: 6 months no activity)
2. Fetch and filter by `updatedAt`
3. Present list — user picks: close all / review one-by-one / cancel
4. Close with standard comment

## Error Handling
- Empty backlog → "All items groomed — nothing to triage."
- No orphaned issues → "All open issues are on the project board."
- Config missing → `/pm-setup`
