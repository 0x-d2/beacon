// The commit the catalog was built from, when each file last changed (a component's "Son değişiklik"), the recent
// commits that touched the look (Değişiklikler), and the open revision notes (`kit-revize` issues, with the GitHub CLI
// signed in). Each answers empty rather than failing: a copy without git or gh still collects.
import { execFileSync } from 'node:child_process'

export function git(root: string, ...args: string[]): string {
  try {
    return execFileSync('git', ['-C', root, ...args], { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }).trim()
  } catch {
    return ''
  }
}

/** `owner/name` of the origin remote (GITHUB_REPOSITORY on a runner). */
export function repository(root: string): string {
  if (process.env.GITHUB_REPOSITORY) return process.env.GITHUB_REPOSITORY
  const url = git(root, 'remote', 'get-url', 'origin')
  return url.match(/github\.com[:/](.+?)(?:\.git)?$/)?.[1] ?? '0x-d2/beacon'
}

/** The last commit date of every file under `paths`, from one walk of the history (newest first, so the first wins). */
export function lastChanges(root: string, paths: string[]): Map<string, string> {
  const out = new Map<string, string>()
  let date = ''
  for (const line of git(root, 'log', '--format=%x1e%cI', '--name-only', '--', ...paths).split('\n')) {
    if (line.startsWith('\x1e')) date = line.slice(1)
    else if (line && !out.has(line)) out.set(line, date)
  }
  return out
}

/** The newest commits that touched `paths`, with the files each changed there. */
export function recentChanges(root: string, paths: string[], count = 80) {
  const out: { sha: string; at: string; subject: string; files: string[] }[] = []
  for (const block of git(root, 'log', `-n${count}`, '--format=%x1e%H%x1f%cI%x1f%s', '--name-only', '--', ...paths).split('\x1e')) {
    const [head, ...files] = block.trim().split('\n')
    if (!head) continue
    const [sha, at, subject] = head.split('\x1f')
    out.push({ sha, at, subject, files: files.filter(Boolean) })
  }
  return out
}

/**
 * The open `kit-revize` issues: each one's item is its form's "Öğe" field (.github/ISSUE_TEMPLATE/kit-revize.yml), so
 * a note shows on the page of what it's about.
 */
export function revisionNotes(repo: string): { number: number; title: string; url: string; item: string }[] {
  try {
    const json = execFileSync('gh', ['issue', 'list', '--repo', repo, '--label', 'kit-revize', '--state', 'open', '--limit', '200', '--json', 'number,title,url,body'], {
      encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 20_000,
    })
    return (JSON.parse(json) as { number: number; title: string; url: string; body: string }[]).map((issue) => ({
      number: issue.number,
      title: issue.title,
      url: issue.url,
      item: issue.body.match(/###\s*Öğe\s*\n+([^\n]+)/)?.[1].trim() ?? '',
    }))
  } catch {
    return []
  }
}
