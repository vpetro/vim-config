# pandoc/ markdown preview: notes for agents

Read `README.md` first for what the preview does. This file has the reasons
behind the design, the constraints that must survive an edit, the approaches
that were tried and failed, and the commands that verify a change. The code
files have no comments by Petro's rule, so the rationale lives here. Keep this
file current when you change a rule it describes.

## Pipeline

1. `init.lua`, the `mdpreview` block. `:MarkdownPreview` / `<leader>mp` calls
   `render(bufnr, vim.ui.open)`. `render` calls the shared `pandoc()` helper,
   which pipes the buffer lines to pandoc on stdin and passes:
   `--from gfm --to html5 --standalone --template pandoc/preview.html
   --lua-filter pandoc/pv.lua --metadata pagetitle=<file name>
   --metadata srcdir=<file dir> --variable mermaid=<abs path to mermaid.min.js>
   --output ~/.cache/nvim/mdpreview/<name>-<sha256(path)[1..8]>.html`, plus
   the caller's variables: `render` adds `stamp=<time>-<counter>` and
   `stampfile=<abs path>`. On success it writes `<same>.stamp.js` containing
   `window.__mdvStamp = "<stamp>";`, after the HTML exists. The first call also
   registers a buffer-local `BufWritePost` autocmd that calls `render(bufnr)`
   with no opener.
   `:MarkdownPdf [path]` calls `mdpreview.pdf`, which renders the same way to
   `<same>.print.html` with `theme=light` and no stamp variables (so no
   poller), then runs the first Chrome-based browser found in `/Applications`
   with `--headless=new --disable-gpu --no-pdf-header-footer
   --virtual-time-budget=6000 --print-to-pdf=<pdf> file://<print html>`,
   and opens the PDF with `vim.ui.open`. The default output is
   `~/Downloads/<name>.pdf`.
2. `pv.lua` runs as three filter passes, in order: `Meta` (captures `srcdir`),
   the element pass (`RawBlock`, `RawInline`, `CodeBlock`, `Image`, `Link`),
   then `Blocks` (`annotate`). The split is required: `annotate` must see the
   `Div.pv` elements the element pass produced. Both passes traverse
   `topdown`. For the element pass that is what makes participant colors
   follow document order and lets links and images inside a note body get
   the same treatment as the rest of the page (the returned `Div` is
   traversed). For the `Blocks` pass it is what allows `skip_note` to return
   `false` for a `Div.pv`, so `annotate` never runs inside a note, where a
   reply `Div` after a paragraph would otherwise be wrapped as a note on that
   paragraph.
3. `preview.html` is a pandoc template. `$pagetitle$` and `$body$` come from
   pandoc; `$mermaid$`, `$stamp$`, `$stampfile$` come from `--variable` and are
   inserted raw. `--metadata` values are HTML-escaped and YAML-parsed;
   `--variable` values are neither. Keep paths in variables and titles in
   metadata.
4. In the browser: an inline `<head>` script sets `data-theme` before paint;
   the main script wires the toolbar, adds the reply toggles to threads,
   renders Mermaid, and navigates notes; the poller script reloads the page
   when the stamp changes.
5. Two markdown mappings in `init.lua` write notes: `<leader>c`
   (`md_insert_pv_comment`) opens a root note under the cursor line, adding
   the list marker's width to the indent when the line starts a list item so
   the note stays inside the item; `<leader>r` (`md_insert_pv_reply`) finds
   the enclosing comment by scanning up for `<!--` (a `-->` above the cursor
   means there is none), takes the depth of the nearest tag line at or above
   the cursor, splits `-->` onto its own line if it shares a line with text,
   and inserts `> PV: ` with depth + 1 markers before the first later tag
   line of depth <= that depth, or before `-->`. On the `-->` line the depth
   is 0, so the reply answers the root. Outside a comment it falls through
   to `md_insert_pv_comment`.

## Constraints that must survive an edit

### Offline, always

Petro writes without network access. No CDN, no web fonts, no fetches at render
or view time. Mermaid is vendored (`mermaid.min.js`, 3.4 MB, from the `mermaid`
npm package, `dist/mermaid.min.js`). Icons are inlined data URIs. Fonts are
system-installed with fallbacks. A change that adds a network dependency is
wrong even if it works on the first try.

