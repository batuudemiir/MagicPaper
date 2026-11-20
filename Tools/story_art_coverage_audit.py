#!/usr/bin/env python3
"""Read-only authored-source inventory; never certifies runtime story coverage.

Scans authored JSON below --sources, including retired/replaced records. The
production loader's selection/replacement semantics require a separate audit.
Slot names are review aids, not assertions of physical presence.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re


def digest(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def authored(node, pointer=""):
    if isinstance(node, dict):
        if isinstance(node.get("id"), str) and isinstance(node.get("text"), str):
            yield pointer, node
        for key, value in sorted(node.items()):
            escaped = key.replace("~", "~0").replace("/", "~1")
            yield from authored(value, pointer + "/" + escaped)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from authored(value, pointer + "/" + str(index))


def inventory(sources):
    records = []
    for path in sorted(sources.rglob("*.json")):
        relative = path.relative_to(sources).as_posix()
        for pointer, item in authored(json.loads(path.read_text(encoding="utf-8"))):
            records.append({"key": relative + "#" + pointer, "source": relative,
                            "pointer": pointer, "id": item["id"],
                            "text_sha256": digest(item["text"]),
                            "slots": sorted(set(re.findall(r"\{\{\s*([^{}]+?)\s*\}\}", item["text"]))),
                            "status": "unreviewed", "anchors": []})
    return records


def check(records, annotations):
    expected = {r["key"]: r for r in records}
    seen, duplicates, stale, unreviewed = set(), set(), set(), set()
    for note in annotations:
        key = note["key"]
        if key in seen:
            duplicates.add(key)
        seen.add(key)
        if key in expected and note.get("text_sha256") != expected[key]["text_sha256"]:
            stale.add(key)
        if note.get("status") != "reviewed":
            unreviewed.add(key)
    missing, extra = set(expected) - seen, seen - set(expected)
    return {"guarantee": "NOT_CERTIFIED", "inventory_count": len(records),
            "annotation_complete": not any([missing, extra, duplicates, stale, unreviewed]),
            "missing": sorted(missing), "extra": sorted(extra),
            "duplicates": sorted(duplicates), "stale": sorted(stale),
            "unreviewed": sorted(unreviewed)}


def verify_editorial(repo, records, sources=None):
    """Check content agent evidence without treating reviews as asset approval."""
    errors, seen, valid = [], set(), 0
    hashes = {s.get("source", s.get("path")): s.get("sha256") for s in (sources or [])}
    for note in records:
        key = note["source"] + "#" + note["jsonPointer"]
        try:
            path = (repo / note["source"]).resolve()
            if not path.is_relative_to(repo.resolve()) or key in seen:
                raise ValueError("unsafe path or duplicate evidence")
            seen.add(key)
            if sources is not None and (note["source"] not in hashes
                    or hashlib.sha256(path.read_bytes()).hexdigest() != hashes[note["source"]]):
                raise ValueError("stale or missing source file hash")
            node = json.loads(path.read_text(encoding="utf-8"))
            for part in note["jsonPointer"].split("/")[1:]:
                part = part.replace("~1", "/").replace("~0", "~")
                node = node[int(part)] if isinstance(node, list) else node[part]
            if digest(node["text"]) != note["textSHA256"]:
                raise ValueError("stale source text")
            if "variantID" in note and node.get("id") != note["variantID"]:
                raise ValueError("stale source identity")
            valid += 1
        except (OSError, ValueError, KeyError, IndexError, TypeError) as error:
            errors.append({"key": key, "reason": str(error)})
    return {"valid_records": valid, "errors": errors, "guarantee": "NOT_CERTIFIED"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--annotations", type=Path)
    parser.add_argument("--editorial-audit", type=Path)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    args = parser.parse_args()
    if not args.sources.is_dir():
        parser.error("--sources must be an existing directory")
    if args.output.resolve().is_relative_to(args.sources.resolve()):
        parser.error("output must be outside the immutable source tree")
    if any(path and path.resolve() == args.output.resolve()
           for path in [args.annotations, args.editorial_audit]):
        parser.error("output must not overwrite annotation evidence")
    records = inventory(args.sources)
    result = {"schema_version": 1, "guarantee": "NOT_CERTIFIED",
              "scope": "all_authored_records_not_runtime_reachability", "records": records}
    if args.annotations:
        notes = json.loads(args.annotations.read_text(encoding="utf-8"))
        result["annotation_check"] = check(records, notes["records"])
    if args.editorial_audit:
        notes = json.loads(args.editorial_audit.read_text(encoding="utf-8"))
        result["editorial_source_check"] = verify_editorial(args.repo, notes["records"], notes["sources"])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"records": len(records), "guarantee": result["guarantee"]}))
    if result.get("editorial_source_check", {}).get("errors"):
        return 2
    check_result = result.get("annotation_check", {})
    if any(check_result.get(key) for key in ["extra", "duplicates", "stale"]):
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
