"""Print where things are in a figure, in its own coordinates, for writing hotspot boxes.

    python3 scripts/measure_svg.py figures/x.svg [--min-area 6000]

Renders the SVG in headless Chrome (so transforms and fonts are applied) and prints one line per
text label, plus every other shape at least --min-area square units in size:

    kind  x  y  w  h  text

Hotspot boxes in content/hotspots/*.json are [x, y, w, h] in these same units.
"""
import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

PAGE = """<!doctype html><body style="margin:0"><div id="h">%s</div><script>
const svg = document.querySelector('#h svg');
const inv = svg.getScreenCTM().inverse();
const out = [];
for (const el of svg.querySelectorAll('rect,circle,ellipse,path,polygon,polyline,line,text')) {
  if (el.closest('defs,marker,metadata,clipPath,mask')) continue;
  const b = el.getBoundingClientRect();
  const p = new DOMPoint(b.x, b.y).matrixTransform(inv), q = new DOMPoint(b.right, b.bottom).matrixTransform(inv);
  out.push([el.tagName, Math.round(p.x), Math.round(p.y), Math.round(q.x - p.x), Math.round(q.y - p.y),
            el.tagName === 'text' ? el.textContent.trim().replace(/\\s+/g, ' ') : '']);
}
document.body.dataset.out = JSON.stringify(out);
</script></body>"""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("svg")
    ap.add_argument("--min-area", type=float, default=6000)
    args = ap.parse_args()

    svg = Path(args.svg).read_text()
    svg = re.sub(r"<\?xml[^>]*>", "", svg)
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / "measure.html"
        page.write_text(PAGE % svg)
        dom = subprocess.run(
            [CHROME, "--headless=new", "--disable-gpu", "--window-size=2400,2400",
             "--virtual-time-budget=3000", "--dump-dom", page.as_uri()],
            capture_output=True, text=True, check=True,
        ).stdout
    m = re.search(r'data-out="([^"]*)"', dom)
    if not m:
        raise SystemExit("could not measure " + args.svg)
    rows = json.loads(m.group(1).replace("&quot;", '"').replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">"))
    for kind, x, y, w, h, text in rows:
        if kind == "text" or w * h >= args.min_area:
            print(f"{kind:8} {x:5} {y:5} {w:5} {h:5}  {text}")


if __name__ == "__main__":
    main()
