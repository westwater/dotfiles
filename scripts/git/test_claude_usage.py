"""Tests for claude_usage.py — run: uv run --no-project --python 3.9 --with pytest -- pytest -q scripts/git/"""
from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone

import pytest

import claude_usage as cu

UTC = timezone.utc
NOW = datetime(2026, 10, 28, 0, 0, tzinfo=UTC)

# trimmed from the real 2026-10-27 response
USAGE = {
    "five_hour": {"utilization": 0.0, "resets_at": "2026-10-28T04:50:00.502627+00:00"},
    "seven_day": {"utilization": 13.0, "resets_at": "2026-10-29T08:00:00.502653+00:00"},
    "limits": [
        {"kind": "session", "group": "session", "percent": 0, "resets_at": "2026-10-28T04:50:00.502627+00:00", "scope": None},
        {"kind": "weekly_all", "group": "weekly", "percent": 13, "resets_at": "2026-10-29T08:00:00.502653+00:00", "scope": None},
        {"kind": "weekly_scoped", "group": "weekly", "percent": 0, "resets_at": "2026-10-29T08:00:00+00:00",
         "scope": {"model": {"id": None, "display_name": "Fable"}, "surface": None}},
    ],
}


def _cred(expires: datetime, scopes: tuple[str, ...] = ("user:inference", "user:profile"), token: str = "t") -> dict:
    return {"claudeAiOauth": {"accessToken": token, "expiresAt": int(expires.timestamp() * 1000), "scopes": list(scopes)}}


# --- keychain naming ---------------------------------------------------------

def test_service_name_matches_claude_code_per_config_dir_entry() -> None:
    # verified against the real Keychain on 2026-10-27
    assert cu.service_name("/Users/westwater/.g/.claude") == "Claude Code-credentials-ddfb1a05"


def test_candidate_config_dirs_include_g_and_work_repos(tmp_path) -> None:
    (tmp_path / ".g" / ".claude").mkdir(parents=True)
    (tmp_path / "work" / "hmrc" / "repo-a" / ".g").mkdir(parents=True)
    (tmp_path / "work" / "hmrc" / "repo-b").mkdir(parents=True)  # no .g → skipped
    dirs = cu.candidate_config_dirs(tmp_path)
    assert dirs[0] == str(tmp_path / ".g" / ".claude")
    assert str(tmp_path / "work" / "hmrc" / "repo-a" / ".g" / ".claude") in dirs
    assert not any("repo-b" in d for d in dirs)


# --- token choice ------------------------------------------------------------

def test_pick_token_takes_latest_unexpired() -> None:
    creds = [_cred(NOW + timedelta(hours=1), token="soon"), _cred(NOW + timedelta(hours=5), token="late"),
             _cred(NOW - timedelta(hours=1), token="dead")]
    assert cu.pick_token(creds, NOW) == "late"


def test_pick_token_none_when_all_expired() -> None:
    assert cu.pick_token([_cred(NOW - timedelta(minutes=1))], NOW) is None


def test_pick_token_skips_token_about_to_expire() -> None:
    assert cu.pick_token([_cred(NOW + timedelta(seconds=30))], NOW) is None


def test_pick_token_skips_inference_only_tokens() -> None:
    # setup-token / CLAUDE_CODE_OAUTH_TOKEN logins lack user:profile and get 401 from the usage endpoint
    assert cu.pick_token([_cred(NOW + timedelta(hours=3), scopes=("user:inference",))], NOW) is None


def test_pick_token_tolerates_malformed_entries() -> None:
    assert cu.pick_token([{}, {"claudeAiOauth": {}}, _cred(NOW + timedelta(hours=2), token="ok")], NOW) == "ok"


# --- formatting --------------------------------------------------------------

def test_format_line_shows_percent_left_and_reset_times() -> None:
    line = cu.format_line(USAGE, NOW, tz=UTC, colour=False)
    assert line == " ● claude     session 100% left · resets 04:50   week 87% left · resets Thu 08:00"


