#!/usr/bin/env python3
"""
Render the public usage page from snapshot JSON.

    python3 scripts/metrics/snapshot.py --days 30 --format json > docs/metrics.json
    python3 scripts/metrics/render_page.py docs/metrics.json > docs/index.html

The page is deliberately self-contained: no CDN, no fonts, no scripts. It is
served from GitHub Pages, which is intentionally decoupled from the production
stack — a status page sharing infrastructure with the thing it reports on is
worthless the moment that thing breaks.

Only aggregates are published. Individual search queries are never included:
there is no upside to publishing them, and their absence keeps the page
consistent with the site's own privacy claim.
"""
import datetime
import html
import json
import sys


def sparkline(points, width=680, height=110, stroke="var(--accent)", fill="var(--accent-dim)"):
    """Inline SVG area chart. Returns "" for empty input rather than a broken path."""
    values = [p[1] for p in points]
    if not values:
        return ""
    lo, hi = min(values), max(values)
    span = (hi - lo) or 1
    step = width / max(len(values) - 1, 1)

    def xy(i, v):
        return i * step, height - ((v - lo) / span) * (height - 12) - 6

    coords = [xy(i, v) for i, v in enumerate(values)]
    line = " ".join(f"{'M' if i == 0 else 'L'}{x:.1f},{y:.1f}" for i, (x, y) in enumerate(coords))
    area = f"{line} L{coords[-1][0]:.1f},{height} L0,{height} Z"
    return (
        f'<svg viewBox="0 0 {width} {height}" preserveAspectRatio="none" '
        f'role="img" aria-label="Daily values from {points[0][0]} to {points[-1][0]}, '
        f'low {lo}, high {hi}">'
        f'<path d="{area}" fill="{fill}"/>'
        f'<path d="{line}" fill="none" stroke="{stroke}" stroke-width="2" '
        f'stroke-linejoin="round" vector-effect="non-scaling-stroke"/></svg>'
    )


