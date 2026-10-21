"""Prepare a figure SVG for inlining in the website (filters/robin.lua inlines the result).

    python3 scripts/web_svg.py figures/x.svg content/hotspots/x.json build/web/x.svg

- Swaps the desktop fonts the figures were drawn with for web fonts the page loads.
- Prefixes every id (and its references) so several inlined SVGs can't collide with each other
  or with the page.
- Drops Inkscape editor state and embeds the hotspot data as <metadata class="hotspots">.
"""
import json
import re
import sys
from pathlib import Path

FONTS = {
    "'Avenir Next', Avenir, sans-serif": "'Nunito Sans', 'Avenir Next', Avenir, sans-serif",
    "Menlo, 'SF Mono', monospace": "'Roboto Mono', Menlo, monospace",
    "Charter, 'Iowan Old Style', Georgia, serif": "Lora, Charter, Georgia, serif",
}


def main(src: str, hotspots: str, out: str) -> None:
    svg = Path(src).read_text()
    prefix = re.sub(r"\W", "", Path(src).stem.split("_")[0]) or "fig"
    prefix = f"f{prefix}-"

    svg = re.sub(r"<\?xml[^>]*>\s*", "", svg)
    svg = re.sub(r"<sodipodi:namedview\b.*?(/>|</sodipodi:namedview>)", "", svg, flags=re.S)
    # Inline, a <title> becomes a native browser tooltip over the whole figure, on top of the
    # hotspot tooltips. The page labels the figure with aria-label instead.
    svg = re.sub(r"<title\b.*?</title>", "", svg, flags=re.S)
    for old, new in FONTS.items():
        svg = svg.replace(f'font-family="{old}"', f'font-family="{new}"')
        svg = svg.replace(f"font-family:{old}", f"font-family:{new}")

    svg = re.sub(r'\bid="([^"]+)"', lambda m: f'id="{prefix}{m.group(1)}"', svg)
    svg = re.sub(r"url\(#([^)]+)\)", lambda m: f"url(#{prefix}{m.group(1)})", svg)
    svg = re.sub(r'((?:xlink:)?href)="#([^"]+)"', lambda m: f'{m.group(1)}="#{prefix}{m.group(2)}"', svg)

    # Size comes from the page's CSS, not the drawing's own width and height.
    svg = re.sub(r"<svg\b[^>]*>", lambda m: re.sub(r'\s(width|height)="[^"]*"', "", m.group(0)), svg, count=1)

    data = json.loads(Path(hotspots).read_text())
    payload = json.dumps(data).replace("&", "\\u0026").replace("<", "\\u003c").replace(">", "\\u003e")
    meta = f'<metadata class="hotspots">{payload}</metadata>'
    svg = re.sub(r"(<svg\b[^>]*>)", lambda m: m.group(1) + meta, svg, count=1)

    Path(out).write_text(svg)


if __name__ == "__main__":
    main(*sys.argv[1:4])