def test_format_line_shows_scoped_weekly_only_when_used() -> None:
    usage = json.loads(json.dumps(USAGE))
    usage["limits"][2]["percent"] = 40
    assert "Fable 60% left · resets Thu 08:00" in cu.format_line(usage, NOW, tz=UTC, colour=False)


def test_format_line_marks_windows_already_reset() -> None:
    later = datetime(2026, 10, 28, 6, 0, tzinfo=UTC)  # past the session reset, before the weekly one
    line = cu.format_line(USAGE, later, tz=UTC, colour=False)
    assert "session 100% left · reset" in line
    assert "week 87% left" in line


def test_format_line_falls_back_to_legacy_fields() -> None:
    legacy = {k: USAGE[k] for k in ("five_hour", "seven_day")}
    assert cu.format_line(legacy, NOW, tz=UTC, colour=False) == cu.format_line(
        {"limits": USAGE["limits"][:2]}, NOW, tz=UTC, colour=False)


def test_format_line_appends_age_when_stale() -> None:
    line = cu.format_line(USAGE, NOW, tz=UTC, colour=False, fetched_at=NOW - timedelta(hours=3))
    assert line.endswith("(as of 3h ago)")


@pytest.mark.parametrize("pct,level", [(13, "green"), (70, "yellow"), (89, "yellow"), (90, "red")])
def test_severity_from_highest_used(pct: int, level: str) -> None:
    usage = {"limits": [{"kind": "session", "percent": 0, "resets_at": "2026-10-28T04:50:00+00:00"},
                        {"kind": "weekly_all", "percent": pct, "resets_at": "2026-10-29T08:00:00+00:00"}]}
    assert cu.severity(usage, NOW) == level


def test_severity_ignores_windows_already_reset() -> None:
    usage = {"limits": [{"kind": "session", "percent": 95, "resets_at": "2026-10-27T23:00:00+00:00"}]}
    assert cu.severity(usage, NOW) == "green"


# --- main ----------------------------------------------------------------------

def test_main_fetches_and_caches(monkeypatch, tmp_path, capsys) -> None:
    cache = tmp_path / "usage.json"
    monkeypatch.setattr(cu, "CACHE", cache)
    monkeypatch.setattr(cu, "load_credentials", lambda: [_cred(datetime.now(UTC) + timedelta(hours=2), token="ok")])
    monkeypatch.setattr(cu, "fetch_usage", lambda token: USAGE if token == "ok" else None)
    assert cu.main([]) == 0
    assert "claude" in capsys.readouterr().out
    assert json.loads(cache.read_text())["usage"] == USAGE


def test_main_falls_back_to_cache_when_no_token(monkeypatch, tmp_path, capsys) -> None:
    cache = tmp_path / "usage.json"
    cache.write_text(json.dumps({"fetched_at": (datetime.now(UTC) - timedelta(hours=2)).isoformat(), "usage": USAGE}))
    monkeypatch.setattr(cu, "CACHE", cache)
    monkeypatch.setattr(cu, "load_credentials", lambda: [])
    monkeypatch.setattr(cu, "fetch_usage", lambda token: pytest.fail("must not call the API without a token"))
    assert cu.main([]) == 0
    assert "(as of 2h ago)" in capsys.readouterr().out


def test_main_cache_only_never_touches_keychain(monkeypatch, tmp_path, capsys) -> None:
    monkeypatch.setattr(cu, "CACHE", tmp_path / "missing.json")
    monkeypatch.setattr(cu, "load_credentials", lambda: pytest.fail("cache-only must not read the Keychain"))
    assert cu.main(["--cache-only"]) == 0
    assert "no data" in capsys.readouterr().out


def test_main_survives_garbled_cache(monkeypatch, tmp_path, capsys) -> None:
    cache = tmp_path / "usage.json"
    cache.write_text("{not json")
    monkeypatch.setattr(cu, "CACHE", cache)
    assert cu.main(["--cache-only"]) == 0
    assert "no data" in capsys.readouterr().out