def tile(label, value, note=""):
    note_html = f'<div class="note">{html.escape(note)}</div>' if note else ""
    return (f'<div class="tile"><div class="label">{html.escape(label)}</div>'
            f'<div class="value">{html.escape(str(value))}</div>{note_html}</div>')


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: render_page.py <metrics.json>")
    d = json.load(open(sys.argv[1]))
    t, s = d.get("traffic") or {}, d.get("searches") or {}
    t_ok, s_ok = "error" not in t and t, "error" not in s and s

    generated = d.get("generated", "")
    try:
        stamp = datetime.datetime.fromisoformat(generated).strftime("%d %B %Y")
    except ValueError:
        stamp = generated[:10]

    tiles = []
    if t_ok:
        tiles.append(tile("Daily visitors", f"{t['mean_daily_uniques']:,}", "mean over the window"))
        tiles.append(tile("Page views", f"{t['page_views']:,}"))
        tiles.append(tile("Requests", f"{t['requests']:,}"))
    if s_ok:
        tiles.append(tile("Searches", f"{s['total']:,}", f"~{s['mean_per_day']:,}/day"))
        if s.get("zero_rate_pct") is not None:
            tiles.append(tile("Found nothing", f"{s['zero_rate_pct']}%",
                              "searches returning no events"))
    if d.get("searches_per_100_visitors") is not None:
        tiles.append(tile("Searches per 100 visitors", d["searches_per_100_visitors"]))

    charts = ""
    if s_ok and s.get("daily"):
        charts += ('<section><h2>Searches per day</h2>'
                   f'<div class="chart">{sparkline([(x["date"], x["searches"]) for x in s["daily"]])}</div>'
                   f'<div class="axis"><span>{html.escape(s["daily"][0]["date"])}</span>'
                   f'<span>{html.escape(s["daily"][-1]["date"])}</span></div></section>')
    if t_ok and t.get("daily"):
        charts += ('<section><h2>Unique visitors per day</h2>'
                   f'<div class="chart">{sparkline([(x["date"], x["uniques"]) for x in t["daily"]])}</div>'
                   f'<div class="axis"><span>{html.escape(t["daily"][0]["date"])}</span>'
                   f'<span>{html.escape(t["daily"][-1]["date"])}</span></div></section>')

    geo = ""
    if t_ok and t.get("countries"):
        rows = "".join(
            f'<tr><td>{html.escape(c["country"])}</td>'
            f'<td class="num">{c["requests"]:,}</td>'
            f'<td class="num">{c["share_pct"]}%</td>'
            f'<td class="bar"><span style="width:{min(c["share_pct"], 100):.1f}%"></span></td></tr>'
            for c in t["countries"][:8])
        geo = ('<section><h2>Where requests come from</h2>'
               '<table><thead><tr><th>Country</th><th class="num">Requests</th>'
               '<th class="num">Share</th><th></th></tr></thead>'
               f'<tbody>{rows}</tbody></table></section>')

    problems = [v.get("error") for v in (t, s) if isinstance(v, dict) and v.get("error")]
    banner = ""
    if problems:
        items = "".join(f"<li>{html.escape(p)}</li>" for p in problems)
        banner = f'<div class="warn"><strong>Partial data.</strong><ul>{items}</ul></div>'

    print(f"""<!doctype html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>FindMyFGC — Usage</title>
<meta name="description" content="Open usage statistics for findmyfgc.cc — traffic, searches, and how often a search finds nothing.">
<style>
:root {{
  --bg:#fbfbfc; --fg:#16181d; --muted:#606875; --line:#e3e5ea;
  --card:#ffffff; --accent:#4f46e5; --accent-dim:rgba(79,70,229,.12); --warn:#fff7ed;
}}
@media (prefers-color-scheme: dark) {{
  :root {{
    --bg:#0f1116; --fg:#e8eaee; --muted:#98a1b0; --line:#252a34;
    --card:#161a21; --accent:#818cf8; --accent-dim:rgba(129,140,248,.16); --warn:#2a1f12;
  }}
}}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--bg); color:var(--fg);
  font:16px/1.6 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif; }}
.wrap {{ max-width:820px; margin:0 auto; padding:3rem 1.25rem 4rem; }}
h1 {{ font-size:1.9rem; margin:0 0 .3rem; letter-spacing:-.02em; }}
h2 {{ font-size:.82rem; text-transform:uppercase; letter-spacing:.09em;
  color:var(--muted); margin:0 0 .75rem; font-weight:600; }}
.sub {{ color:var(--muted); margin:0 0 2.25rem; }}
.sub a {{ color:var(--accent); }}
.tiles {{ display:grid; gap:.75rem; grid-template-columns:repeat(auto-fit,minmax(160px,1fr));
  margin-bottom:2.5rem; }}
.tile {{ background:var(--card); border:1px solid var(--line); border-radius:10px; padding:1rem; }}
.tile .label {{ font-size:.72rem; text-transform:uppercase; letter-spacing:.07em; color:var(--muted); }}
.tile .value {{ font-size:1.75rem; font-weight:650; letter-spacing:-.02em; margin-top:.2rem; }}
.tile .note {{ font-size:.78rem; color:var(--muted); margin-top:.1rem; }}
section {{ margin-bottom:2.5rem; }}
.chart {{ background:var(--card); border:1px solid var(--line); border-radius:10px;
  padding:.5rem; overflow:hidden; }}
.chart svg {{ display:block; width:100%; height:110px; }}
.axis {{ display:flex; justify-content:space-between; font-size:.75rem;
  color:var(--muted); margin-top:.4rem; }}
table {{ width:100%; border-collapse:collapse; font-size:.92rem; }}
th, td {{ text-align:left; padding:.5rem .6rem; border-bottom:1px solid var(--line); }}
th {{ font-size:.72rem; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }}
.num {{ text-align:right; font-variant-numeric:tabular-nums; }}
.bar {{ width:34%; }}
.bar span {{ display:block; height:7px; border-radius:4px; background:var(--accent); opacity:.75; }}
.warn {{ background:var(--warn); border:1px solid var(--line); border-radius:10px;
  padding:.9rem 1rem; margin-bottom:2rem; font-size:.9rem; }}
.warn ul {{ margin:.4rem 0 0; padding-left:1.1rem; }}
.method {{ border-top:1px solid var(--line); padding-top:1.5rem;
  font-size:.86rem; color:var(--muted); }}
.method li {{ margin-bottom:.45rem; }}
.method strong {{ color:var(--fg); }}
</style>
</head><body><div class="wrap">
<h1>FindMyFGC — usage</h1>
<p class="sub">Open statistics for <a href="https://www.findmyfgc.cc/">findmyfgc.cc</a>,
a free tournament finder for fighting-game events.
Trailing {d.get('window_days', 30)} days · updated {html.escape(stamp)}.</p>
{banner}
<div class="tiles">{''.join(tiles)}</div>
{charts}
{geo}
<div class="method">
<h2>How this is measured</h2>
<ul>
<li><strong>Visitors</strong> come from Cloudflare, which sits in front of the site and
counts requests at the edge. It is cookieless — no identifier is stored on your device.</li>
<li><strong>Daily visitors is a daily distinct count with no cross-day deduplication.</strong>
Somebody visiting on five days counts five times, so these figures cannot be added up into
a monthly-users number, and none is claimed here.</li>
<li><strong>Searches</strong> are counted from the API's own logs. Only aggregates are
published — never individual search queries.</li>
<li><strong>Found nothing</strong> is the share of searches that resolved a real location but
matched no events nearby. Usually that means no tournaments are scheduled in range, which is
the honest state of a lot of the map.</li>
</ul>
</div>
</div></body></html>""")


if __name__ == "__main__":
    main()
