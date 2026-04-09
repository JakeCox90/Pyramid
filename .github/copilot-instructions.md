This project uses the Agent Framework for multi-agent development.

Read these files before starting any work:
- `AGENT.md` — shared playbook (task flow, behaviour rules, architecture principles)
- `project.yaml` — project configuration (tooling, platform, active agents)

When working as a specific agent role, read the corresponding file in `agents/{role}/CLAUDE.md`.

Key rules from the framework:
- Never assume or fabricate information — look it up or ask
- Try to fix errors yourself (up to 3 attempts) before escalating
- All code changes go via Pull Request — never push directly to main
- Follow the commit convention: `{type}({team_key}-{id}): {description}`
- Read `docs/domain-rules/` before writing any business logic
- Add `[HUMAN REVIEW]` label to PRs touching critical-path code
