"""Shared HTTP helpers for box scripts: cached sessions and circuit breakers.

Import from any script whose Python has this directory on sys.path
(add a boxkit.pth file to the venv, or set PYTHONPATH / KIT_LIB):

    from boxkit import cached_session, breaker, guarded_get

    r = guarded_get("https://pypi.org/pypi/requests/json")
    print(r.status_code, getattr(r, "from_cache", False), len(r.content))

Environment (optional):
    BOXKIT_CACHE      SQLite path, default $KIT_HOME/tools/cache/http.sqlite
                      (KIT_HOME defaults to the kit folder containing tools/lib)
    BOXKIT_EXPIRE_HOURS  Cache TTL in hours, default 6
    BOXKIT_TIMEOUT    Hard GET timeout in seconds, default 30
    BOXKIT_USER_AGENT Override the default User-Agent
"""
from __future__ import annotations

import os
import threading
from datetime import timedelta
from pathlib import Path
from typing import Any, Optional, Union

import pybreaker
import requests
import requests_cache

_KIT_HOME = Path(os.environ.get("KIT_HOME", str(Path(__file__).resolve().parent.parent.parent)))
CACHE_DIR = Path(os.environ.get("KIT_CACHE", str(_KIT_HOME / "tools" / "cache")))
DEFAULT_CACHE_PATH = CACHE_DIR / "http.sqlite"
DEFAULT_EXPIRE = timedelta(hours=float(os.environ.get("BOXKIT_EXPIRE_HOURS", "6")))
DEFAULT_TIMEOUT = float(os.environ.get("BOXKIT_TIMEOUT", "30"))
DEFAULT_FAIL_MAX = 3
DEFAULT_RESET = 60
USER_AGENT = os.environ.get(
    "BOXKIT_USER_AGENT",
    "boxkit/1.0 (+shared box tools; read-only fetches)",
)

_session_lock = threading.Lock()
_breaker_lock = threading.Lock()
_default_session: Optional[requests_cache.CachedSession] = None
_breakers: dict[str, pybreaker.CircuitBreaker] = {}


def _cache_file() -> Path:
    return Path(os.environ.get("BOXKIT_CACHE", str(DEFAULT_CACHE_PATH)))


def _session_cache_name(cache_path: Path) -> str:
    """requests-cache appends .sqlite to the name; strip it so the file is http.sqlite."""
    name = str(cache_path)
    if name.endswith(".sqlite"):
        name = name[: -len(".sqlite")]
    return name


def cached_session(
    expire_after: Union[timedelta, int, float, None] = None,
    cache_path: Union[Path, str, None] = None,
    **kwargs: Any,
) -> requests_cache.CachedSession:
    """Return a requests-cache SQLite session.

    Default cache file: <KIT_CACHE>/http.sqlite, expire after 6 hours.
    Calls with no overrides reuse one process-wide session so the circuit
    breaker and cache stay shared.
    """
    global _default_session
    use_default = expire_after is None and cache_path is None and not kwargs
    if use_default:
        with _session_lock:
            if _default_session is None:
                path = _cache_file()
                path.parent.mkdir(parents=True, exist_ok=True)
                _default_session = requests_cache.CachedSession(
                    _session_cache_name(path),
                    backend="sqlite",
                    expire_after=DEFAULT_EXPIRE,
                    allowable_codes=(200, 203, 204, 300, 301, 308),
                    stale_if_error=True,
                )
            return _default_session

    path = Path(cache_path) if cache_path is not None else _cache_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    expire = DEFAULT_EXPIRE if expire_after is None else expire_after
    return requests_cache.CachedSession(
        _session_cache_name(path),
        backend="sqlite",
        expire_after=expire,
        allowable_codes=(200, 203, 204, 300, 301, 308),
        stale_if_error=True,
        **kwargs,
    )


def breaker(
    name: str,
    fail_max: int = DEFAULT_FAIL_MAX,
    reset_timeout: Union[int, float] = DEFAULT_RESET,
) -> pybreaker.CircuitBreaker:
    """Return a named circuit breaker (fail_max=3, reset_timeout=60 seconds).

    Breakers are reused by name in this process so repeated failures trip
    the same circuit (your modding PC, Nexus, a given host, and so on).
    """
    with _breaker_lock:
        br = _breakers.get(name)
        if br is None:
            br = pybreaker.CircuitBreaker(
                fail_max=fail_max,
                reset_timeout=reset_timeout,
                name=name,
            )
            _breakers[name] = br
        return br


def guarded_get(
    url: str,
    *,
    name: str = "http",
    timeout: Optional[float] = None,
    session: Optional[requests.Session] = None,
    headers: Optional[dict] = None,
    **kwargs: Any,
) -> requests.Response:
    """GET with cache, circuit breaker, and a hard timeout.

    On a dead host the first few calls pay the timeout, then the named
    breaker opens and later calls raise pybreaker.CircuitBreakerError
    immediately (fail_max=3, reset after 60 seconds).

    Returns a requests.Response (may have .from_cache=True on a hit).
    """
    sess = session or cached_session()
    br = breaker(name)
    hdrs = {"User-Agent": USER_AGENT}
    if headers:
        hdrs.update(headers)
    tmt = DEFAULT_TIMEOUT if timeout is None else timeout

    def _do() -> requests.Response:
        return sess.get(url, timeout=tmt, headers=hdrs, **kwargs)

    return br.call(_do)
