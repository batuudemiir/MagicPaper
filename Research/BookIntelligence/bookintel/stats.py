"""Small, dependency-free descriptive statistics."""

from __future__ import annotations


def median(values: list[float]) -> float:
    if not values:
        return 0
    ordered = sorted(values)
    mid = len(ordered) // 2
    return ordered[mid] if len(ordered) % 2 else (ordered[mid - 1] + ordered[mid]) / 2


def quantile(values: list[float], q: float) -> float:
    """Linear-interpolated quantile, q in [0, 1]."""
    if not values:
        return 0
    ordered = sorted(values)
    position = (len(ordered) - 1) * q
    low = int(position)
    high = min(low + 1, len(ordered) - 1)
    return ordered[low] + (ordered[high] - ordered[low]) * (position - low)


def summary(values: list[float]) -> dict:
    return {
        "n": len(values),
        "min": min(values, default=0),
        "p25": round(quantile(values, 0.25), 2),
        "median": round(median(values), 2),
        "p75": round(quantile(values, 0.75), 2),
        "max": max(values, default=0),
    }
