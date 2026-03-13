# Presto Player PM Agent

A set of 7 Claude Code skills that turn Claude into a product manager for GitHub Projects v2. Built for the [Presto Player](https://prestoplayer.com) project, but adaptable to any GitHub org/project.

## Quick Start (3 steps)

### Step 1: Install prerequisites

Make sure you have these installed:

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) — the CLI tool (`npm install -g @anthropic-ai/claude-code`)
- [GitHub CLI](https://cli.github.com/) — `brew install gh` (macOS) or see link for other platforms

### Step 2: Run the setup

```bash
git clone https://github.com/neerajmasai/presto-pm-agent.git
cd presto-pm-agent
./setup.sh
```

The setup script will:
- Verify `gh` is installed and authenticated
- Symlink all 7 skill folders into `~/.claude/skills/`
- Symlinks mean `git pull` automatically updates your skills

### Step 3: Add GitHub project scopes (one-time)

```bash
gh auth refresh -h github.com -s read:project -s project
```

This opens a browser window — approve the additional scopes. You only need to do this once.

### Verify it works

Open Claude Code in any directory and type:

```
/pm-daily
```

You should see a daily sprint briefing with current iteration status.

---

## Let Claude Code Set It Up For You

Copy-paste this prompt into Claude Code and it will handle the entire setup:

```
Clone the repo https://github.com/neerajmasai/presto-pm-agent.git into ~/presto-pm-agent, run the setup.sh script, and then run `gh auth refresh -h github.com -s read:project -s project` to add project scopes. After setup is complete, run /pm-daily to verify everything works.
```

---

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

## Usage Examples

```bash
# Morning standup — run this every day
/pm-daily

# Sprint lifecycle
/pm-sprint plan       # Add backlog items to current/next sprint
/pm-sprint start      # Set up the next sprint
/pm-sprint end        # Close sprint, carry over incomplete items
/pm-sprint status     # Sprint health and burndown

# Backlog management
/pm-triage            # Deduplicate, groom, create issues, split epics, close stale

# Reporting
/pm-retro             # Sprint retrospective with completion stats
/pm-velocity          # Velocity trends across sprints
/pm-risk              # At-risk items and cross-repo dependencies
/pm-roadmap           # Quarterly roadmap and release planning
```

## Typical Daily Workflow

1. Start your day with `/pm-daily` to see sprint status and action items
2. Use `/pm-sprint status` mid-sprint to check burndown
3. Run `/pm-triage` weekly to keep the backlog clean
4. At sprint end, run `/pm-retro` for the retrospective, then `/pm-sprint end` to close it out
5. Use `/pm-sprint plan` to load up the next sprint
6. Run `/pm-velocity` after 2+ sprints to see trends

## Configuration

The skills are pre-configured for the Presto Player project:

| Setting | Value |
|---------|-------|
| **Org** | `prestomade` |
| **Project** | #5 (ID: `PVT_kwDOBL-zrs4BPoD9`) |
| **Repos** | `prestomade/presto-player`, `prestomade/presto-player-pro` |
| **Teams** | Squad 1, Squad 2, Squad 3 |
| **Status flow** | Todo → In Progress → In Review → QA → Done |

### Important: Iterations

Iterations (sprints) must be **pre-created in the GitHub UI** — the API doesn't support creating them:

https://github.com/orgs/prestomade/projects/5/settings → Iteration field → Add iteration

### Adapting for a different project

To use these skills with a different GitHub org/project, update the following in each `skills/pm-*/SKILL.md`:

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

## How It Works

These skills are markdown files (`SKILL.md`) that instruct Claude Code how to interact with the GitHub Projects v2 GraphQL API via the `gh` CLI. Each skill contains:

- **Context** — org, project, field IDs, option IDs
- **Workflow** — step-by-step instructions Claude follows
- **Queries** — GraphQL queries to fetch project data
- **Mutations** — GraphQL mutations to update items
- **Output templates** — formatted report structures
- **Error handling** — what to do when things go wrong

Claude Code reads these instructions at runtime and executes the appropriate `gh` commands to fetch data, make mutations, and present formatted reports. No external services, databases, or API keys needed beyond `gh` authentication.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `/pm-daily` not recognized | Run `./setup.sh` again, or check `ls ~/.claude/skills/pm-daily/SKILL.md` exists |
| "missing required scopes" | Run `gh auth refresh -h github.com -s read:project -s project` |
| "No current iteration" | Create an iteration in GitHub UI: Project Settings → Iteration → Add |
| Empty sprint data | Make sure items are assigned to the current iteration in the project board |
| `gh` not found | Install GitHub CLI: `brew install gh` (macOS) or https://cli.github.com/ |

## Updating

Since the setup script uses symlinks, just pull the latest:

```bash
cd ~/presto-pm-agent
git pull
```

Your skills are automatically updated — no reinstall needed.

## License

MIT
