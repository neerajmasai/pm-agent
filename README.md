# Presto Player PM Agent

A set of 7 Claude Code skills that turn Claude into a product manager for GitHub Projects v2. Built for the [Presto Player](https://prestoplayer.com) project, but adaptable to any GitHub org/project.

## Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| Daily Briefing | `/pm-daily` | Sprint status, items by column, blockers, new issues, action items |
| Sprint Management | `/pm-sprint` | Start, end, plan sprints. Add/remove items, check status |
| Backlog Triage | `/pm-triage` | Deduplicate issues, groom backlog, create issues, split epics, close stale |
| Roadmap | `/pm-roadmap` | Quarterly view, release plan with changelog, milestone tracking |
| Retrospective | `/pm-retro` | Completion stats, carried-over items, scope creep, per-squad breakdown |
| Velocity | `/pm-velocity` | Sprint velocity trends, team workload, scope creep tracking, cross-repo split |
| Risk Tracking | `/pm-risk` | At-risk items, cross-repo dependencies, stakeholder status updates |

## Prerequisites

1. **Claude Code** — [Install Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)
2. **GitHub CLI (`gh`)** — [Install GitHub CLI](https://cli.github.com/)
3. **GitHub CLI project scopes** — Run once:
   ```bash
   gh auth refresh -h github.com -s read:project -s project
   ```
4. **GitHub Project iterations** — Iterations must be pre-created in the GitHub UI (the API doesn't support creating them):
   https://github.com/orgs/prestomade/projects/5/settings → Iteration field → Add iteration

## Installation

### Quick Setup (recommended)

```bash
git clone https://github.com/neerajmasai/presto-pm-agent.git
cd presto-pm-agent
./setup.sh
```

This creates symlinks from `~/.claude/skills/pm-*` to the repo, so you get updates automatically when you `git pull`.

### Manual Setup

Copy the skill folders to your Claude Code skills directory:

```bash
cp -r skills/pm-* ~/.claude/skills/
```

### Verify Installation

Open Claude Code and type `/pm-daily` — you should see the skill trigger and produce a daily briefing.

## Configuration

The skills are configured for the Presto Player project:

- **Org**: `prestomade`
- **Project**: #5 (ID: `PVT_kwDOBL-zrs4BPoD9`)
- **Repos**: `prestomade/presto-player`, `prestomade/presto-player-pro`
- **Teams**: Squad 1, Squad 2, Squad 3
- **Status flow**: Todo → In Progress → In Review → QA → Done

### Adapting for a different project

To use these skills with a different GitHub org/project, update the following in each `SKILL.md`:

1. **Org name** — replace `prestomade` with your org
2. **Project number** — replace `5` with your project number
3. **Project ID** — replace `PVT_kwDOBL-zrs4BPoD9` with your project's node ID
4. **Field IDs** — replace Status, Team, and Iteration field IDs with yours
5. **Option IDs** — replace status and team option IDs with yours
6. **Repo names** — replace repo references with your repos

To find your project's field and option IDs, run:

```bash
gh api graphql -f query='
{
  organization(login: "YOUR_ORG") {
    projectV2(number: YOUR_NUMBER) {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            name id
            options { id name }
          }
          ... on ProjectV2IterationField {
            name id
            configuration {
              iterations { id title startDate duration }
            }
          }
        }
      }
    }
  }
}'
```

## Usage Examples

```
# Morning standup
/pm-daily

# Plan the next sprint
/pm-sprint plan

# Start a new sprint
/pm-sprint start

# End current sprint (carry over / close incomplete items)
/pm-sprint end

# Check sprint health
/pm-sprint status

# Triage the backlog
/pm-triage

# Sprint retrospective
/pm-retro

# Velocity metrics
/pm-velocity

# Risk report
/pm-risk

# Roadmap view
/pm-roadmap
```

## How It Works

These skills are markdown files (`SKILL.md`) that instruct Claude Code how to interact with the GitHub Projects v2 GraphQL API via the `gh` CLI. Each skill contains:

- Context (org, project, field IDs)
- Step-by-step workflow instructions
- GraphQL queries and mutations
- Output format templates
- Error handling guidance

Claude Code reads these instructions and executes the appropriate `gh` commands to fetch data, make mutations, and present formatted reports.

## License

MIT
