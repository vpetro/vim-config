# Markdown preview

`pandoc/` is the markdown preview for this Neovim config. `<leader>mp` (or
`:MarkdownPreview`) renders the current buffer to a standalone HTML page with
pandoc and opens it in the default browser. Saving the buffer re-renders the
page, and the open tab reloads on its own. Nothing here touches the network:
pandoc runs locally, Mermaid is vendored, the icons and styles are inlined, and
the fonts are the ones installed on the machine.

## Using it

- `<leader>mp` in any buffer renders it and opens the result. The page is
  written under `~/.cache/nvim/mdpreview/`, named after the file plus a short
  hash of its path, so two files with the same name do not collide. The
  directory is safe to delete at any time.
- After the first render, every `:w` on that buffer regenerates the page. The
  tab notices within about a second and reloads, keeping its scroll position.
- The buffer contents go to pandoc, not the file on disk, so unsaved edits are
  included.
- The toolbar at the top right toggles light and dark. The choice is saved in
  the browser. With no saved choice the page follows the OS setting.
- When the document has review notes, the toolbar also shows their count
  (replies included) with previous and next buttons, an `expand`/`collapse`
  button for every thread at once, and a `hide`/`show notes` button that
  takes the notes out of the page so it reads the way a reader would see it.
  From the keyboard: `n` and `p` step through the notes, `e` expands or
  collapses, `h` hides or shows. Open threads and the hidden state survive
  the reload on save.
- `:MarkdownPdf [path]` writes a PDF of the current buffer without a print
  dialog. With no path it goes to `~/Downloads/<name>.pdf`; the file opens
  in Preview when done. It runs headless Chrome over the same rendered page,
  so it needs a Chrome-based browser installed (Chrome, Chromium, Brave, or
  Edge in `/Applications`).

## Printing

The page has a print stylesheet, used both by `:MarkdownPdf` and by the
browser's own print dialog:

- Letter paper, 11pt body, the same 58-character measure centered on the
  page, page numbers at the bottom. Always the light palette, whatever the
  tab's theme.
- Every thread is expanded and the reply toggles are gone. Notes hidden with
  `h` stay hidden, so that is the way to print the document without its
  review.
- Headings stay with the text that follows them, a note's label with its
  first lines, a block with its notes. Code blocks wrap instead of scrolling;
  diagrams shrink to the page instead of scrolling.

One difference between the two paths: Mermaid bakes its colors into the SVG
when it renders, so the browser's print dialog on a dark tab prints dark
diagrams on a white page. `:MarkdownPdf` renders in light mode from the
start; from the browser, switch the toolbar to light before printing.

## Review notes

A review note is an HTML comment that starts with an uppercase tag and a
colon. The tag is the reviewer: initials for a person, the model name for an
agent.

```markdown
The service decides when the scrape happens.

<!-- PV: not sure about this. the box has its own schedule. -->
```

Every other markdown renderer hides it, GitHub included, and `rg "PV:"` finds
all the notes in a tree. In the preview the note is visible:

- A note on its own line renders as a callout under the paragraph, heading,
  list item, code block, or diagram it follows. Several notes on one block
  stack under it. Put a note after the block it refers to; a note in the
  middle of a paragraph splits the paragraph, and an unindented note inside a
  list item ends the list.
- A note inside a sentence renders as an inline highlight.
- The tag is the label, and each participant gets its own accent color in
  order of first appearance, so `PV`, `FABLE`, and `SK` are told apart at a
  glance.
- The note body is markdown. Inline code, emphasis, and links work inside it.
- Tags are one to eight uppercase letters. The code markers `TODO`, `NOTE`,
  `FIXME`, `HACK`, `XXX`, `BUG`, `TBD`, `WIP`, `NB`, and `PS` are not tags,
  so those comments stay hidden, as do comments without a tag.

### Threads

A reply goes inside the note it answers, on its own lines before the closing
`-->`. Every line of the reply starts with one `>` per level of depth, the
way quoted mail does, and the first line continues with the replier's tag.
Replies nest to any depth:

```markdown
<!-- PV: not sure about this. the box has its own schedule.
> FABLE: The box polls every fifteen minutes, but the service decides
> whether that poll turns into a scrape. Both statements are true; the
> sentence should say which one it means.
>> PV: ok, then say the service decides whether a poll scrapes.
> SK: the polling interval is also configurable per source.
-->
```

The count of `>` is the depth; indentation means nothing, so a reply can be
re-indented or re-wrapped freely, and `gq` in nvim keeps the markers (`>` is
already a markdown comment leader there). A quoted blank line (`>`) inside a
reply starts a new paragraph. The root note may stay on one long line, the
way nvim soft-wraps it while typing; replies written by hand or by an agent
are wrapped at about 72 columns. Once a note has replies, `-->` goes on its
own line at the indentation of `<!--`. Blockquotes cannot be used inside a
note, since `>` is the depth marker there.

In the preview a thread starts collapsed: the root note shows with a
`3 replies` toggle under it. Click it to open the thread, or step onto one
of its replies with `n`; `expand` in the toolbar opens every thread.

