// ROBIN brief — visual theme.
// Palette is lifted from the figures so text and diagrams read as one system.
// The document itself is generated from content/brief.md by pandoc (see Makefile).

#let ink = rgb("#22313a")
#let slate = rgb("#5d6b73")
#let mist = rgb("#8a979e")
#let rule-c = rgb("#d9e0e3")
#let paper-2 = rgb("#f4f7f6")
#let accent = rgb("#3f7466")   // heading green
#let accent-soft = rgb("#eaf2ef")
#let teal = rgb("#2f8592")     // inline code / links
#let clay = rgb("#c2603a")     // TK notes
#let clay-soft = rgb("#fbeee7")

#let serif = ("Lora",)
#let display = ("Playfair Display",)
#let sans = ("Source Sans 3",)
#let mono = ("Roboto Mono", "Menlo")

// ---------- building blocks used by the generated document ----------

#let eyebrow(body) = text(font: sans, size: 9pt, weight: 600, fill: slate, body)

#let section-head(label-text, title, lbl, takeaway: none) = {
  block(above: 2em, below: 0.5em, sticky: true, {
    line(length: 100%, stroke: 0.5pt + rule-c)
    v(12pt)
    [#heading(level: 2, grid(
      columns: (21pt, 1fr),
      align: horizon,
      text(font: display, size: 13pt, weight: 400, fill: rgb("#7c8f85"), label-text),
      title,
    )) #lbl]
    if takeaway != none {
      pad(left: 21pt, top: 2pt, text(font: serif, size: 10pt, weight: 400, fill: slate, takeaway))
      v(10pt)
    }
  })
}

#let appendix(label-text, title, lbl) = {
  pagebreak(weak: true)
  v(0.4in)
  block(below: 0.5em, sticky: true, text(font: serif, size: 11pt, fill: slate, label-text))
  [#heading(level: 1, title) #lbl]
}

#let module-row(title, body) = block(
  width: 100%, above: 0pt, below: 0pt,
  stroke: (top: 0.5pt + rule-c), inset: (y: 9pt),
  grid(columns: (94pt, 1fr), column-gutter: 12pt,
    text(font: sans, size: 9.5pt, weight: 600, title),
    text(font: sans, size: 9.5pt, body),
  ),
)
#let arrow-list(body) = block(
  width: 100%, above: 1.1em, below: 1.4em,
  stroke: (bottom: 0.5pt + rule-c),
  body,
)

#let pull(body) = block(
  inset: (left: 14pt, y: 2pt),
  stroke: (left: 2pt + accent),
  above: 1.5em,
  below: 1.5em,
  text(weight: 600, body),
)

#let callout(kind: "note", title: none, body) = {
  let (fg, bg) = if kind == "tk" { (clay, clay-soft) } else { (accent, accent-soft) }
  block(
    width: 100%,
    fill: bg,
    inset: (x: 14pt, y: 11pt),
    radius: 4pt,
    stroke: (left: 2.5pt + fg),
    {
      set text(font: sans, size: 9.5pt)
      if title != none {
        text(font: sans, size: 9pt, fill: fg, weight: 600, title)
        v(0.3em)
      }
      body
    },
  )
}

#let card(title: none, body) = block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  stroke: 0.6pt + rule-c,
  {
    text(font: sans, size: 9pt, fill: slate, weight: 600, title)
    v(0.25em, weak: true)
    set text(font: sans, size: 9.5pt)
    set par(spacing: 0.6em)
    body
  },
)

#let cards(..items) = block(above: 1em, below: 1.4em, grid(
  columns: (1fr,) * items.pos().len(),
  column-gutter: 10pt,
  ..items.pos(),
))

// Figure; `wide` bleeds slightly into the margins, `float` lets Typst move it to avoid gaps.
#let fig(path, caption, width: 100%, height: auto, wide: false, float: false) = {
  let img = image(path, width: if height == auto { width } else { auto }, height: height)
  figure(
    if wide { pad(x: -0.35in, img) } else { img },
    caption: caption,
    kind: image,
    placement: if float { auto } else { none },
  )
}

#let toc-row(num, title, lbl) = link(lbl, grid(
  columns: (2.2em, 1fr, auto),
  text(font: serif, size: 10pt, fill: slate, num),
  text(font: sans, size: 10pt, fill: ink, title),
  text(font: sans, size: 9pt, fill: slate, context counter(page).at(lbl).first()),
))

// ---------- document setup ----------

