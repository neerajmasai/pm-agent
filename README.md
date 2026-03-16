# GitHub PM Agent for Claude Code

A set of 8 Claude Code skills that turn Claude into a project manager for **any GitHub Projects V2** board. Manage sprints, run standups, track risks, plan roadmaps, and more — all from your terminal.

## Quick Start

### 1. Install prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) — `npm install -g @anthropic-ai/claude-code`
- [GitHub CLI](https://cli.github.com/) — `brew install gh` (macOS) or see link for other platforms

### 2. Run the setup

```bash
git clone https://github.com/neerajmasai/pm-agent.git
cd pm-agent
./setup.sh
```

The setup script will:
- Verify `gh` is installed and authenticated
- Symlink all 8 skill folders into `~/.claude/skills/`
- Symlinks mean `git pull` automatically updates your skills

### 3. Add GitHub project scopes (one-time)

```bash
gh auth refresh -h github.com -s read:project -s project
```

### 4. Connect your project

Open Claude Code and run:

```
/pm-setup https://github.com/orgs/your-org/projects/5
```

This auto-discovers your project's fields, statuses, teams, iterations, and repos. Config is saved to `~/.claude/pm-config.json` — all other skills read from it automatically.

Works with both **organization** and **user** projects:
- `https://github.com/orgs/<org>/projects/<number>`
- `https://github.com/users/<user>/projects/<number>`

### 5. Verify it works

```
/pm-daily
```

You should see a daily sprint briefing with current iteration status.

---

## Let Claude Code Set It Up For You

Copy-paste this prompt into Claude Code:

```
Clone the repo https://github.com/neerajmasai/pm-agent.git into ~/pm-agent, run the setup.sh script, then run `gh auth refresh -h github.com -s read:project -s project` to add project scopes. After setup, run /pm-setup with my project URL to configure it.
```

---

## Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| **Setup** | `/pm-setup` | Configure project — auto-discover fields, repos, statuses from a URL |
| **Daily Briefing** | `/pm-daily` | Sprint status, items by column, blockers, new issues, action items |
| **Sprint Management** | `/pm-sprint` | Start, end, plan sprints. Add/remove items, check status |
| **Backlog Triage** | `/pm-triage` | Deduplicate issues, groom backlog, create issues, split epics, close stale |
| **Roadmap** | `/pm-roadmap` | Quarterly view, release plan with changelog, milestone tracking |
| **Retrospective** | `/pm-retro` | Completion stats, carried-over items, scope creep, per-team breakdown |
| **Velocity** | `/pm-velocity` | Sprint velocity trends, team workload, scope creep tracking, cross-repo split |
| **Risk Tracking** | `/pm-risk` | At-risk items, cross-repo dependencies, stakeholder status updates |

## Usage Examples

```bash
# One-time setup — connect to any GitHub project
/pm-setup https://github.com/orgs/acme/projects/3

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

# Switch to a different project anytime
/pm-setup https://github.com/users/myuser/projects/1
```

## Typical Daily Workflow

1. Start your day with `/pm-daily` to see sprint status and action items
2. Use `/pm-sprint status` mid-sprint to check burndown
3. Run `/pm-triage` weekly to keep the backlog clean
4. At sprint end, run `/pm-retro` for the retrospective, then `/pm-sprint end` to close it out
5. Use `/pm-sprint plan` to load up the next sprint
6. Run `/pm-velocity` after 2+ sprints to see trends

## How Configuration Works

### Auto-Discovery via `/pm-setup`

When you run `/pm-setup` with a project URL, it:

1. **Parses the URL** to determine org/user and project number
2. **Introspects the project** via GraphQL to discover all fields and their options
3. **Identifies linked repos** from existing project items
4. **Maps fields to roles** — Status, Team, Iteration, Target Date, Quarter
5. **Confirms the status flow** with you (e.g., Todo → In Progress → Done)
6. **Writes `~/.claude/pm-config.json`** — the shared config all skills read from

### Optional Fields

Not every project has the same fields. Skills handle this gracefully:

| Field | If Missing |
|-------|-----------|
| **Status** | Required — setup won't proceed without it |
| **Team** | Team breakdowns skipped |
| **Iteration** | Sprint-based features disabled; shows all non-done items |
| **Target Date** | Deadline warnings skipped |
| **Quarter** | Roadmap groups by iteration or flat list |

### Multi-Repo Support

Projects tracking multiple repos get:
- Cross-repo dependency detection (in `/pm-risk`)
- Per-repo split in velocity reports (in `/pm-velocity`)
- Repo prefix on issue numbers (e.g., `frontend#42`, `backend#15`)

Single-repo projects get cleaner output with no prefix.

### Switching Projects

Run `/pm-setup` again with a different URL:

```
/pm-setup https://github.com/orgs/other-org/projects/2
```

### Important: Iterations

Iterations (sprints) must be **pre-created in the GitHub UI** — the API doesn't support creating them. Go to your project settings → Iteration field → Add iteration.

## How It Works

These skills are markdown files (`SKILL.md`) that instruct Claude Code how to interact with the GitHub Projects V2 GraphQL API via the `gh` CLI. Each skill contains:

- **Config loading** — reads project context from `~/.claude/pm-config.json`
- **Workflow** — step-by-step instructions Claude follows
- **Queries** — GraphQL queries built dynamically from config
- **Mutations** — GraphQL mutations to update items
- **Output templates** — formatted report structures
- **Error handling** — graceful degradation for missing fields

No external services, databases, or API keys needed beyond `gh` authentication.

## Directory Structure

```
skills/
├── pm-setup/
│   ├── SKILL.md                  # Setup wizard
│   └── references/
│       └── config-loader.md      # Shared config docs (referenced by all skills)
├── pm-daily/SKILL.md             # Daily standup briefing
├── pm-sprint/SKILL.md            # Sprint lifecycle management
├── pm-risk/SKILL.md              # Risk & dependency tracking
├── pm-velocity/SKILL.md          # Velocity metrics & reporting
├── pm-triage/SKILL.md            # Backlog refinement & grooming
├── pm-retro/SKILL.md             # Sprint retrospective
└── pm-roadmap/SKILL.md           # Roadmap & release planning
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `/pm-daily` says "No project configured" | Run `/pm-setup` with your project URL first |
| `/pm-daily` not recognized | Run `./setup.sh` again, or check `ls ~/.claude/skills/pm-daily/SKILL.md` |
| "missing required scopes" | `gh auth refresh -h github.com -s read:project -s project` |
| "No current iteration" | Create an iteration in GitHub UI: Project Settings → Iteration → Add |
| Empty sprint data | Make sure items are assigned to the current iteration |
| `gh` not found | `brew install gh` or https://cli.github.com/ |
| "Could not resolve to a ProjectV2" | Config may be stale — re-run `/pm-setup` |

## Updating

Since the setup script uses symlinks, just pull the latest:

```bash
cd ~/pm-agent   # or wherever you cloned it
git pull
```

## License

MIT
