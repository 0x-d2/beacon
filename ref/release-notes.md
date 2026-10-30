# Beacon's changelog

Beacon keeps its own log, apart from upstream's: `CHANGELOG.beacon.md` (Turkish, the owner's) and
`CHANGELOG.beacon.en.md` (English), at the repo root.

**Never write Beacon into `CHANGELOG.md`.** That file is Vorssaint's: `build.sh` ships it inside the Mac app, the app
reads it for its in-app release notes (`Core/ReleaseNotes.swift`, `ReleaseDigest`), `Tests/ReleaseDigestTests.swift`
parses it, and `release.yml` takes a version's notes from it.

## When

Every change someone can notice — using Beacon (the iPhone app, the watch app and its complications, Settings ›
Monitor › Watch from iPhone on the Mac, the BeaconKit™ site) or working on it (build, tooling, these docs) — gets its
line **in the same change, before the work is reported done**. A refactor with no visible effect gets none. A fix to
something added the same day that nobody has seen yet edits that day's line instead of adding a "fixed" one.

## The Stop hook

`.claude/settings.json` runs `.claude/hooks/beacon-changelog.py` whenever Claude Code is about to stop. If the working
tree (`git status`, untracked included) has a change newer than the last edit of **both** changelog files, it blocks
the stop once and lists the files. Answer it by adding the lines — or, if nothing listed can be noticed, by saying so in
one line; the next stop goes through (`stop_hook_active`). Only Claude Code runs it: other agents follow the rule
above by hand. Disable it for a session with `/hooks`, never by deleting it.

## Format

```markdown
## 2026-10-30

- **Apple Watch:** Beacon artık Apple Watch'ta: …
- **iPhone:** …
```

- One `## YYYY-MM-DD` per day (the local date of the change), newest day first; under it, newest line first. A day
  that exists gets the new line at its top.
- Each line: `- **Area:** sentence.` Areas, in Turkish / English: **Mac**, **iPhone**, **Apple Watch**,
  **BeaconKit**, **Geliştirme** / **Development**.
- Write for the person who notices it: what changed and where to find it (`Ayarlar › Monitör › iPhone'dan izle`), not
  how it was built — no file names, types, commit hashes or "refactor". One sentence, two at most; wrap at 120 columns
  with a two-space continuation.
- Turkish as in the apps ("sen" form where it addresses the reader, Apple's Turkish terms; `ref/localization.md`),
  with the straight `'` the file already uses (`Mac'in`, `iPhone'dan`).
- The English file has the same line at the same place, with English area names. Both files change together.
