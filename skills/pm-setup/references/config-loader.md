# Config Loader — Shared Reference

Every PM skill reads project configuration from `~/.claude/pm-config.json`. This file describes how to load and use the config.

## Loading the Config

1. Read `~/.claude/pm-config.json`
2. If the file doesn't exist, is empty, or fails to parse as JSON:
   > No project configured yet. Run `/pm-setup` with your GitHub project URL to get started.
   > Example: `/pm-setup https://github.com/orgs/acme/projects/3`
   Then **stop** — don't attempt any GraphQL queries without valid config.

## Config Shape

```json
{
  "owner": "acme",
  "ownerType": "organization",
  "projectNumber": 3,
  "projectId": "PVT_kwDO...",
  "projectTitle": "My Project",
  "repos": ["acme/frontend", "acme/backend"],
  "fields": {
    "status":    { "name": "Status",    "id": "PVTSSF_...", "options": {"Todo": "abc", "Done": "xyz"} },
    "team":      { "name": "Team",      "id": "PVTSSF_...", "options": {"Squad A": "..."} },
    "iteration": { "name": "Iteration", "id": "PVTIF_..." },
    "targetDate":{ "name": "Target date","id": "PVTF_..." },
    "quarter":   { "name": "Quarter",   "id": "PVTIF_..." }
  },
  "statusFlow": ["Todo", "In progress", "In Review", "QA", "Done"]
}
```

## Key Rules

### Optional fields
`team`, `iteration`, `targetDate`, and `quarter` may be `null` if the project doesn't have them. When null:
- **Omit that field entirely** from GraphQL queries (don't include it with a null name)
- Skip any analysis that depends on the missing field (e.g., skip team breakdowns if no team field, skip sprint filtering if no iteration field)
- Mention the gap to the user if it affects the output: "This project has no Iteration field — showing all non-done items instead of sprint-filtered view."

### Building GraphQL queries
The `ownerType` value determines the GraphQL root field. Use it **literally** as the field name:
- If `ownerType` is `"organization"` → `organization(login: "acme") { projectV2(number: 3) { ... } }`
- If `ownerType` is `"user"` → `user(login: "acme") { projectV2(number: 3) { ... } }`

Substitute `owner` and `projectNumber` from config. Never hardcode org names or project numbers.

### Status flow
`statusFlow` is ordered from start to finish. The **last** entry is always the "done" status. The **first** is the backlog/todo status. Middle entries are active statuses. Use this to determine:
- Which items are "done" (last status)
- Which items are "active" / "in progress" (middle statuses)
- Which items haven't started (first status)

### Multiple repos
When `repos` has 2+ entries, enable cross-repo features (dependency tracking, repo-split analysis). When only 1 repo, skip those sections.

### Stale config detection
If a GraphQL query fails with "Could not resolve to a ProjectV2" or similar, the config may be stale. Tell the user:
> The project config may be outdated. Run `/pm-setup` to refresh it.
