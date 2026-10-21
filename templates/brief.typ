// GENERATED from content/brief.md by `make pdf` — edit the Markdown, not this file.
#import "/typst/theme.typ": *

#let draft = $if(draft)$true$else$false$endif$

#show: robin-brief.with(draft: draft)

#title-page(
  title: [$title$],
  acronym: [$acronym$],
  subtitle: [$subtitle$],
  lede: [$lede$],
  intro: callout(title: [What this document is])[$intro$],
  toc: [
$toc-rendered$
  ],
)

$body$
