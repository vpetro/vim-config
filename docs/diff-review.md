# Review notes in Diffview

`lua/diff_review/` adds local review comments to
[diffview.nvim](https://github.com/sindrets/diffview.nvim). While reading a
two-way diff, select a line or a range, write a comment, and reopen it later
beside the same diff. The comments live in one Markdown file per worktree,
written in the review-note thread format that the markdown preview and the
`<leader>c` / `<leader>r` mappings already use, so a pi worker can read the
file and reply in place.

Nothing here writes to the reviewed buffers, the working tree, or the Git
index. There is no GitHub posting.

## Using it

Restart Neovim after installing or updating the config. The leader key is
Space, so `<leader>nc` means Space, then `n`, then `c` in normal mode.

Choose the comparison for the work you want to review:

| Changes to review | Command |
|---|---|
| Committed branch changes since the branch point | `:DiffviewOpen origin/main...HEAD` |
| All current uncommitted changes against HEAD | `:DiffviewOpen HEAD` |
| Branch changes including current uncommitted edits | `:DiffviewOpen origin/main...HEAD --imply-local` |

The plain `origin/main...HEAD` comparison does not include uncommitted edits.

1. Select a file and put the cursor on a real line in either code pane, not
   on the filename in the file panel. For a range, select lines with `V`.
2. Press Space `nc` to create a comment. The Markdown review file opens in
   a bottom split, with insert mode active inside `<!-- PV:  -->`.
3. Type the comment, press Escape, and use `:w`. Use `:q` to close just the
   review split, or Ctrl-W `k` to return to a code pane.
4. To reopen a saved thread, put the cursor on its marked code line and
   press Space `no`. This opens an existing thread; it does not create one.
5. Run `:DiffReviewPath` while the Diffview is open and give that file path
   to pi. Ask it to reply inside the existing threads without changing the
   source code or anchor metadata. Save your own edits before pi edits the
   file.
6. After pi replies, open the thread again with Space `no`. If the saved
   reply is not visible, run `:checktime` with the review buffer selected.
   Space `r` inside a thread adds your reply. Save with `:w`.

If both Neovim and pi have unsaved or conflicting versions, stop and resolve
them before saving. Do not use `:e!` to refresh unfinished typing; it discards
those buffer edits.

Inside a `:DiffviewOpen` view, with the cursor in one of the two diff windows:

| Key / command | Effect |
|---|---|
| `<leader>nc`, `:DiffReviewComment` | Note on the current line. |
| `<leader>nc` in visual mode, `:'<,'>DiffReviewComment` | Note on the selected lines. |
| `<leader>no`, `:DiffReviewOpen` | Open the review file; when the cursor is on an annotated line, land on that note's thread. |
| `:DiffReviewPath` | Print the review file path. |

The mappings are Diffview view keymaps: they exist only on buffers shown in a
Diffview and go away with them. `<leader>nc` on a line opens the review file
in a split under the diff, appends an entry for that line or range, and
leaves the cursor in insert mode inside an empty `<!-- PV:  -->`. Type the
comment and save the file the way you save anything else; nothing is written
until `:w`. Save it, then point a pi worker at the path from
`:DiffReviewPath`, or at the buffer name shown in the split's status line.

Both sides can be annotated. A line removed on the left is recorded as a
left-side note with the left path and revision, so it is never mistaken for a
line of the new file. A side that shows no file (the added or deleted half of
a file, or a binary file) is refused with a message, as are merge-conflict
entries, file-history views, and layouts other than the two-way ones. Context
lines are ordinary targets.

Annotated lines get a `◆` in the sign column of the matching diff window
(`DiffReviewSign`, gold). The marker appears only when the open comparison and
the buffer content are the same ones the note was taken from; see below.

`:DiffReviewOpen` also works outside a Diffview: it finds the worktree of the
current file (or the working directory) with `git rev-parse` and opens that
worktree's review file.

## The review file

One file per worktree, under `stdpath("state")/diff-review/`
(`~/.local/state/nvim/diff-review/`), named `<worktree basename>-<12 hex
chars of sha256(worktree path)>.md`. Two worktrees of the same repo get two
files. The path is the canonical (`realpath`) worktree root reported by
Diffview.

The file starts with a heading and three lines of explanation, then one
entry per note:

````markdown
## `src/render.lua` lines 40-42 (right: working tree)

<!-- diff-review v1 {"id":"3f9a2b1c","root":"/Users/me/code/example","left":":0","right":"LOCAL","side":"b","path":"src/render.lua","lines":[40,42],"sha256":"<64 hex>","created":"2026-09-04T23:35:18-0400"} -->

```lua
local w = width(node)
local h = height(node)
return w * h
```

<!-- PV: Is this the padded or the content box?
> ASTRA: Content box; padding is added in layout.lua.
>> PV: Then name it content_area.
-->
````

- The heading shows the path (in a code span, so `__init__.py` or a path
  with spaces renders as typed), the line or range, and the side: `left` or
  `right`, followed by `working tree`, `index`, `index stage N`, or the first
  ten characters of a commit hash. `unsaved buffer` is added when the diff
  showed a buffer with unsaved changes.
- The anchor comment is one line of JSON and is the machine-readable part.
  `<` and `>` inside it are written as `\u003c` and `\u003e`, so a path can
  never close the comment early. Fields: `id` (eight hex characters, unique
  in the file), `root`, `left` and `right` (the compared revisions: a full
  commit hash, `:N` for an index stage, or `LOCAL` for the working tree),
  `side` (`a` left, `b` right), `path` (the selected side's path, so the old
  name on the left side of a rename), `lines` (`[first, last]`, 1-based,
  inclusive), `sha256` of the side's buffer content at the time (lines joined
  with `\n`), optional `unsaved`, and `created`.
