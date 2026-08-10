#!/usr/bin/env python3
"""
Regenerate the FindMyFGC usage snapshot.

Emits markdown on stdout, sized to paste into the Notion "Metrics & Observability"
page. Run it whenever the numbers there look stale.

    python3 scripts/metrics/snapshot.py            # last 30 days
    python3 scripts/metrics/snapshot.py --days 90  # longer window

Credentials
-----------
Cloudflare: CLOUDFLARE_API_TOKEN, read from the environment or the repo's
gitignored .env. Needs exactly one permission: Zone -> Analytics -> Read.
The token is never printed or written anywhere by this script.

AWS: whatever the `aws` CLI is already configured with. Read-only calls only.

Why two sources
---------------
Neither is sufficient alone, and each is misleading if read as the other:

  * Cloudflare sees real traffic. It sits in front of CloudFront and answers a
    large share of requests from its own cache, so AWS-side request counts
    understate reality (measured 2026-08: 2.26x on requests, 9x on bytes).
    It cannot see anything about searches.

  * CloudWatch sees application behaviour — searches, results, failures. These
    are HTTP 200s with the detail buried in log text, invisible to Cloudflare.

Known limits, so nobody re-derives them
---------------------------------------
  * Cloudflare `uniques` is a DAILY distinct count with no cross-day dedupe.
    Summing it gives visitor-days, not people. There is no true MAU available.
  * ALB 4XX is ~94% vulnerability-scanner 404s. It is not a user-error signal.
  * Search history is bounded by CloudWatch log retention. Once the metric
    filters in terraform/backend/observability.tf are applied, the counts
    survive log deletion and this script can read them from metrics instead.
"""
import argparse
import collections
import datetime
import json
import os
import statistics
import subprocess
import sys
import urllib.error
import urllib.request

CF_API = "https://api.cloudflare.com/client/v4"
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ENV_FILE = os.path.join(REPO_ROOT, ".env")
ZONE = "findmyfgc.cc"
LOG_GROUP = "/ecs/find-my-fgc-backend-prod"
REGION = "us-east-2"


def env(key):
    """Read a key from the environment, falling back to the gitignored .env."""
    if os.environ.get(key):
        return os.environ[key]
    if not os.path.exists(ENV_FILE):
        return None
    for line in open(ENV_FILE):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export "):].lstrip()
        name, sep, value = line.partition("=")
        if sep and name.strip() == key:
            return value.strip().strip("'\"")
    return None


def aws(*args):
    """Run an aws CLI command and parse JSON. Returns None on failure."""
    try:
        out = subprocess.run(
            ["aws", *args, "--output", "json"],
            capture_output=True, text=True, timeout=180, check=True,
        ).stdout
        return json.loads(out) if out.strip() else None
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, json.JSONDecodeError) as e:
        detail = getattr(e, "stderr", "") or str(e)
        print(f"  [aws call failed: {detail[:200]}]", file=sys.stderr)
        return None


# ── Cloudflare ────────────────────────────────────────────────────────────────

