local srcdir
local who = {}
local who_count = 0

local markers = {
  TODO = true, NOTE = true, FIXME = true, HACK = true, XXX = true,
  BUG = true, TBD = true, WIP = true, NB = true, PS = true,
}

local function tag_of(line)
  local tag, rest = line:match("^%s*(%u+):%s?(.*)$")
  if tag and #tag <= 8 and not markers[tag] then
    return tag, rest
  end
end

local function unquote(line)
  local depth, rest = 0, line
  while true do
    local more = rest:match("^%s*>(.*)$")
    if not more then
      break
    end
    depth, rest = depth + 1, more
  end
  if depth > 0 then
    rest = rest:gsub("^ ", "", 1)
  end
  return depth, rest
end

local function split_lines(s)
  local lines = {}
  for line in (s .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  return lines
end

local function parse_thread(raw)
  local text = raw:match("^%s*<!%-%-(.-)%-%->%s*$")
  if not text then
    return nil
  end
  local lines = split_lines(text)
  local first = 1
  while lines[first] and lines[first]:match("^%s*$") do
    first = first + 1
  end
  local _, head = unquote(lines[first] or "")
  local tag, rest = tag_of(head)
  if not tag then
    return nil
  end
  local root = { tag = tag, lines = { rest }, replies = {}, depth = 0 }
  local stack = { root }
  for i = first + 1, #lines do
    local depth, line = unquote(lines[i])
    local t, r = tag_of(line)
    if t then
      while #stack > 1 and stack[#stack].depth >= depth do
        stack[#stack] = nil
      end
      local node = { tag = t, lines = { r }, replies = {}, depth = depth }
      local parent = stack[#stack]
      parent.replies[#parent.replies + 1] = node
      stack[#stack + 1] = node
    else
      local node = stack[#stack]
      node.lines[#node.lines + 1] = line
    end
  end
  return root
end

local function body_of(node)
  local min
  for i = 2, #node.lines do
    if not node.lines[i]:match("^%s*$") then
      local n = #node.lines[i]:match("^(%s*)")
      if not min or n < min then
        min = n
      end
    end
  end
  local out = { node.lines[1] }
  for i = 2, #node.lines do
    out[#out + 1] = node.lines[i]:sub((min or 0) + 1)
  end
  return (table.concat(out, "\n"):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function note_attrs(node)
  if not who[node.tag] then
    who[node.tag] = tostring(who_count % 4)
    who_count = who_count + 1
  end
  return { class = "pv", ["data-tag"] = node.tag, ["data-who"] = who[node.tag] }
end

local function note_div(node)
  local attrs = note_attrs(node)
  local blocks = pandoc.read(body_of(node), "gfm").blocks
  for _, reply in ipairs(node.replies) do
    blocks:insert(note_div(reply))
  end
  return pandoc.Div(blocks, attrs)
end

local function note_span(node)
  local attrs = note_attrs(node)
  local inlines = pandoc.utils.blocks_to_inlines(pandoc.read(body_of(node), "gfm").blocks)
  for _, reply in ipairs(node.replies) do
    inlines:insert(pandoc.Space())
    inlines:insert(note_span(reply))
  end
  return pandoc.Span(inlines, attrs)
end

local function escape_html(s)
  return (s:gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

local function is_relative(src)
  return not src:match("^%a[%w+.-]*:") and not src:match("^/") and not src:match("^#")
end

local function raw_block(el)
  if not el.format:match("html") then
    return nil
  end
  local thread = parse_thread(el.text)
  if thread then
    return note_div(thread)
  end
end

local function raw_inline(el)
  if not el.format:match("html") then
    return nil
  end
  local thread = parse_thread(el.text)
  if thread then
    return note_span(thread)
  end
end

local function code_block(el)
  if el.classes:includes("mermaid") then
    return pandoc.RawBlock("html", '<pre class="mermaid">' .. escape_html(el.text) .. "</pre>")
  end
end

local function image(el)
  if srcdir and is_relative(el.src) then
    el.src = "file://" .. srcdir .. "/" .. el.src
    return el
  end
end

local function google_docs(path)
  if path:match("^/spreadsheets") then
    return "googlesheets"
  elseif path:match("^/presentation") then
    return "googleslides"
  end
  return "googledocs"
end

local function atlassian(path)
  return path:match("^/wiki") and "confluence" or "jira"
end

local services = {
  { "github.com", "github" },
  { "linear.app", "linear" },
  { "docs.google.com", google_docs },
  { "drive.google.com", "googledrive" },
  { "meet.google.com", "googlemeet" },
  { "calendar.google.com", "googlecalendar" },
  { "mail.google.com", "gmail" },
  { "cloud.google.com", "googlecloud" },
  { "google.com", "google" },
  { "slack.com", "slack" },
  { "atlassian.net", atlassian },
  { "datadoghq.com", "datadog" },
  { "figma.com", "figma" },
  { "youtube.com", "youtube" },
  { "youtu.be", "youtube" },
  { "arxiv.org", "arxiv" },
  { "reddit.com", "reddit" },
  { "wikipedia.org", "wikipedia" },
  { "x.com", "x" },
  { "twitter.com", "x" },
  { "npmjs.com", "npm" },
  { "pypi.org", "pypi" },
  { "stackoverflow.com", "stackoverflow" },
  { "notion.so", "notion" },
  { "chromatic.com", "chromatic" },
  { "storybook.js.org", "storybook" },
  { "yahoo.com", "yahoo" },
  { "yahooinc.com", "yahoo" },
}

local function service_for(target)
  local host, path = target:match("^%a[%w+.-]*://([^/?#]+)([^?#]*)")
  if not host then
    return nil
  end
  host = host:lower():gsub("^.*@", ""):gsub(":%d+$", "")
  for _, entry in ipairs(services) do
    local domain, svc = entry[1], entry[2]
    if host == domain or host:sub(-#domain - 1) == "." .. domain then
      return type(svc) == "function" and svc(path) or svc
    end
  end
end

local function link(el)
  local svc = service_for(el.target)
  if svc then
    el.attributes["data-svc"] = svc
    return el
  end
end

local function is_note(b)
  return b.t == "Div" and b.classes:includes("pv")
end

local function skip_note(el)
  if is_note(el) then
    return el, false
  end
end

local function annotate(blocks)
  local out = pandoc.List()
  local i = 1
  while i <= #blocks do
    local block = blocks[i]
    local j = i + 1
    if not is_note(block) then
      while j <= #blocks and is_note(blocks[j]) do
        j = j + 1
      end
    end
    if j > i + 1 then
      local notes = pandoc.Div({ table.unpack(blocks, i + 1, j - 1) }, { class = "notes" })
      out:insert(pandoc.Div({ block, notes }, { class = "annotated" }))
    else
      out:insert(block)
    end
    i = j
  end
  return out
end

return {
  {
    Meta = function(m)
      if m.srcdir then
        srcdir = pandoc.utils.stringify(m.srcdir)
      end
    end,
  },
  {
    traverse = "topdown",
    RawBlock = raw_block,
    RawInline = raw_inline,
    CodeBlock = code_block,
    Image = image,
    Link = link,
  },
  {
    traverse = "topdown",
    Div = skip_note,
    Blocks = annotate,
  },
}