- The fenced excerpt is the selected text. The fence is one backtick longer
  than the longest backtick run in the excerpt, so an excerpt that contains
  fences stays inside.
- The thread is the usual review-note comment. Replies go inside it, one `>`
  per level, as in `pandoc/README.md`. The module never rewrites a thread;
  it only appends new entries and reads existing ones.

Anything else in the file is left alone. Prose between entries, notes without
anchors, and hand edits to headings all survive. A malformed anchor is
reported (see labels below) and skipped, never repaired or deleted.

## Anchors, markers, and stale notes

A note is *current* for a diff window when every one of `root`, `left`,
`right`, `side`, and `path` equals the window's, and `sha256` equals the hash
of the window's buffer content right now. Only current notes get a marker,
and only in their own window; the marker covers the note's whole range. The
range is trusted because the content hash guarantees the buffer is
byte-for-byte the one the note was taken from.

When the review file is open next to a comparison, each entry heading gets a
status label as virtual text:

- `current`: marked in the open diff.
- `outdated: the code changed since this note`: same comparison, side, and
  path, but the buffer content differs. The note and its excerpt are kept;
  nothing is marked, and `:DiffReviewOpen` does not jump to it, because the
  old line numbers may now point at unrelated code.
- `not in the open comparison`: another file, side, revision pair, or
  worktree.
- `malformed anchor: <reason>` on anchor lines that do not parse or fail
  validation.

There is no rebasing or fuzzy reattachment. Editing the working-tree buffer
inside Diffview makes its notes outdated at once (they come back if the edit
is undone); a note taken on an unsaved buffer stays tied to that unsaved
content. Because `left`/`right` are part of the identity, a note taken in
`HEAD~1..HEAD` is not shown in `HEAD~2..HEAD` even when the file content is
identical, and a `:DiffviewOpen` note on a staged file goes stale after the
commit, since its left side was a specific `HEAD` hash. Working tree versus
index notes (`:0` / `LOCAL`) have no hash in their identity and stay current
as long as the content matches.

## Buffer, disk, and the pi worker

