"""HTTP for adapters: host allow-list, robots.txt, rate limit, honest User-Agent.

There is deliberately no way to fetch an arbitrary URL. An adapter declares the
hosts it may reach (an entry starting with "." allows that domain's subdomains,
e.g. ".archive.org" for Internet Archive's download servers); anything else is
refused before a socket is opened, and a redirect to a host outside the list is
refused too. Tests pass a `fetcher` and never reach the network.
"""

from __future__ import annotations

import os
import ssl
import time
import urllib.error
import urllib.request
import urllib.robotparser
from typing import Callable
from urllib.parse import urlparse

from .. import TOOL_VERSION

USER_AGENT = f"MagicPaper-BookIntelligence/{TOOL_VERSION} (children's book research; low volume)"
Fetcher = Callable[[str], bytes]


class AccessRefused(RuntimeError):
    """A request the rules do not allow. Recorded as a failure, never retried around."""


# python.org builds on macOS ship without a CA bundle until "Install
# Certificates.command" is run. Fall back to the system bundle — verification
# stays on; it is never disabled.
_SYSTEM_BUNDLES = ("/etc/ssl/cert.pem", "/etc/ssl/certs/ca-certificates.crt")


def _ssl_context() -> ssl.SSLContext:
    context = ssl.create_default_context()
    if not os.path.exists(ssl.get_default_verify_paths().cafile or ""):
        for bundle in _SYSTEM_BUNDLES:
            if os.path.exists(bundle):
                context.load_verify_locations(cafile=bundle)
                break
    return context


def host_allowed(host: str | None, allowed: set[str]) -> bool:
    if not host:
        return False
    return host in allowed or any(a.startswith(".") and host.endswith(a) for a in allowed)


class _GuardedRedirects(urllib.request.HTTPRedirectHandler):
    def __init__(self, allowed: set[str]):
        super().__init__()
        self.allowed = allowed

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        parsed = urlparse(newurl)
        if parsed.scheme != "https" or not host_allowed(parsed.hostname, self.allowed):
            raise AccessRefused(f"redirect to {newurl} leaves this adapter's allow-list")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def _urllib_fetcher(allowed: set[str]) -> Fetcher:
    opener = urllib.request.build_opener(urllib.request.HTTPSHandler(context=_ssl_context()),
                                         _GuardedRedirects(allowed))

    def fetch(url: str) -> bytes:
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with opener.open(request, timeout=60) as response:
            return response.read()
    return fetch


class HttpClient:
    def __init__(self, allowed_hosts: set[str], fetcher: Fetcher | None = None,
                 min_interval: float = 1.5, check_robots: bool = True):
        self.allowed_hosts = allowed_hosts
        self.fetcher = fetcher or _urllib_fetcher(allowed_hosts)
        self.min_interval = min_interval if fetcher is None else 0
        self.check_robots = check_robots
        self._last = 0.0
        self._robots: dict[str, urllib.robotparser.RobotFileParser] = {}

    def _allowed_by_robots(self, url: str) -> bool:
        if not self.check_robots:
            return True
        parsed = urlparse(url)
        root = f"{parsed.scheme}://{parsed.netloc}"
        parser = self._robots.get(root)
        if parser is None:
            parser = urllib.robotparser.RobotFileParser()
            try:
                parser.parse(self._get(f"{root}/robots.txt").decode("utf-8", "replace").splitlines())
            except urllib.error.HTTPError as error:
                if error.code not in (404, 410):
                    raise AccessRefused(f"{root}/robots.txt answered {error.code}; not fetching")
                parser.parse([])  # no robots.txt → no restriction stated
            except (urllib.error.URLError, OSError) as error:
                raise AccessRefused(f"{root}/robots.txt unreachable ({error}); not fetching")
            self._robots[root] = parser
        return parser.can_fetch(USER_AGENT, url)

    def _get(self, url: str) -> bytes:
        wait = self.min_interval - (time.monotonic() - self._last)
        if wait > 0:
            time.sleep(wait)
        try:
            return self.fetcher(url)
        finally:
            self._last = time.monotonic()

    def get(self, url: str) -> bytes:
        parsed = urlparse(url)
        if parsed.scheme != "https" or not host_allowed(parsed.hostname, self.allowed_hosts):
            raise AccessRefused(f"{url}: host not on this adapter's allow-list")
        if not self._allowed_by_robots(url):
            raise AccessRefused(f"{url}: disallowed by robots.txt")
        return self._get(url)
