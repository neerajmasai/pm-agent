---
name: pm-roadmap
description: >
  Roadmap and release planning for Presto Player — view items by quarter,
  generate release plans with changelogs, and track milestone progress across
  both presto-player and presto-player-pro.
---

# PM Roadmap & Release Planning

## Context

- **Org**: prestomade
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`

### Field IDs

| Field | ID |
|---|---|
| Quarter | `PVTIF_lADOBL-zrs4BPoD9zg9-ywE` |
| Status | `PVTSSF_lADOBL-zrs4BPoD9zg9-yn0` |
| Target date | `PVTF_lADOBL-zrs4BPoD9zg9-ywM` |

## On Trigger

Ask the user:
> What would you like to see?
> 1. **Roadmap** — items grouped by quarter with progress
> 2. **Release plan** — what's ready to ship + draft changelog
> 3. **Milestones** — progress by epic/milestone

## Workflow: Roadmap View

### 1. Fetch all project items with quarter field

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
          quarter: fieldValueByName(name: "Quarter") {
            ... on ProjectV2ItemFieldIterationValue { title }
          }
          targetDate: fieldValueByName(name: "Target date") {
            ... on ProjectV2ItemFieldDateValue { date }
          }
          content {
            ... on Issue {
              number title repository { name }
              labels(first: 10) { nodes { name } }
            }
          }
        }
      }
    }
  }
}'
```

### 2. Group by quarter and display

```
## Roadmap

### Q1 2026
- Total: 25 | Done: 18 (72%) | In Progress: 4 | Todo: 3
- ⚠️ Target dates approaching:
  - #123 Video chapters — due Mar 15

### Q2 2026
- Total: 15 | Done: 0 (0%) | In Progress: 1 | Todo: 14

### No Quarter Assigned
- Total: 45 items — consider assigning these to a quarter
```

## Workflow: Release Plan

### 1. Get last release date for each repo

```bash
gh api repos/prestomade/presto-player/releases/latest --jq '.published_at' 2>/dev/null || echo "No releases"
gh api repos/prestomade/presto-player-pro/releases/latest --jq '.published_at' 2>/dev/null || echo "No releases"
```

### 2. Query Done items since last release

Filter project items where:
- Status = "Done"
- Issue `closedAt` > last release date

### 3. Display release plan

```
## Release Plan

### presto-player (last release: v4.1.0, <date>)

**Ready to Ship (N items)**

🚀 Features
- #123 Video chapters — @dev1
- #456 Quality selector — @dev2

🐛 Bug Fixes
- #789 Safari playback fix — @dev3

🔒 Security
- #101 XSS patch — @dev4

**Blockers (items not yet Done)**
- #111 In Review: Overlay selector — @dev5 (2 days in review)
- #222 QA: Video info panel — @dev6

### presto-player-pro (last release: v3.0.2, <date>)
... (same format)

### Draft Changelog

#### presto-player vX.X.X

**Features**
- Video chapters support (#123)
- Quality selector for self-hosted videos (#456)

**Bug Fixes**
- Fixed Safari playback issue (#789)

**Security**
- Fixed XSS vulnerability in embed handler (#101)
```

## Workflow: Milestone Tracking

### 1. Get items grouped by label prefix or parent issue

Look for items with labels like `epic: <name>` or group by parent issue references.

If no clear epics/milestones exist, group by label categories (enhancement, bug, security, etc.)

### 2. Display

```
## Milestone Tracking

### Video Player Overhaul (7 items)
████████░░ 72% complete (5/7)
- ✅ #101, ✅ #102, ✅ #103, ✅ #104, ✅ #105
- 🔄 #106 In Progress
- ⏳ #107 Todo

### Admin Dashboard Revamp (4 items)
██████████ 100% complete (4/4)
All items done!
```

## Error Handling
- No releases found: "No releases found for <repo>. Showing all Done items instead."
- No quarter data: "No items have Quarter field set. Consider assigning quarters during sprint planning."