#let robin-brief(draft: false, body) = {
  set document(title: "ROBIN — A Vision and Design Overview", author: "DSE")
  set page(
    paper: "us-letter",
    margin: (x: 1.05in, top: 1in, bottom: 0.95in),
    header: context {
      if counter(page).get().first() > 1 {
        set text(font: sans, size: 8pt, fill: slate)
        grid(
          columns: (1fr, auto),
          [ROBIN · Vision and Design Overview],
          if draft { text(fill: clay)[DRAFT] },
        )
        v(-4pt)
        line(length: 100%, stroke: 0.4pt + rule-c)
      }
    },
    footer: context {
      if counter(page).get().first() > 1 {
        set text(font: sans, size: 8pt, fill: slate)
        align(right, counter(page).display())
      }
    },
  )

  set text(font: serif, size: 10.25pt, fill: ink, lang: "en", hyphenate: false)
  set par(leading: 0.78em, spacing: 1.25em, justify: false)
  show strong: set text(weight: 700)

  // headings
  show heading: set text(font: display, fill: accent, weight: 500)
  show heading.where(level: 1): it => {
    set text(size: 22pt)
    block(above: 0.4em, below: 0.9em, it.body)
  }
  show heading.where(level: 2): it => {
    set text(size: 15pt)
    block(above: 0.4em, below: 0.9em, sticky: true, it.body)
  }
  show heading.where(level: 3): it => {
    set text(font: sans, size: 12pt, weight: 600)
    block(above: 1.7em, below: 0.85em, sticky: true, it.body)
  }
  show heading.where(level: 4): it => {
    set text(font: sans, size: 10.25pt, weight: 700, fill: ink)
    block(above: 1.5em, below: 0.8em, sticky: true, it.body)
  }

  // code
  show raw: set text(font: mono, size: 0.9em)
  show raw.where(block: false): it => box(
    fill: paper-2,
    inset: (x: 2.5pt),
    outset: (y: 2.5pt),
    radius: 2pt,
    text(fill: teal, it),
  )
  show raw.where(block: true): it => block(
    width: 100%,
    fill: paper-2,
    inset: (x: 14pt, y: 11pt),
    radius: 4pt,
    stroke: (left: 2.5pt + teal),
    {
      set par(leading: 0.65em)
      set text(size: 8.5pt)
      it
    },
  )

  // links: external links get a subtle underline
  show link: it => {
    if type(it.dest) == str {
      underline(stroke: 0.5pt + teal.lighten(40%), offset: 2pt, text(fill: teal, it))
    } else {
      text(fill: teal, it)
    }
  }

  // lists
  set list(indent: 0.4em, body-indent: 0.7em, marker: text(fill: accent)[•], spacing: 0.75em)
  set enum(indent: 0.2em, body-indent: 0.7em, spacing: 0.75em, numbering: n => text(
    font: mono,
    size: 8.5pt,
    weight: 500,
    fill: accent,
    str(n) + ".",
  ))

  // tables: small sans text, quiet uppercase labels, one firm rule under the header and hairlines
  // between rows. No vertical rules; the first column sits flush with the text edge.
  set table(
    stroke: (_, y) => if y > 0 { (bottom: 0.4pt + rule-c) },
    inset: (x, _) => (left: if x == 0 { 0pt } else { 7pt }, right: 7pt, y: 5.5pt),
  )
  set table.hline(stroke: 0.7pt + slate)
  show table: set text(font: sans, size: 8.75pt)
  show table: set par(leading: 0.5em, justify: false)
  show table.cell.where(y: 0): set text(size: 7.25pt, weight: 600, fill: slate, tracking: 0.06em)
  show table.cell.where(y: 0): it => upper(it)
  show table.cell.where(x: 0): set text(weight: 600)
  show figure.where(kind: table): set block(above: 1.4em, below: 1.7em, breakable: true)
  show figure.where(kind: table): set align(left)

  // figures
  set figure(gap: 0.9em)
  set place(clearance: 2em)
  show figure: set block(above: 1.8em, below: 1.8em, breakable: false)
  show figure.caption: it => {
    set text(font: sans, size: 8.5pt, fill: slate)
    set par(leading: 0.6em)
    [#text(font: sans, size: 8.5pt, weight: 600, fill: accent, [Figure #context it.counter.display(it.numbering)]) #h(0.6em) #it.body]
  }

  body
}

// ---------- title page ----------

#let title-page(title: [], acronym: [], subtitle: [], lede: [], intro: none, toc: []) = {
  set page(header: none, footer: none)
  v(0.55in)
  grid(
    columns: (auto, 1fr),
    column-gutter: 22pt,
    align: (left + bottom, left + bottom),
    text(font: display, size: 76pt, fill: accent, weight: 400, tracking: -0.01em, title),
    pad(bottom: 14pt, {
      set text(font: display, size: 13pt, fill: accent)
      set par(leading: 0.45em)
      show strong: set text(weight: 600)
      acronym
    }),
  )
  v(4pt)
  line(length: 100%, stroke: 0.6pt + rule-c)
  v(10pt)
  text(font: display, size: 19pt, fill: ink, style: "italic", subtitle)
  v(22pt)
  block(width: 88%, {
    set text(size: 12.5pt, fill: slate)
    set par(leading: 0.8em)
    lede
  })
  v(1fr)
  if intro != none {
    intro
    v(0.35in)
  }
  eyebrow[Contents]
  v(8pt)
  line(length: 100%, stroke: 0.4pt + rule-c)
  {
    set block(spacing: 0.62em)
    toc
  }
  v(0.3in)
  pagebreak()
}