The Markdown file is authoritative, and a loaded review buffer is treated as
the newest copy of it: markers and labels are computed from the buffer when
it is loaded, from disk otherwise. Adding a note appends to the buffer and
does not save; `:w` persists it, together with any comment you have typed.

External edits (a pi worker replying in the file) show up through Neovim's
normal `autoread` / `checktime` path; on this Neovim build a file watcher
reloads an unmodified buffer within about 100 ms. When a note is added while
the buffer is loaded and unmodified but the file changed on disk, the module
reloads the buffer first (forcing the reload through `FileChangedShell`), then
appends. When the buffer has unsaved edits *and* the disk changed, it refuses
with a message naming the file and stops; save or `:e!` and try again. The
comparison uses a content hash remembered at the last read or write, not
timestamps. If Neovim's own check cannot see the disk change (same size and
mtime), the module reports that the reload did not happen instead of
appending.

## Design notes

- The module has two files. `notes.lua` is pure: anchor encoding and
  decoding with validation, entry rendering, Markdown parsing, matching, and
  the review path. `init.lua` holds the Diffview integration, the buffer and
  window handling, and the markers. The tests exercise `notes.lua` directly.
- Diffview access is confined to `view_context()` and `rev_id()`. It uses
  `require("diffview.lib").get_current_view()`, the view's class name
  (`DiffView` only), `cur_layout` (name `diff2_*`, windows `a` and `b` with
  `.id` and `.file`), `cur_entry.kind`, `adapter.ctx.toplevel`, and each
  file's `path`, `rev` (`type`, `commit`, `stage` against `RevType`),
  `nulled`, `binary`, and `bufnr`. The side is chosen by the current window
  id, never by parsing `diffview://` buffer names. Refreshes hang off the
  documented `User` autocommands (`DiffviewDiffBufWinEnter`,
  `DiffviewViewEnter`, `DiffviewViewLeave`, `DiffviewViewClosed`) and off
  `nvim_buf_attach` on the buffers involved, so script and API edits are seen
  as well as typed ones.
- Mappings are supplied through `M.keymaps()` for Diffview's `keymaps.view`
  table, so Diffview attaches and detaches them with its other view maps.
  `<leader>n` was free: `init.lua` uses `<leader>c` and `<leader>r` in
  markdown buffers and Diffview uses `<leader>c*` for conflicts, `<leader>e`
  and `<leader>b` for the panel.
- The review split is opened with `nvim_open_win` as a full-width bottom
  split and has `diff`, `scrollbind`, `cursorbind`, and the diff fold
  settings switched off, because a split made from a diff window inherits
  them. Diffview only manages its own windows, so the extra split does not
  disturb file selection.
- Markers are one extmark per note with `end_row`, which this Neovim draws
  on every line of the range. Buffer fingerprints are cached by changedtick.

## Limitations

- Two-way `:DiffviewOpen` comparisons only. File history, merge layouts, and
  `diff1` layouts are refused.
- Notes are tied to a worktree path; moving the worktree starts a new file.
- No reply rendering inside code buffers, no review status, no posting.
- The default tag is `PV`; `setup({ tag = "..." })` changes it, and
  `setup({ dir = "..." })` changes the directory.

## Tests

```sh
nvim --clean --headless -l tests/diff_review_test.lua
```

The test file builds temporary Git repositories, loads the installed
Diffview from `~/.local/share/nvim/site/pack/core/opt/diffview.nvim` (or
`$DIFFVIEW_PATH`), and drives real views: notes on both sides for modified,
added, deleted, renamed, and space-containing paths; source buffers, working
tree, and index left unchanged; markers after closing and reopening the view
and after restarting Neovim (a child `nvim` process); outdated notes after
buffer edits and after a new commit; external replies and the refusal when
the buffer and disk have diverged; two worktrees of one repo; rejection of
the file panel, history views, and malformed anchors; and the buffer-local
mappings. It exits non-zero on failure.