def cloudflare(days):
    token = env("CLOUDFLARE_API_TOKEN")
    if not token:
        return None, ("No CLOUDFLARE_API_TOKEN found (checked environment and .env). "
                      "Create one at https://dash.cloudflare.com/profile/api-tokens "
                      "with Zone -> Analytics -> Read.")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    def gql(query, variables):
        req = urllib.request.Request(
            f"{CF_API}/graphql",
            data=json.dumps({"query": query, "variables": variables}).encode(),
            headers=headers, method="POST",
        )
        try:
            doc = json.load(urllib.request.urlopen(req, timeout=60))
        except urllib.error.HTTPError as e:
            return {"_err": f"HTTP {e.code}: {e.read().decode()[:300]}"}
        if doc.get("errors"):
            return {"_err": json.dumps(doc["errors"])[:300]}
        return doc["data"]

    try:
        zreq = urllib.request.Request(f"{CF_API}/zones?name={ZONE}", headers=headers)
        zones = json.load(urllib.request.urlopen(zreq, timeout=30)).get("result") or []
    except urllib.error.HTTPError as e:
        return None, f"Cloudflare zone lookup failed: HTTP {e.code}"
    if not zones:
        return None, f"No zone named {ZONE} is visible to this token."
    zid = zones[0]["id"]

    today = datetime.date.today()
    since = (today - datetime.timedelta(days=days)).isoformat()
    data = gql(
        """query($z:String!,$s:String!,$u:String!){viewer{zones(filter:{zoneTag:$z}){
             httpRequests1dGroups(limit:1000,filter:{date_geq:$s,date_lt:$u}){
               dimensions{date}
               sum{requests cachedRequests pageViews bytes threats
                   countryMap{clientCountryName requests}}
               uniq{uniques}}}}}""",
        {"z": zid, "s": since, "u": today.isoformat()},
    )
    if "_err" in data:
        return None, f"Cloudflare analytics query failed: {data['_err']}"
    rows = sorted(data["viewer"]["zones"][0]["httpRequests1dGroups"],
                  key=lambda r: r["dimensions"]["date"])
    if not rows:
        return None, "Cloudflare returned no rows for this window."
    return {"rows": rows, "plan": zones[0].get("plan", {}).get("name", "unknown")}, None


# ── CloudWatch: searches ──────────────────────────────────────────────────────

def searches(days):
    """Count searches and outcomes from the log group via Logs Insights.

    Insights is used rather than filter-log-events because the latter scans
    serially and times out here: ~92% of this log group is /health noise.
    """
    end = int(datetime.datetime.now(datetime.timezone.utc).timestamp())
    start = end - days * 86400
    query = (
        'filter @message like "POST /tournaments [gameIds:" '
        '| stats count() as searches by bin(1d) as day | sort day asc'
    )
    started = aws("logs", "start-query", "--region", REGION,
                  "--log-group-name", LOG_GROUP,
                  "--start-time", str(start), "--end-time", str(end),
                  "--limit", "10000", "--query-string", query)
    if not started:
        return None, "Could not start the Logs Insights query."
    qid = started["queryId"]

    for _ in range(150):
        res = aws("logs", "get-query-results", "--region", REGION, "--query-id", qid)
        if not res:
            return None, "Logs Insights query failed while polling."
        if res["status"] == "Complete":
            per_day = {}
            for row in res["results"]:
                f = {c["field"]: c["value"] for c in row}
                per_day[f["day"][:10]] = int(f["searches"])
            return per_day, None
        if res["status"] in ("Failed", "Cancelled", "Timeout"):
            return None, f"Logs Insights query ended with status {res['status']}."
        subprocess.run(["sleep", "2"], check=False)
    return None, "Logs Insights query did not finish in time."


def outcomes(days):
    """Zero-result and geocode-failure counts over the window."""
    end = int(datetime.datetime.now(datetime.timezone.utc).timestamp())
    start = end - days * 86400
    out = {}
    # Two log lines carry "tournamentCount" per request (TournamentService's
    # "StartGG response" and the route handler's completion line), so both
    # queries pin to the completion line or every count comes out doubled.
    for label, q in [
        ("completions",
         'filter @message like "POST /tournaments complete" | stats count() as n'),
        ("zero",
         'filter @message like "POST /tournaments complete" '
         'and @message like "tournamentCount: 0]" | stats count() as n'),
        ("geocode_fail", 'filter @message like /Could not resolve location/ | stats count() as n'),
        ("startgg_err", 'filter @message like /StartGG API error/ | stats count() as n'),
    ]:
        started = aws("logs", "start-query", "--region", REGION,
                      "--log-group-name", LOG_GROUP,
                      "--start-time", str(start), "--end-time", str(end),
                      "--limit", "1", "--query-string", q)
        if not started:
            out[label] = None
            continue
        for _ in range(150):
            res = aws("logs", "get-query-results", "--region", REGION,
                      "--query-id", started["queryId"])
            if not res:
                out[label] = None
                break
            if res["status"] == "Complete":
                rows = res["results"]
                out[label] = int(rows[0][0]["value"]) if rows else 0
                break
            if res["status"] in ("Failed", "Cancelled", "Timeout"):
                out[label] = None
                break
            subprocess.run(["sleep", "2"], check=False)
        else:
            out[label] = None
    return out