Vendoring lives in the repo, not in a setup step. The plugin this replaced broke
because its build output sat outside git and vanished on a fresh clone. Anything
the template needs must arrive with `git clone`.

### The reload protocol

A `file://` page cannot `fetch()` a local file (Chrome blocks it), but it can
load a local `<script src="file://...">`. The page therefore polls by appending
a script tag for `<name>.stamp.js?t=<now>` once a second and calls
`location.reload()` when `window.__mdvStamp` differs from the stamp baked into
the page. Verified in headless Chrome. Write the stamp file only after the HTML
is complete; the reverse order can reload a stale page. The stamp is
`os.time() .. "-" .. renders`; do not use `vim.uv.hrtime()`, which `tostring`
formats in scientific notation.

### Viewport-responsive screen width

On screen, prose uses about 90% of 900px and 1080px portrait windows, with a
1152px upper limit. `--measure: 1152px` caps `main`'s content width;
`--gutter: clamp(1rem, 5vw, 3rem)` sets its side padding. The type still
scales with the viewport
(`html { font-size: clamp(1rem, 0.75rem + 0.45vw, 1.375rem) }`).

Keep these layout variables inside `@media screen`. Print defines its own
58ch measure and zero gutter. Do not restore a fixed character-count cap on
screen: Petro wants wider prose in portrait windows.

The `ch` unit is the width of the digit zero, which is wider than the average
letter in Centra No2 and SF Pro. Inspect computed content widths and font
sizes with the installed fonts when changing the layout; do not infer
character counts from `ch`. Recheck print separately.

### The layout model

`main` is a centered `flow-root` block with `max-width: var(--measure)`.
Everything renders in that column. `pre.mermaid` is the one exception: at
the top level, or inside an `.annotated` wrapper, it gets a symmetric
negative `margin-inline` (`--bleed`) capped at 40% of the measure per side
and at the viewport edge. Code blocks and tables stay in the column and
scroll.

Review notes render under the block they follow. `annotate` wraps
`[block, .notes]` in a `Div.annotated`; the wrapper zeroes the block's
bottom margin so the notes sit close under it and then supplies the
paragraph spacing itself. Inside `li` the wrapper has no bottom margin
because list items space themselves.

Until 2026-09-03 notes floated in a right-hand margin column, with the
wrapper in `[.notes, block]` order and wide content breaking out into the
margin when no note was beside it. That was dropped when notes became
threads: a reply is a paragraph or more, and a column of `clamp(16rem, 22vw,
24rem)` cannot hold a thread. Petro asked for threads under the text. If a
margin ever comes back, the failure modes that shaped the old version were:
a CSS grid leaves gaps in the prose under short paragraphs with long notes;
a float reaching the margin through a negative right margin is ignored by
Chrome's float avoidance, so wide blocks overlap it; a margin made of `main`
padding puts the float outside the containing block of the breakout
elements, with the same overlap. The margin has to be inside `main`'s
content box and the breakout elements need `width: auto`.

### Review note rules

A comment is a note when its first non-blank line, after `unquote`, matches
`^%s*(%u+):%s?(.*)$` with a tag of one to eight uppercase letters that is
not in the `markers` denylist (`TODO`, `NOTE`, `FIXME`, `HACK`, `XXX`,
`BUG`, `TBD`, `WIP`, `NB`, `PS`). The old rule was one to three letters,
which excluded the markers by length; it also excluded `FABLE`, which is how
the agent's replies went missing from the preview. The denylist is the
replacement for the length rule. The `RawBlock` text from the `gfm` reader
ends with a newline, which is why the outer pattern allows trailing
whitespace.

`parse_thread` turns one comment into a tree. `unquote` strips leading
`>` markers from a line (whitespace between them allowed) and one space
after the last one, returning the count as the line's depth. A line whose
unquoted text matches the tag pattern starts a reply at that depth,
attached through a stack: pop while the top's depth is greater than or
equal to the new depth, then attach to the top. The root is depth 0 and is
never popped, so an unmarked tag line attaches to the root, and a reply
that skips a level attaches to the nearest shallower node. Lines without a
tag are continuation lines of the most recent node, markers stripped
whatever their count. `body_of` then removes the common leading whitespace
of a node's continuation lines, so a nested markdown list inside a reply
keeps its relative indentation. The body is parsed with
`pandoc.read(body, "gfm")`.