In a markdown buffer (defined in `init.lua`):

- `<leader>c` inserts an empty `<!-- PV:  -->` on the next line, indented
  to the content of the current list item when there is one, with the
  cursor inside it.
- `<leader>r` replies to the note under the cursor: it adds a `> PV: ` line
  with one more marker than that note, after its existing replies, and
  moves `-->` to its own line if the note was a single line. On the closing
  `-->` line it replies to the root. Outside a note it behaves like
  `<leader>c`.

## Layout

On screen, body text uses the available window width with adaptive side
gutters, centered up to a 1152px maximum. The prose column uses about 90% of
900px and 1080px portrait windows. The type still grows with the viewport:
16px in a small window, about 20px on a 16" MacBook, 22px on a large
external display. Print keeps its separate 58ch measure and 11pt type.
Diagrams may bleed past the column on both sides; code blocks and tables
stay in the column and scroll sideways when wider. Review notes render in
the column under their block.

Paragraphs use `text-wrap: pretty`, headings use `text-wrap: balance`, and long
URLs wrap instead of overflowing.

## Links

A link gets a small icon of the service it points to, in the link color, in
front of its label. Hosts covered: GitHub, Linear, Google Docs, Sheets and
Slides (told apart by path), Drive, Meet, Calendar, Gmail, Google Cloud, Slack,
Jira and Confluence (by path on `atlassian.net`), Datadog, Figma, YouTube,
arXiv, Reddit, Wikipedia, X, npm, PyPI, Stack Overflow, Notion, Chromatic,
Storybook, and Yahoo (`*.yahoo.com` and `*.yahooinc.com`). Links to any other
host have no icon. `AGENTS.md` describes how to add a service.

## Diagrams

A ` ```mermaid ` fence renders with the vendored Mermaid (`mermaid.min.js`,
version 11.17.2). The diagram theme is built from the page palette, so diagrams
match light or dark and re-render when the theme toggles. Flowchart edges use a
curve chosen from the diagram's direction: `bumpY` for `TB` and `TD`, `bumpX`
for `LR` and `RL`. A diagram with its own `%%{init}%%` directive or YAML
frontmatter is left as written. A diagram that would have to shrink by more
than about a quarter to fit keeps its natural size and scrolls inside its box,
so its text stays legible.

Two authoring habits improve the output. Keep decision-diamond text short,
because Mermaid sizes the diamond to the text and a long question becomes a
huge shape. Keep the number of edges entering a subgraph from above low,
because Mermaid draws edges over subgraph titles.

## Also rendered

GitHub task lists, tables with zebra rows, GitHub alerts (`> [!NOTE]` and the
other four), footnotes, fenced code with syntax highlighting in the editor
palette, and images with paths relative to the markdown file.

YAML frontmatter is not shown as text. A `title` in it becomes the document
heading, with `id`, `status`, and `date` in a small line under it when they
are present.

## Files

| File | Role |
|---|---|
| `preview.html` | pandoc template: palettes, layout, toolbar, Mermaid setup, link icons, reload poller |
| `pv.lua` | pandoc Lua filter: review notes and threads, Mermaid fences, image paths, link service tags |
| `mermaid.min.js` | vendored Mermaid |
| `sample.md` | fixture that exercises every feature; open it after changing the template |
| `pdfpages.js` | JXA helper that renders the pages of a PDF to PNG, for checking print output |
| `README.md`, `AGENTS.md` | this file, and the notes for agents editing the preview |

The Neovim side is the `mdpreview` block in `init.lua`. It builds the pandoc
command, writes the page and a small stamp file the page polls for reloads,
registers the `BufWritePost` autocmd for the previewed buffer, and runs
headless Chrome for `:MarkdownPdf`.

## Customizing

The knobs are CSS custom properties at the top of `preview.html`:

- `--measure` (line length), `--gutter`, and the `font-size` clamp on `html`.
- Two palettes, `:root` for light and `:root[data-theme="dark"]` for dark: page
  colors, the heading ramp, code token colors, note colors, the table stripe,
  and the `--dg-*` diagram colors. The second, third, and fourth participant
  in a document take their accent from the heading ramp
  (`.pv[data-who="1"]` and following).
- `--sans` and `--mono` font stacks. Body text is Centra No2 when it is
  installed, then Avenir Next, then the system font.

Adding a link icon or changing the note tag rule means editing `pv.lua` and the
icon CSS. `AGENTS.md` has the procedure.

## Requirements

pandoc 3.x on `PATH` (Lua filters and the `gfm` reader with alerts), Neovim
0.10 or newer (`vim.system`, `vim.ui.open`), and a browser with `:has()`,
`color-mix()`, and CSS masks (Safari 16.4 or newer, or any current Chrome). The
reload poller loads a local script from a `file://` page, which Chrome and
Safari both allow. `:MarkdownPdf` needs a Chrome-based browser in
`/Applications`; page numbers in the PDF need Chrome 131 or newer.
