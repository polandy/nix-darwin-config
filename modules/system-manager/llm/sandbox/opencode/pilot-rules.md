# Sandbox rules (override anything in the project instructions)

You run unattended in an isolated sandbox. Nobody answers questions; decide and proceed.

- There is no network except the model API. Dependencies are already installed in
  `node_modules`. Do not run `bun install`, `bun add`, `bun update`, `npm install` or similar:
  they fail and waste time. If the task needs a new or upgraded dependency, say so in your
  final answer instead.
- Do not commit, branch, push or change git config. Your changes in the working tree are
  collected automatically when you finish.
- Ignore workflow steps from the project instructions about worktrees, pull requests, reviews,
  owner verification or waiting for a go-ahead. They do not apply here.
- Ignore the general sandbox notes about `oc-preview`, `oc-shot` and mockups; this run is a
  coding task only.
- End-to-end tests (Playwright) cannot run here: no browsers are installed. Skip them.
- Before you finish, run the project's own checks and fix what you broke. For a Bun project
  that is `bun run test`, `bun run check` and `bun run lint` (see `package.json`).
- Finish with a short summary: what you changed, which checks you ran and their result.