Markers replaced indentation on 2026-09-03, after one round of use. Petro
found counting spaces to reply at depth impractical, and indentation was
fragile: a formatter or a stray re-indent changes the tree, and four
leading spaces are a code block to markdown. `>` was chosen over other
glyphs because everyone reads nested `>` as a thread, nvim already treats
`>` as a markdown comment leader (`comments=...,n:>`, so `gq` keeps the
markers when re-wrapping), and a flat Google Docs style thread falls out
by everyone using one `>`. Two accepted costs: a blockquote inside a note
body is impossible, and the count runs opposite to mail, where more `>`
means older text.

A continuation line that begins with an all-caps word and a colon (`URL:`)
will be read as a reply. The denylist covers the common code markers; for
anything else, rewrap the line. This is accepted: the alternative, a
registry of known participants, would break the "anyone can reply" property.

Block notes become `Div.pv[data-tag][data-who]`, inline notes `Span.pv`, and
replies are nested `Div.pv` (or `Span.pv`) inside their parent's content,
after the body blocks. `data-who` is the participant's index in order of
first appearance in the document, modulo 4, assigned in `note_attrs` before
the replies are built so the root's author gets the first color. The CSS
maps index 1 to 3 onto the heading ramp (`--h2`, `--h4`, `--h1`) by
redefining `--note-accent` on the element; index 0 keeps the note gold.
Order of appearance was chosen over a per-tag color table so that any tag
works and the author who comments first (Petro, in practice) is always gold.

`annotate` wraps each non-note block followed by one or more notes into
`Div.annotated{ block, Div.notes{...} }`; a note with no preceding block is
left alone and renders as a standalone callout. Threads render as nested
callouts: the root has the note background and a 3px accent stripe; each
reply is indented with its own 2px stripe and no background of its own.
Note text is 0.88rem at line-height 1.5; the threads are long and this is
the smallest size that still reads as body text rather than a caption.

### Collapsed threads and hidden notes

Long threads can overwhelm the text they refer to. In an early render, a
35-line thread followed an 8-line paragraph, making the section mostly
commentary. The margin never had that problem because the text
stayed continuous. The answer is not a return to the margin (a thread does
not fit one) but control over what shows.

The main script finds every thread (a `div.pv` with no `.pv` ancestor and
at least one `.pv` descendant), inserts a `button.replies` before its first
reply, and toggles `collapsed` on the root; `div.pv.collapsed > div.pv` is
`display: none`, so the whole subtree folds with the root. The default is
collapsed. A thread that has been opened stays open across the reload on
save: `setOpen` records the set of open threads in `sessionStorage` under
`mdv-open:<pathname>`, keyed by tag plus the first 80 characters of the
root's own text (children and the button excluded), which survives edits
elsewhere in the document and re-collapses only when the root text itself
changes. `sessionStorage` rather than `localStorage` because this is a
viewing state for one tab, and it should reset when the tab closes;
`file://` pages get it in Chrome and Safari like any other origin. Note
navigation (`goTo`) opens the thread a reply sits in before scrolling to
it, and shows the notes if they are hidden.

`hide` adds `no-notes` to `body`: `.pv` and `.notes` become `display:
none`, and `.annotated` becomes `display: contents` so the wrapped block
returns to `main`'s flow with its own margins. The rule that zeroes a
block's bottom margin inside `.annotated` is scoped to `body:not(.no-notes)`
for the same reason. Hidden state is remembered the same way as open
threads (`mdv-notes-hidden:<pathname>`). The toolbar hides the counter,
the arrows, and the fold button while notes are hidden, leaving only
`show notes`. Keys: `e` for fold, `h` for hide, next to the existing `n`
and `p`.

### Mermaid

