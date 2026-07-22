# CLAUDE.md

Project conventions for Claude Code. These instructions are mandatory and override
default behavior — including the default of adding a Claude co-author trailer to commits.

## Branching

- **Every** change — new feature, bug fix, cleanup, refactor, anything — starts on its
  own branch. Never commit such work directly to `main`.
- Branch off **`main`** (always branch from an up-to-date `main`).
- The branch name is prefixed with **`feature/`**.
- After the prefix, the name is exactly **three words separated by `-`**, chosen to
  describe the goal of the branch as precisely as possible.
- When possible, reuse the wording from the planned commit message.

Examples: `feature/fix-button-spacing`, `feature/add-retry-backoff`.

## Commits & pushing (on the feature branch)

- Commit freely — every meaningful change can be its own commit.
- **Push after every commit.** (No extra consent is needed for these feature-branch
  pushes; the consent rule below applies only to the squash commit.)

### Commit message style

- Headline in the **imperative mood**, starting with a **capital letter**, short but
  clear and easy to understand (the git/GitHub recommended style).
- **Do NOT add any indication that the commit was co-authored by Claude.** No
  `Co-Authored-By: Claude ...` trailer, no "Generated with Claude" line, nothing.
- Below the headline you **may** add a body to further explain the committed changes —
  but only when it genuinely adds benefit. If the headline already says enough, omit it.
- When you do write a body, keep it focused on what changed and why; wrap reasonably.

## Merging back to `main`

This flow has **three separate user prompts**, each needing its own explicit answer:
(1) consent to squash, (2) consent to push the squash, and (3) after the push, whether to
delete the merged feature branch.

- **Until squash consent is given, all changes stay on the feature branch.** Do not
  rebase-and-squash into `main` before the user has explicitly consented to the squash.
- After the squash commit exists, **do not push it** until the user has explicitly
  consented to the push.
- After the squashed `main` is pushed, **ask whether the feature branch should be deleted
  both locally and on the remote.**
- **Never mix these prompts into a single message of yours.** Ask for one at a time. The
  user *may* volunteer several (or all) of the answers at once of their own free will —
  that is fine — but you must never solicit more than one at once.

Steps once squash consent is given:

1. **Rebase** the feature branch on the latest `main`.
2. **Squash merge** the feature branch into `main`.
3. The squash commit message follows the same style rules above (imperative, capital
   first letter, no Claude attribution).
4. The squash message **summarizes all the commits** from the merged branch into one
   coherent message that captures everything relevant — not just the last commit.
5. Then get explicit push consent (the second gate) before pushing the squashed `main`.
6. After the push, ask whether to delete the feature branch locally and on the remote.
   If the user agrees, delete it with:
   - `git branch -D <branch>` — use **`-D`** (force), **not** `-d`: git does not treat a
     squash merge as a real merge, so `-d` would refuse to delete the branch.
   - `git push origin --delete <branch>` — to remove it from the remote.

## Release notes

When asked to generate release notes, write them for a **user deciding whether to
update** — describe what changed for them and why it matters, in plain language, not a
raw list of commits. Follow the structure, style, and delivery rules below.

### Structure

1. **Fork note.** Open with a blockquote naming the upstream project this repo forks, built
   from the upstream repo and URL given in the *Repository context* section:

   ```
   > **Note:** This repository is a fork of [<owner>/<repo>](<upstream-url>) with modifications.
   ```

2. **`### What's New`** heading.

3. **Optional overview.** When the release has one unifying theme or a big headline change,
   add a sentence or two summarizing it before the subsections. Skip it for a grab-bag of
   small fixes and go straight to the subsections.

4. **One `#### <emoji> <title>` subsection per notable change.** Lead each with a single
   topical emoji and a short title (noun phrase or imperative). Explain the change from the
   user's point of view.

5. **`#### 🔧 Under the hood`** — collect the minor, internal, or hard-to-notice changes
   (dependency bumps, refactors, build/CI, subtle correctness fixes) here instead of giving
   each its own top-level subsection.

6. **Closing note** where warranted — e.g. a bold **Updating to this version is strongly
   recommended.** after security fixes, or a one-line "maintenance release, updating is
   optional but recommended" summary.

7. **Full Changelog footer.** Finish every note with a single line reading
   `**Full Changelog**: <url>`, where `<url>` is the GitHub compare link between the
   previous and the new version tag, e.g.
   `https://github.com/chris-karl/valetudo-helper-httpbridge/compare/v<previous>...v<current>`.
   Separate this footer from the last line of actual content above it with two blank lines.

### Style

- **Explain impact, not just mechanics.** Say what a user would observe or need to do, and
  spell out any jargon on first use (e.g. "cross-site scripting (XSS)").
- **Bold the key takeaway** of a subsection or bullet so it stays skimmable.
- **Use a table for renames** and other old→new mappings (`| Old name | New name |`), and
  remind readers to update any scripts that depend on the old names.
- Use short bullet lists for several related points inside one subsection.
- Keep prose tight; link to the README or other docs for step-by-step details rather than
  inlining them.
- **Do not use dashes to join sentences or clauses** in the release text. Where a dash
  would connect two statements, use a period or a comma instead.
- Match the emoji to the topic (e.g. 🍎 macOS, 🔒 security, 🐛 fixes, 📦 packaging/assets,
  🔧 under the hood, ⏳/🕰 timing, 🖥 runtime).

### Delivery

Write the raw Markdown source into a **`.md` file in the session's scratchpad directory**
(the per-session temp directory named in the system prompt; fall back to `$TMPDIR` or
`/tmp` if none is provided) and give the user the file's path. Never deliver the notes
only as chat output: its
terminal rendering adds wrapping and indentation, so text copied from it carries
formatting artifacts, while the file preserves the exact source.

In the file, **every line outside fenced code blocks must start at column 1** (no leading
whitespace) — Markdown renders lines indented by four or more spaces as code blocks, so
stray indentation survives the user's copy-paste (e.g. into GitHub's release editor) and
mangles the formatting there. Verify the written file before handing over the path.

## Tooling

- The **`gh`** tool is **not** expected to be installed and **should not be installed**,
  even if needed. Use alternative ways like **`curl`** instead.

## Keeping this file accurate

- If the user clearly wants something different from what is written here, **offer** to
  update this CLAUDE.md.
- Only make the change after the user **explicitly agrees** to it.

## Repository context

This repo is a fork of [`Hypfer/valetudo-helper-httpbridge`](https://github.com/Hypfer/valetudo-helper-httpbridge).

- **`origin`** (`git@github.com:chris-karl/valetudo-helper-httpbridge.git`) — our own fork and
  the **primary working remote**. All branches, commits, and pushes go here, and `main` tracks
  `origin/main`.
- **`upstream`** (`git@github.com:Hypfer/valetudo-helper-httpbridge.git`) — the original
  project. Use it **only to fetch upstream updates** (e.g. `git fetch upstream`);
  **never push to it.** No local branch tracks `upstream`. Even when an upstream repo
  also has a branch named `main`, an unqualified `main` always means the fork's branch;
  refer to upstream branches explicitly as `upstream/<branch>` (this upstream's default
  branch is `master`, i.e. `upstream/master`).
