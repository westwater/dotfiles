#!/usr/bin/env python3
"""One-line Claude plan usage (session + weekly % left, reset times) for the `s` dashboard.

Reads an access token from Claude Code's own Keychain login and calls the endpoint `/usage` uses.
The wrapper sets CLAUDE_CONFIG_DIR per repo, so each repo's login has its own Keychain entry;
the freshest unexpired one wins. Tokens are never refreshed here (refreshing rotates the refresh
token and would log that Claude Code config out), so when no session has run for a few hours the
last cached response is shown with its age.

usage: claude_usage.py [--cache-only]
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import unicodedata
import urllib.request
from datetime import datetime, timezone, tzinfo
from pathlib import Path

CACHE = Path.home() / ".g" / ".claude" / "cache" / "claude-usage.json"
USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
EXPIRY_MARGIN_S = 60

R, B, D = "\033[0m", "\033[1m", "\033[2m"
COLOURS = {"green": "\033[32m", "yellow": "\033[33m", "red": "\033[31m"}


def service_name(config_dir: str) -> str:
    """Keychain service Claude Code stores a login under when CLAUDE_CONFIG_DIR is set."""
    digest = hashlib.sha256(unicodedata.normalize("NFC", config_dir).encode()).hexdigest()[:8]
    return f"Claude Code-credentials-{digest}"


def candidate_config_dirs(home: Path) -> list[str]:
    """Config dirs the wrapper may have used: ~/.g first, then every repo with a .g link."""
    dirs = [str(home / ".g" / ".claude")]
    for pattern in ("work/*/*", "Projects/*"):
        for repo in sorted(home.glob(pattern)):
            if (repo / ".g").exists():
                dirs.append(str(repo / ".g" / ".claude"))
    return dirs


def load_credentials() -> list[dict]:
    """Every Claude Code login found in the Keychain (unparseable or missing entries skipped)."""
    services = [service_name(d) for d in candidate_config_dirs(Path.home())] + ["Claude Code-credentials"]
    creds = []
    for service in services:
        try:
            out = subprocess.run(["security", "find-generic-password", "-s", service, "-w"],
                                 capture_output=True, text=True, timeout=3).stdout
            creds.append(json.loads(out))
        except (subprocess.SubprocessError, ValueError):
            continue
    return creds


def pick_token(creds: list[dict], now: datetime) -> str | None:
    """Access token with the latest expiry that is still valid and can read usage, else None."""
    best, best_exp = None, now.timestamp() + EXPIRY_MARGIN_S
    for cred in creds:
        o = cred.get("claudeAiOauth") or {}
        token, exp = o.get("accessToken"), (o.get("expiresAt") or 0) / 1000
        if token and "user:profile" in (o.get("scopes") or []) and exp > best_exp:
            best, best_exp = token, exp
    return best


def fetch_usage(token: str) -> dict | None:
    """GET the usage endpoint; None on any failure."""
    req = urllib.request.Request(USAGE_URL, headers={
        "Authorization": f"Bearer {token}", "anthropic-beta": "oauth-2025-04-20"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.load(resp)
    except Exception:
        return None


def _parse_ts(s: str) -> datetime:
    return datetime.fromisoformat(s.replace("Z", "+00:00"))


def _limits(usage: dict) -> list[dict]:
    """Normalised [{label, used, resets_at}]; scoped weeklies only when used."""
    raw = usage.get("limits")
    if not isinstance(raw, list):
        raw = [{"kind": kind, "percent": (usage.get(key) or {}).get("utilization"),
                "resets_at": (usage.get(key) or {}).get("resets_at")}
               for kind, key in (("session", "five_hour"), ("weekly_all", "seven_day")) if usage.get(key)]
    out = []
    for lim in raw:
        kind, pct, reset = lim.get("kind"), lim.get("percent"), lim.get("resets_at")
        if pct is None or not reset:
            continue
        if kind == "session":
            label = "session"
        elif kind == "weekly_all":
            label = "week"
        elif kind == "weekly_scoped" and pct > 0:
            label = (((lim.get("scope") or {}).get("model") or {}).get("display_name")) or "scoped"
        else:
            continue
        out.append({"label": label, "used": float(pct), "resets_at": _parse_ts(reset)})
    return out


def severity(usage: dict, now: datetime) -> str:
    """green / yellow (>=70% used) / red (>=90%) from the most-used window not yet reset."""
    used = max([l["used"] for l in _limits(usage) if l["resets_at"] > now] or [0])
    return "red" if used >= 90 else "yellow" if used >= 70 else "green"


def _age(delta_s: float) -> str:
    m = int(delta_s // 60)
    return "<1m" if m < 1 else f"{m}m" if m < 60 else f"{m // 60}h" if m < 48 * 60 else f"{m // 1440}d"


def _row(icon: str, body: str, colour: bool) -> str:
    return f" {icon} {B}{'claude':<10}{R} {body}" if colour else f" ● {'claude':<10} {body}"


def format_line(usage: dict, now: datetime, tz: tzinfo | None = None, colour: bool = True,
                fetched_at: datetime | None = None) -> str:
    """The `s` row: '● claude  session 100% left · resets 04:50   week 87% left · resets Thu 08:00'."""
    today = now.astimezone(tz).date()
    parts = []
    for lim in _limits(usage):
        if lim["resets_at"] <= now:
            parts.append(f"{lim['label']} 100% left · reset")
            continue
        local = lim["resets_at"].astimezone(tz)
        when = local.strftime("%H:%M" if local.date() == today else "%a %H:%M")
        parts.append(f"{lim['label']} {100 - round(lim['used'])}% left · resets {when}")
    if not parts:
        return no_data_line(colour)
    body = "   ".join(parts)
    if fetched_at is not None:
        age = f"(as of {_age((now - fetched_at).total_seconds())} ago)"
        body += f"   {D}{age}{R}" if colour else f"   {age}"
    icon = f"{COLOURS[severity(usage, now)]}●{R}"
    return _row(icon, body, colour)


def no_data_line(colour: bool = True) -> str:
    return _row(f"{D}●{R}", f"{D}no data{R}", True) if colour else _row("●", "no data", False)


def _read_cache() -> tuple[dict, datetime] | None:
    try:
        data = json.loads(CACHE.read_text())
        return data["usage"], _parse_ts(data["fetched_at"])
    except Exception:
        return None


def _write_cache(usage: dict, now: datetime) -> None:
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        tmp = CACHE.with_suffix(".tmp")
        tmp.write_text(json.dumps({"fetched_at": now.isoformat(), "usage": usage}))
        os.replace(tmp, CACHE)
    except OSError:
        pass


def main(argv: list[str]) -> int:
    """Print the usage row; always exits 0 so it can never break `s`."""
    colour = sys.stdout.isatty() or os.environ.get("FORCE_COLOR") == "1"
    now = datetime.now(timezone.utc)
    if "--cache-only" not in argv:
        token = pick_token(load_credentials(), now)
        usage = fetch_usage(token) if token else None
        if usage:
            _write_cache(usage, now)
            print(format_line(usage, now, colour=colour))
            return 0
    cached = _read_cache()
    if cached is None:
        print(no_data_line(colour))
    else:
        try:
            print(format_line(cached[0], now, colour=colour, fetched_at=cached[1]))
        except Exception:
            print(no_data_line(colour))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