- `theme: "base"` with every `themeVariables` color read from the `--dg-*` and
  page CSS variables at render time (`diagramConfig()`), so diagrams follow the
  theme toggle. Mermaid accepts hex colors only. `color-mix()`, `rgb()`, and
  named colors break the theme silently. Keep the `--dg-*` values as 6-digit
  hex.
- Re-rendering works by restoring each `pre.mermaid` from `data-src` and
  clearing `data-processed`, then `mermaid.initialize` and `mermaid.run`. The
  source is stashed once at load.
- `withCurve()` prepends `%%{init: {"flowchart": {"curve": ...}}}%%` per
  diagram: `bumpX` for `LR`/`RL`, `bumpY` otherwise. Mermaid sets the curve
  at the diagram level. This directive selects the curve for each diagram's
  direction. Sources that begin with `---` (frontmatter) or `%%{` are left
  untouched. `basis` was
  rejected for its overshoot, `stepAfter` for the jogs dagre produces.
- `look: "neo"` was tried and rejected: it adds drop shadows to every node and
  cluster (glow in dark mode), which is decoration without information.
  Rounded corners come from CSS `rx`/`ry` on `.node rect.basic` and
  `.cluster rect` instead.
- Mermaid injects its own stylesheet scoped by the SVG's id, so page CSS that
  overrides it needs `!important`. That is why the edge label and cluster label
  rules use it. Edge labels are HTML (`.edgeLabel p` inside a `foreignObject`);
  their plate is `color-mix(in srgb, var(--bg) 88%, transparent)` with
  symmetric `padding` and negative `margin`, which also fixes the label box
  that was a few pixels narrower than its text.
- `fitDiagrams()` runs after `mermaid.run` resolves. If the SVG's natural width
  exceeds the box by more than 30% it sets `max-width: none` and the natural
  width, so the `pre` scrolls instead of shrinking the text below legibility.
- `pre.mermaid` sets `font-family: var(--sans)` and the config passes the same
  family, so label measurement and rendering agree.
- Known and accepted: edges are drawn after cluster titles, so an edge entering
  a subgraph from above crosses its title. The title plate keeps it legible.
  Nothing in CSS reorders SVG paint.

### Link icons

`pv.lua` maps the link host to a service name and sets `data-svc`. The table is
ordered; `docs.google.com` must precede `google.com`. Matching is exact host or
subdomain. `docs.google.com` and `atlassian.net` dispatch on path. The
template has one CSS rule per service that sets `--svc` to a data URI, and one
generic rule that draws it with `mask` and `background-color: currentColor` so
the icon takes the link color in both themes.

Icons are from Simple Icons (CC0). Slack, Yahoo, and LinkedIn are not in that
set (brand takedowns), so Slack is a hand-drawn rounded hash and Yahoo a
hand-drawn "Y!", both as plain SVG shapes; LinkedIn has no icon. Data URIs
percent-encode `<`, `>`, `#`, and spaces and use single quotes inside the SVG so
the CSS `url("...")` stays valid.

To add a service:

1. Add `{ "<domain>", "<name>" }` to `services` in `pv.lua`, above any broader
   domain it shares a suffix with.
2. Get the icon path (`npm pack simple-icons@latest`, then
   `package/icons/<slug>.svg`) and generate the rule:

```python
import re, pathlib
d = re.search(r'<path d="([^"]+)"', pathlib.Path("icons/<slug>.svg").read_text()).group(1)
body = f"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'><path d='{d}'/></svg>"
enc = body.replace("<", "%3C").replace(">", "%3E").replace("#", "%23").replace(" ", "%20")
print(f'a[data-svc="<name>"] {{ --svc: url("data:image/svg+xml,{enc}"); }}')
```

3. Paste the rule next to the other `a[data-svc=...]` rules in `preview.html`
   and add a link to `sample.md`.

### Fonts

Body is `"Centra No2"`, a font Petro installed himself. macOS registers its
weights under legacy names (`Centra No2 Book`, `Centra No2 Medium`), but the
family name `Centra No2` resolves in Chrome with 400 mapping to Book, 500 to
Medium, and 700 to Bold (verified by measuring text widths per weight). Headings
and `strong` use 700. Fallbacks are Avenir Next, then `system-ui`. Do not
introduce a web font; see the offline rule.

### Print and PDF

