#!/bin/bash
set -euo pipefail
pilot_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
repo_dir="$(cd -- "$pilot_dir/../../.." && pwd)"
work_dir="$(mktemp -d /tmp/magicpaper-art-pilot.XXXXXX)"
mkdir -p "$work_dir/Sources/ArtPilot"
python3 - "$repo_dir/StoryEngine" "$work_dir/Package.swift" <<'PY'
import json,sys
from pathlib import Path
path=json.dumps(sys.argv[1])
Path(sys.argv[2]).write_text('// swift-tools-version: 5.9\nimport PackageDescription\nlet package = Package(name: "ArtPilot", platforms: [.macOS(.v13)], dependencies: [.package(path: '+path+')], targets: [.executableTarget(name: "ArtPilot", dependencies: [.product(name: "StoryEngine", package: "StoryEngine")])])\n')
PY
cp "$pilot_dir/Export.swift" "$work_dir/Sources/ArtPilot/main.swift"
CLANG_MODULE_CACHE_PATH="$work_dir/module-cache" swift run --package-path "$work_dir" --scratch-path "$work_dir/build" --disable-sandbox -j 4 ArtPilot "$pilot_dir/books.json"
python3 "$pilot_dir/audit.py"
