-- Turns the conventions in content/brief.md into Typst (PDF) or HTML (website).
-- See the comment at the top of content/brief.md for the markup this understands.

local TYPST = FORMAT:match('typst') ~= nil
local stringify = pandoc.utils.stringify

local function raw(s) return pandoc.RawBlock(TYPST and 'typst' or 'html', s) end
local function rawi(s) return pandoc.RawInline(TYPST and 'typst' or 'html', s) end

-- Render inlines/blocks to a string in the output format.
local function render(x, inline)
  local blocks = inline and { pandoc.Plain(x) } or x
  return (pandoc.write(pandoc.Pandoc(blocks), TYPST and 'typst' or 'html'):gsub('%s+$', ''))
end

local function esc_html(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

local function short_num(eyebrow) -- "Appendix 2" -> "A2", "01" -> "01"
  local n = eyebrow:match('^Appendix%s+(%w+)')
  return n and ('A' .. n) or eyebrow
end

-- ------------------------------------------------------------------ contents

local function collect_toc(blocks)
  local toc, cur = {}, nil
  for _, b in ipairs(blocks) do
    if b.t == 'Header' and b.level == 1 then
      cur = {
        id = b.identifier,
        num = short_num(b.attributes.eyebrow or ''),
        title = b.attributes.short or stringify(b.content),
        appendix = b.classes:includes('appendix'),
        subs = {},
      }
      table.insert(toc, cur)
    elseif b.t == 'Header' and b.level == 2 and cur then
      table.insert(cur.subs, { id = b.identifier, title = b.attributes.short or stringify(b.content) })
    end
  end
  return toc
end

local function toc_typst(toc)
  local out, gap_done = {}, false
  for _, s in ipairs(toc) do
    if s.appendix and not gap_done then table.insert(out, '#v(4pt)'); gap_done = true end
    table.insert(out, string.format('#toc-row([%s], [%s], <%s>)', (s.num:gsub('^0', '')), s.title, s.id))
  end
  return table.concat(out, '\n')
end

local function toc_html(toc)
  local function item(s)
    local sub = ''
    if #s.subs > 0 then
      local li = {}
      for _, c in ipairs(s.subs) do
        table.insert(li, string.format('<li><a href="#%s">%s</a></li>', c.id, esc_html(c.title)))
      end
      sub = '<ol class="toc-sub">' .. table.concat(li) .. '</ol>'
    end
    return string.format('<li><a href="#%s"><span>%s</span>%s</a>%s</li>', s.id, (s.num:gsub('^0', '')), esc_html(s.title), sub)
  end
  local main, app = {}, {}
  for _, s in ipairs(toc) do table.insert(s.appendix and app or main, item(s)) end
  return '<ol>' .. table.concat(main) .. '</ol><ol class="toc-app">' .. table.concat(app) .. '</ol>'
end

-- ------------------------------------------------------------------ elements

local fig_n = 0

local function Figure(fig)
  local img = fig.content[1] and fig.content[1].content and fig.content[1].content[1]
  if not img or img.t ~= 'Image' then return nil end
  fig_n = fig_n + 1
  local wide, float = img.classes:includes('wide'), img.classes:includes('float')
  local caption = fig.caption.long[1] and fig.caption.long[1].content or {}

  if TYPST then
    local args = { string.format('"/%s"', img.src) }
    if wide then table.insert(args, 'wide: true') end
    if float then table.insert(args, 'float: true') end
    if img.attributes.width then table.insert(args, 'width: ' .. img.attributes.width) end
    if img.attributes.height then table.insert(args, 'height: ' .. img.attributes.height) end
    local lbl = fig.identifier ~= '' and (' <' .. fig.identifier .. '>') or ''
    return raw(string.format('#fig(%s)[%s]%s', table.concat(args, ', '), render(caption, true), lbl))
  end

  -- The web uses the PNG with the same basename; SVG text depends on locally installed fonts.
  -- Figures marked .interactive are inlined instead, from the web-ready SVG (web fonts, hotspot
  -- data) that scripts/web_svg.py writes to build/web/ before pandoc runs.
  local stem = img.src:match('([^/]+)%.%w+$')
  local open_attrs = (fig.identifier ~= '' and (' id="' .. fig.identifier .. '"') or '')
  local caption_html = string.format('<figcaption><span>Figure %d</span>%s</figcaption>', fig_n, render(caption, true))
  if img.classes:includes('interactive') then
    local f = io.open('build/web/' .. stem .. '.svg')
    if f then
      local svg = f:read('a'):gsub('<svg%f[%s]', '<svg class="ifig" aria-label="' .. esc_html(stringify(img.caption)) .. '"', 1)
      f:close()
      return raw(string.format('<figure%s class="%sis-interactive"><div class="ifig-wrap">%s</div>%s</figure>',
        open_attrs, wide and 'wide ' or '', svg, caption_html))
    end
    io.stderr:write('robin.lua: build/web/' .. stem .. '.svg missing; using the PNG\n')
  end
  return raw(string.format('<figure%s%s><img src="figures/%s.png" alt="%s" loading="lazy">%s</figure>',
    open_attrs, wide and ' class="wide"' or '', stem, esc_html(stringify(img.caption)), caption_html))
end

local takeaways = {
    why = 'A shared foundation lets monitoring programs spend more time on science and less on rebuilding pipelines.',
    design = 'One reusable core connects to each program’s tools through a small set of adapters.',
    stacks = 'The same core fits different infrastructure, budgets, and data-governance needs.',
    lifecycle = 'Every request becomes traceable work, from the selected recordings to the final results.',
    forward = 'Inference and run management are developed; comparison and fine-tuning are next.',
  }

local function Header(h)
  local level = h.level
  if TYPST then
    if level == 1 then
      local fn = h.classes:includes('appendix') and 'appendix' or 'section-head'
      return raw(string.format('#%s([%s], [%s], <%s>' .. (takeaways[h.identifier] and (', takeaway: [' .. takeaways[h.identifier] .. ']') or '') .. ')', fn,
        (h.attributes.eyebrow or ''):gsub('^0', ''), render(h.content, true), h.identifier))
    end
    if h.attributes.letter then h.content:insert(1, pandoc.Str(h.attributes.letter .. '. ')) end
    h.level = level + 1
    h.attributes = {}
    return h
  end

  if level == 1 and h.attributes.eyebrow then
    h.content:insert(1, rawi('<span class="eyebrow">' .. esc_html((h.attributes.eyebrow:gsub('^0', ''))) .. '</span>'))
  end
  if h.attributes.letter then
    h.content:insert(1, rawi('<span class="letter">' .. h.attributes.letter .. '</span>'))
  end
  h.attributes = {}
  h.level = level + 1
  -- Shared section introductions are styled independently for web and PDF.

  if level == 1 and takeaways[h.identifier] then
    return {h, raw('<p class="section-takeaway">' .. esc_html(takeaways[h.identifier]) .. '</p>')}
  end
  if h.identifier == 'app-soundhub' then
    return {raw('<div class="appendix-guide"><span class="eyebrow">Further reading</span><p>The brief continues in three appendices: integration, governance, and technical design.</p><nav aria-label="Appendices"><a href="#app-soundhub">SoundHub integration →</a><a href="#app-governance">Governance &amp; provenance →</a><a href="#app-tech">Technical design →</a></nav></div>'), h}
  end
  return h
end

local function Div(div)
  local c = div.classes
  local blocks = div.content

  if c:includes('draft') and not TYPST then return {} end

  if c:includes('callout') then
    local title = div.attributes.title
    if TYPST then
      local kind = c:includes('tk') and ', kind: "tk"' or ''
      blocks = { raw(string.format('#callout(title: [%s]%s)[', title or '', kind)), table.unpack(blocks) }
      table.insert(blocks, raw(']'))
    else
      local inner = pandoc.List(blocks)
      if title then inner:insert(1, pandoc.Div(pandoc.Plain(pandoc.Str(title)), { class = 'callout-title' })) end
      blocks = { pandoc.Div(inner, { class = table.concat(c, ' ') }) }
    end
  elseif c:includes('card') then
    local title = div.attributes.title or ''
    if TYPST then
      blocks = { raw(string.format('card(title: [%s])[', title)), table.unpack(blocks) }
      table.insert(blocks, raw('],'))
    else
      local inner = pandoc.List(blocks)
      inner:insert(1, pandoc.Div(pandoc.Plain(pandoc.Str(title)), { class = 'eyebrow' }))
      return pandoc.Div(inner, { class = 'card' })
    end
  elseif c:includes('cards') then
    if not TYPST then return nil end
    blocks = { raw('#cards('), table.unpack(blocks) }
    table.insert(blocks, raw(')'))
  elseif c:includes('arrows') and TYPST then
    local rows = { raw('#arrow-list[') }
    for _, list in ipairs(blocks) do
      if list.t == 'BulletList' then
        for _, item in ipairs(list.content) do
          local inlines = item[1].content
          local title = inlines:remove(1)
          if inlines[1] and inlines[1].t == 'Space' then inlines:remove(1) end
          table.insert(rows, raw('#module-row([' .. render(title.content, true) .. '])[' .. render(item) .. ']'))
        end
      end
    end
    table.insert(rows, raw(']'))
    return rows
  elseif c:includes('arrows') then
    -- On the web, "**Term** description" bullets become a definition list (ruled rows).
    local out = {}
    for _, b in ipairs(blocks) do
      if b.t == 'BulletList' then
        local items = {}
        for _, item in ipairs(b.content) do
          local inlines = item[1].content
          local title = inlines:remove(1)
          if inlines[1] and inlines[1].t == 'Space' then inlines:remove(1) end
          table.insert(items, { title.content, { item } })
        end
        table.insert(out, pandoc.DefinitionList(items))
      else
        table.insert(out, b)
      end
    end
    return pandoc.Div(out, div.attr)
  elseif c:includes('pull') then
    if not TYPST then return nil end
    local fn = c:includes('arrows') and 'arrow-list' or 'pull'
    blocks = { raw('#' .. fn .. '['), table.unpack(blocks) }
    table.insert(blocks, raw(']'))
  else
    return nil
  end

  if c:includes('draft') then
    table.insert(blocks, 1, raw('#if draft ['))
    table.insert(blocks, raw(']'))
  end
  return blocks
end

-- Rough width of a table cell in ems at the table's text size: its whole text, and its longest
-- word (which can't wrap). Inline code is monospace, so it runs wider per character.
local function cell_width(cell)
  local total, word, longest = 0, 0, 0
  local function add(n, per)
    word = word + n * per; total = total + n * per
    if word > longest then longest = word end
  end
  pandoc.walk_block(pandoc.Div(cell.contents), {
    Str = function(s) add(utf8.len(s.text) or #s.text, 0.42) end,
    Code = function(c) add(#c.text, 0.45) end,
    Space = function() total = total + 0.25; word = 0 end,
    SoftBreak = function() total = total + 0.25; word = 0 end,
  })
  return total, longest
end

-- Tables read left-aligned unless a column asks otherwise, and their columns share the width
-- by how much text they hold (pipe tables otherwise get widths from the dashes, usually equal).
-- Each column gets at least its longest word plus padding; the rest goes in proportion to the
-- column's typical cell (between its average and longest), so one long note doesn't win.
-- On the web, a wrapper lets a table scroll sideways on a phone instead of squeezing the page.
local TABLE_EMS = 52   -- text width of the PDF column, in ems of the table's text
local PAD = 1.6        -- cell padding, in the same ems
local function Table(tbl)
  local n = #tbl.colspecs
  local min, want = {}, {}
  for i = 1, n do min[i], want[i] = 0, 0 end
  local rows = 0
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      rows = rows + 1
      for i, cell in ipairs(row.cells) do
        local total, longest = cell_width(cell)
        min[i] = math.max(min[i], longest + PAD)
        want[i] = want[i] + total
      end
    end
  end
  local widths = {}
  if rows > 0 then
    local maxes = {}
    for _, body in ipairs(tbl.bodies) do
      for _, row in ipairs(body.body) do
        for i, cell in ipairs(row.cells) do maxes[i] = math.max(maxes[i] or 0, (cell_width(cell))) end
      end
    end
    for i = 1, n do want[i] = math.max(min[i], (want[i] / rows + maxes[i]) / 2 + PAD) end
    -- Give every column its minimum, then share what's left in proportion to the rest of its want.
    local fixed, extra = 0, 0
    for i = 1, n do fixed = fixed + min[i]; extra = extra + (want[i] - min[i]) end
    local spare = math.max(TABLE_EMS - fixed, 0)
    for i = 1, n do
      local share = extra > 0 and spare * (want[i] - min[i]) / extra or spare / n
      widths[i] = (min[i] + share) / math.max(fixed + spare, TABLE_EMS)
    end
  end
  for i, spec in ipairs(tbl.colspecs) do
    tbl.colspecs[i] = { spec[1] == 'AlignDefault' and 'AlignLeft' or spec[1], widths[i] or 'ColWidthDefault' }
  end
  if TYPST then return tbl end
  return pandoc.Div({ tbl }, { class = 'table-wrap' })
end

-- Definition lists read best as bullets with a bold lead-in, like the other lists.
-- (The module rows in ::: arrows are built as definition lists separately, after this runs.)
local function DefinitionList(dl)
  local items = {}
  for _, item in ipairs(dl.content) do
    local term, defs = item[1], item[2]
    local inl = pandoc.List({ pandoc.Strong(term .. { pandoc.Str('.') }), pandoc.Space() })
    for _, b in ipairs(defs[1]) do
      if b.content then inl:extend(b.content) end
    end
    table.insert(items, { pandoc.Plain(inl) })
  end
  return pandoc.BulletList(items)
end

function Pandoc(doc)
  local toc = collect_toc(doc.blocks)
  doc = doc:walk { Figure = Figure, Header = Header, Div = Div, DefinitionList = DefinitionList, Table = Table }
  doc.meta['toc-rendered'] = pandoc.MetaBlocks { raw(TYPST and toc_typst(toc) or toc_html(toc)) }
  return doc
end