# ── Rendering ─────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--days", type=int, default=30, help="window in days (default 30)")
    args = ap.parse_args()
    today = datetime.date.today()

    print(f"# FindMyFGC — usage snapshot\n")
    print(f"**Generated {today.isoformat()}** · window: trailing {args.days} days\n")

    # -- traffic
    print("## Traffic (Cloudflare — the real numbers)\n")
    cf, cf_err = cloudflare(args.days)
    if cf_err:
        print(f"> Not available: {cf_err}\n")
    else:
        rows = cf["rows"]
        req = sum(r["sum"]["requests"] for r in rows)
        pv = sum(r["sum"]["pageViews"] for r in rows)
        by = sum(r["sum"]["bytes"] for r in rows)
        uniq = [r["uniq"]["uniques"] for r in rows]
        first, last = rows[0]["dimensions"]["date"], rows[-1]["dimensions"]["date"]
        print(f"Plan: {cf['plan']} · data present {first} to {last} ({len(rows)} days)\n")
        print(f"- Requests: **{req:,}**")
        print(f"- Page views: **{pv:,}**")
        print(f"- Mean daily unique visitors: **{statistics.mean(uniq):,.0f}**")
        print(f"- Bandwidth: **{by/1e9:.2f} GB**\n")
        print("> Do not sum the uniques column — it is a daily distinct count with no")
        print("> cross-day dedupe, so the sum is visitor-days, not people.\n")

        geo = collections.Counter()
        for r in rows:
            for e in r["sum"].get("countryMap", []):
                geo[e["clientCountryName"]] += e["requests"]
        if geo:
            total = sum(geo.values())
            print("| Country | Requests | Share |")
            print("|---|---:|---:|")
            for country, n in geo.most_common(8):
                print(f"| {country} | {n:,} | {100*n/total:.1f}% |")
            print()

    # -- searches
    print("## Searches (CloudWatch — what Cloudflare cannot see)\n")
    per_day, s_err = searches(args.days)
    if s_err:
        print(f"> Not available: {s_err}\n")
    else:
        total = sum(per_day.values())
        n = len(per_day) or 1
        print(f"- Total searches: **{total:,}**")
        print(f"- Mean per day: **{total/n:,.0f}** · median "
              f"**{statistics.median(per_day.values()):,.0f}**\n")

        o = outcomes(args.days)
        comp, zero = o.get("completions"), o.get("zero")
        if comp and zero is not None:
            print(f"- Zero-result rate: **{100*zero/comp:.1f}%** ({zero:,} of {comp:,})")
        if o.get("geocode_fail") is not None and total:
            gf = o["geocode_fail"]
            print(f"- Geocode failures (HTTP 422): **{gf:,}** ({100*gf/total:.2f}% of searches)")
        if o.get("startgg_err") is not None:
            print(f"- start.gg upstream errors: **{o['startgg_err']:,}**")
        print()

        if per_day:
            peak = max(per_day.values()) or 1
            print("```")
            for day in sorted(per_day):
                bar = "#" * max(1, round(per_day[day] / peak * 40))
                print(f"{day}  {per_day[day]:5d}  {bar}")
            print("```\n")

    if cf and not cf_err and per_day and not s_err:
        visitors = statistics.mean([r["uniq"]["uniques"] for r in cf["rows"]])
        per = sum(per_day.values()) / (len(per_day) or 1)
        if visitors:
            print(f"**Conversion:** ~{100*per/visitors:.0f} searches per 100 daily visitors.\n")

    print("---\n")
    print("*Regenerate with `python3 scripts/metrics/snapshot.py`. "
          "Traffic is Cloudflare edge data; searches are parsed from Vapor logs. "
          "Search history is bounded by CloudWatch log retention.*")


if __name__ == "__main__":
    main()