The print stylesheet is the last block in the template so it wins ties.
Decisions in it:

- The dark palette lives inside `@media screen`, so print always gets the
  light palette without duplicating forty variables. The page background is
  forced to white in print; the off-white `--bg` printed as a visible box
  inside the page margins.
- Mermaid reads its colors from the CSS variables at render time and bakes
  them into the SVG, so CSS cannot recolor a diagram for print. The PDF path
  passes `--variable theme=light`, which the `<head>` script uses instead of
  storage or the OS setting, so the page renders light before Mermaid runs.
  The browser's print dialog on a dark tab prints dark diagrams; documented,
  not fixed. A `beforeprint` re-render was rejected because Mermaid renders
  asynchronously and Chrome takes the print snapshot before it finishes.
- Letter, 11pt, `--measure: 58ch` (about 80 characters at that size, which
  is 5.3in centered on an 8.5in page, close to the LaTeX article defaults),
  `line-height: 1.45`. Page numbers come from an `@bottom-center` margin
  box, which Chrome supports from 131. The font stack there is literal
  because margin boxes do not reliably see custom properties.
- `print-color-adjust: exact` on everything so note callouts, code panels,
  and zebra rows keep their backgrounds whatever the print setting.
- Threads are force-expanded (`div.pv.collapsed > div.pv { display: block }`)
  and the reply buttons hidden, because a collapsed thread on paper is
  useless. `body.no-notes` is left alone so hiding the notes is the way to
  print a clean document.
- Breaks: headings `break-after: avoid`; `pre`, tables, figures, diagrams
  `break-inside: avoid`; a block's notes `break-before: avoid`; and
  `div.pv > :first-child { break-before: avoid }`, which keeps a note's
  label (the `::before`) with its first lines. Without the last rule a label
  sat alone at the bottom of a page. The cost of these rules is occasional
  white space and an empty stretch of a thread's yellow box at a page
  bottom when a reply moves to the next page; accepted over split labels.
- `pre { white-space: pre-wrap }` in print because paper does not scroll;
  `pre.mermaid svg { max-width: 100% !important }` overrides the inline
  width `fitDiagrams()` sets for oversized diagrams.
- `--virtual-time-budget=6000` is what lets Mermaid finish before Chrome
  prints; without it the diagram area is empty. `--no-pdf-header-footer` is
  the current flag name (it replaced `--print-to-pdf-no-header`).
- The output path is built with `fnamemodify(path, ":p")`, never
  `expand()`: Petro's `wildignore` contains `*.pdf`, and `expand()` honors
  it, returning an empty string for any `.pdf` path. That produced
  `--print-to-pdf=/private/tmp/` on the first try.

### pandoc template gotchas

`$` is the template delimiter. A literal dollar sign must be written `$$`. The
CSS and JS in the template contain none, and the generated icon CSS is checked
for it. Search the output for `\$[a-z-]+\$` after a template edit to catch an
unresolved variable.

## Verifying a change

Render the fixture directly:

```sh
A=~/code/petro/vim-config/pandoc
pandoc --from gfm --to html5 --standalone --template "$A/preview.html" --lua-filter "$A/pv.lua" --metadata pagetitle=sample.md --metadata "srcdir=$A" --variable "mermaid=$A/mermaid.min.js" --output /tmp/sample.html "$A/sample.md"
rg -n '\$[a-z-]+\$' /tmp/sample.html || echo "template variables resolved"
```

Screenshot it without a display:

```sh
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=1728,2400 --virtual-time-budget=6000 --screenshot=/tmp/sample.png file:///tmp/sample.html
```

The page follows the OS theme when nothing is saved, so on a Mac in dark mode
both themes screenshot dark. To force light, edit a copy:
`sed 's/matches ? "dark" : "light"/matches ? "light" : "light"/'`. Use
`--dump-dom` instead of `--screenshot` to inspect the rendered DOM (Mermaid
output, computed widths via an injected script).

Run the real Neovim path with the opener stubbed:

```sh
nvim --headless -c 'lua vim.ui.open = function(p) _G.opened = p end' ~/code/petro/vim-config/pandoc/sample.md -c 'MarkdownPreview' -c 'lua vim.wait(5000, function() return _G.opened ~= nil end); print(_G.opened)' -c 'qa!'
```

