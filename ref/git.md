# Git, PRs and the workspace

## The repos

- `origin` is the owner's fork, `github.com/0x-d2/beacon`. `upstream` is Vorssaint, `vorssaint/vorssaint-utils`: a
  local remote that fetches `main` and tags only, with pushing disabled (`pushurl DISABLED`). With two remotes `gh`
  needs to be told which repo is meant: `gh repo set-default 0x-d2/beacon` (done; it lives in the shared git config).
- **`main` is upstream's `main` and nothing else.** Never commit to it, merge into it or open a PR against it; the
  Upstream sync workflow moves it (below).
- **`custom` is Beacon** and the default branch: every piece of work branches from `custom` (or from the branch it
  builds on) and targets it — `gh pr create --base custom`, and `custom` as the Conductor workspace's target. The first
  stack (#1 kit site ← #2 renders ← #3 Mac service ← #4 iPhone app, with #5 inside #4) was fast-forwarded into
  `custom` on 2026-10-30, its commits unchanged.
- Branch names: `0x-d2/<topic>`. `upstream-sync` is the workflow's.
- PRs merge with a **merge commit** only (squash and rebase are off in the repo settings; the commit takes the PR's
  title and body). A squashed upstream merge would bring the same commits back as conflicts on the next update.
- The ruleset "main and custom" keeps both from being deleted or force-pushed.

## Commits

- **Only when the owner asks.** Same for push and PRs.
- Message: `type(scope): summary`, lower case, the summary saying what the user gets
  (`feat(ios): add Beacon, the iPhone app that watches the Mac`, `fix(monitor): list paired phones the way the login
  keychain allows`). Types: `feat`, `fix`, `refactor`, `docs`, `chore`. Scopes in use: `monitor` (Mac side), `ios`,
  `watch`, `kit`, `agents` (these docs).
- Body: plain prose paragraphs wrapped at ~72 columns — what changed, how it behaves, why — in the code comments' voice.
  End with the attribution line the session gives (`Co-Authored-By: …`); a PR body ends with its line too.
- One independently useful change per commit; don't mix unrelated fixes in. The commit carries its changelog lines
  (`ref/release-notes.md`).

## Never committed

`iOS/Beacon.xcodeproj/` (XcodeGen writes it), `iOS/Config/Local.xcconfig` (the signing team), `build/`, `dist/`,
`docs/logs/`, `web/public/{data,renders}`, `web/node_modules`, `web/dist`, signing material (`*.p12`, `*.p8`, …),
`.context/`. Generated Info.plists and entitlements under `iOS/` **are** committed (XcodeGen rewrites them from
`project.yml`; commit the result).

## Upstream updates

- `.github/workflows/upstream-sync.yml` runs every day at 07:00 Turkish time and on demand
  (`gh workflow run upstream-sync.yml`). It fast-forwards `main` to upstream (the `merge-upstream` API), and when
  `custom` lacks something `main` has, points `upstream-sync` at `main` and opens the PR
  "chore(upstream): merge Vorssaint's latest" into `custom` — or moves the open one forward. A failed run arrives as
  GitHub's mail.
- It runs on the owner's fine-grained token in the `UPSTREAM_SYNC_TOKEN` secret: this repo only, **Contents** and
  **Pull requests** read and write, renewed when it expires (`gh secret set UPSTREAM_SYNC_TOKEN`). GITHUB_TOKEN won't
  do: the PRs it opens start no CI.
- The token is left **without the Workflows permission** on purpose. A workflow that reaches `main` runs here straight
  away, with the repo's secrets within reach, so GitHub refuses an upstream change under
  `.github/workflows/` and the run fails naming those files. Read the change
  (`git fetch upstream && git log -p origin/main..upstream/main -- .github/workflows`); if it's fine, take it by hand:
  `git push origin upstream/main:main`, then `git push --force origin upstream/main:upstream-sync` (only with no
  `upstream-sync` PR open) and `gh workflow run upstream-sync.yml` for the PR.
- Merging the PR: wait for CI, look at the upstream files Beacon hooks into — under `Sources/Vorssaint/`:
  `Services/SystemMonitor/SystemMonitor.swift`, `Core/Defaults.swift`, `Core/SettingsBackupSupport.swift`,
  `App/FeatureRuntime.swift`, `UI/Settings/MonitorSettings.swift`, `main.swift`; and `Tests/MetricsTests.swift`,
  `Tests/SystemMonitorPlanTests.swift`, `build.sh`, `.github/workflows/ci.yml`, `Resources/Info.plist` with the
  `InfoPlist.strings`, `.gitignore` — then build and test the Mac side (`ref/build-and-test.md`). CI covers the Mac
  app and the kit, not iOS.
- Conflicts are resolved on `upstream-sync`, never on `main`: GitHub's "Resolve conflicts" commits there, or locally
  `git switch upstream-sync && git merge origin/custom`, fix, push.
- A branch made from an older `custom` takes the update with `git merge origin/custom`.
- By hand, without the workflow: GitHub's "Sync fork" on `main` only (on `custom` it would merge upstream without a
  PR), then `gh pr create --base custom --head upstream-sync` after the push above.
- GitHub turns a public repo's schedules off after 60 days without activity: `gh workflow enable upstream-sync.yml`.
  Upstream's own bot, "Issue fix status", is disabled here; the fork has no issues.

## Upstream

`AGENTS.md`, `CLAUDE.md`, `ref/`, `.claude/` (the project's Claude Code hooks), `CHANGELOG.beacon*.md` and
`upstream-sync.yml` are this fork's. Upstream's `.gitignore` keeps agent notes local; the fork tracks them. A PR to
`vorssaint/vorssaint-utils` branches from `main`, leaves them, `iOS/`, `web/` and the kit out, and follows upstream's
`CONTRIBUTING.md` and `docs/AI-CONTRIBUTIONS.md`.

## The Conductor workspace

- Each workspace is a git worktree with its own branch; the stash is shared between worktrees — never a bare
  `git stash`/`pop`; set work aside with a WIP commit instead.
- `.context/` (git-ignored) is the workspace's scratch space: screenshots (`.context/<name>.png`, shown in the final
  message), plans, attachments the owner drops (`.context/attachments/`), throwaway harnesses (`.context/spikes/`).
- Simulators booted by another workspace (names with that workspace's city, e.g. "Podgorica") are not yours: don't
  shut them down or install on them.
