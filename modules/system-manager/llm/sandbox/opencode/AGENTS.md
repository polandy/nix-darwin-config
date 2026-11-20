# Working environment: sandbox

You run in an isolated sandbox. The repo is at `/work`.

- No network except the model API. Uploads, downloads, `curl`, package registries, web search
  and publishing files (pastebins, gists, artifacts, base64 in the chat) do not work. Do not
  try, and do not look for workarounds.
- **Always store results as a file in the repo**, then name the path, and you are done.
  andy looks at the files and publishes them if needed.
  - Mockups and concepts: `docs/dev/mockups/<name>.html`, a single file, without external
    fonts, CDNs or images from the web (they do not load when viewed).
  - Screenshots: `docs/dev/mockups/screenshots/<name>.png`.
- Viewing the app locally (only in this repo, only on 127.0.0.1):
  - `oc-preview start` starts the preview with sample data and prints the URL.
    `oc-preview status|log|stop`.
  - `oc-shot <url-or-file> <out.png>` takes a screenshot. Options: `--full` (whole
    page), `--mobile` (390 px, touch), `--width N --height N`, `--dark` / `--light`,
    `--click '<css-selector>'` (repeatable, e.g. to expand a row),
    `--wait <ms>`. Check your own mockup with
    `oc-shot docs/dev/mockups/<name>.html /tmp/check.png`. You can view images with the
    Read tool.
  - skipper-cd starts in the Deploys view. For the Stacks view, first
    `--click 'button[data-view="stacks"]'`; expand a row with
    `--click '.roster-row[data-stack="<name>"]'`.
- Before you finish, `oc-preview stop`.
- GitHub: `git push` is blocked; push, open and merge your PR with `oc-pr` instead (the token stays
  on the host):
  - `oc-pr push` pushes the current feature branch (never `main`/`master`, no force push, no tags).
  - `oc-pr pr-create [--title <text>] [--body-file <file>]` opens the PR (default: from the commits).
  - `oc-pr merge <pr>` squash-merges only when all checks pass and the latest "PR quality review"
    says ready and is newer than the head. Otherwise it names the reason; do not retry in a loop.