After a layout change, check both themes at 900px and 1728px, the "Threads"
section of `sample.md` (three participants, depth two, a sibling reply, a
two-paragraph reply) both collapsed and expanded, the page with notes
hidden, the list-item thread under "Notes on other block types", an `LR`
and a `TB` flowchart, and the "Wide content" section, where notes sit under
a code block and under a bleeding diagram: the notes must stay in the text
column and the diagram must keep its bleed. Add new test cases to
`sample.md`, the shared fixture. Headless Chrome starts with empty
`sessionStorage`, so every thread is collapsed in the initial screenshot;
to see them open, inject a click on `.toolbar .fold` with `--dump-dom` or
temporarily set the default in `setOpen`.

Check the PDF path the same way, with the opener stubbed, then render the
pages to PNG with the JXA helper (PDFKit through the ObjC bridge; nothing to
install) and read them:

```sh
nvim --headless -c 'lua vim.ui.open = function(p) _G.opened = p end' "$A/sample.md" -c 'MarkdownPdf /tmp/sample.pdf' -c 'lua vim.wait(30000, function() return _G.opened ~= nil end)' -c 'qa!'
osascript -l JavaScript "$A/pdfpages.js" /tmp/sample.pdf /tmp/sample-page 1.6
```

The second argument is the output prefix (`/tmp/sample-page-1.png`, ...),
the third the scale (1.6 gives about 980px wide pages). Check: title block
when the source has frontmatter, page number on every page, the fixture's
thread expanded across a page break with no orphaned label, code wrapped, the
diagram rendered in light colors.

The reply mapping has a headless harness: extract `md_insert_pv_comment`
through `md_insert_pv_reply` from `init.lua` into a file, `luafile` it under
`nvim --headless --clean -u NONE` on a fixture, call the function on a line,
and write the buffer out. Cases that must hold: reply on a depth-1 tag line
lands after that note's existing replies with two markers; on a wrapped
continuation line, same as its tag line; on `-->`, one marker before `-->`;
on a single-line note, the note splits and `-->` moves down; inside a list
item, the base indent is the item's; below a single-line note or outside a
comment, a fresh root note.

Check the parser directly when touching `parse_thread`:

```sh
pandoc --from gfm --to html5 --lua-filter "$A/pv.lua" "$A/sample.md" | rg -o 'class="pv"[^>]*' | sort | uniq -c
```

Every `.pv` must have a `data-tag`, and the counts per tag must match the
fixture.

## Things that look wrong but are not

- Mermaid edge-label boxes were a few pixels narrow before the plate CSS, and
  Mermaid renders them the same way with its own default fonts. Not caused by
  the page font.
- `rg -c 'data-svc="'` on a rendered page counts the 28 CSS rules as well as
  the links.
- Two screenshots of "light" and "dark" that are identical mean the OS theme
  won, not a broken toggle. See the sed above.
- Headless Chrome hides scrollbars, so a scrolling diagram box looks clipped in
  a screenshot.
- Headless Chrome prints two `task_policy_set ... invalid argument` lines and
  sometimes `CVDisplayLinkCreateWithCGDisplay failed` on macOS. Noise; the
  PDF is fine.

## Open decisions

- Position of a note within a paragraph is lost: the render attaches the
  thread to the whole block. The direction, if wanted, is anchoring: keep a
  mid-paragraph note where it is, render a highlight on the preceding
  sentence, and put the thread under the paragraph. That needs a pre-pass
  over the raw text before pandoc, because pandoc splits the paragraph at
  the comment before any filter runs.
- Follow Petro's global `AGENTS.md` and `voice.md` for link labels: name the
  target rather than repeating its URL.
- The mono stack is the system default. PragmataPro and JetBrains Mono are
  installed if a change is wanted.

## Editing rules

No comments in the Lua, CSS, or JS; put reasons here. ASCII quotes only. Match
the existing structure of `preview.html`: variables at the top, layout, then
components, then the diagram rules, then the toolbar, then the icon rules.
Update `README.md` when behavior changes and this file when a reason or
constraint changes.
