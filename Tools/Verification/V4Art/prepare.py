"""Prepare a disposable macOS verification package from current production sources.
Run python3 Tools/Verification/V4Art/prepare.py, then the printed swift test command.
This facade cannot replace the actual iOS test target.
"""
from pathlib import Path
import hashlib,json,shutil,tempfile
root=Path(__file__).resolve().parents[3];templates=Path(__file__).resolve().parent
out=Path(tempfile.mkdtemp(prefix='magicpaper-v4-verification-'));sources=out/'Sources/MagicPaper';tests=out/'Tests/MagicPaperTests';sources.mkdir(parents=True);tests.mkdir(parents=True)
paths=['MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryArtPolicy.swift','MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryArtBinder.swift','MagicPaper/StoryEngineBridge/Pilots/P56/P56StoryMapper.swift','MagicPaper/StoryEngineBridge/StorySpotAssetResolver.swift','MagicPaper/StoryEngineBridge/StoryPageProvenance.swift']
records=[]
for rel in paths:
 p=root/rel;shutil.copy2(p,sources/p.name);records.append({'source':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
s=(root/'MagicPaper/Models/Story.swift').read_text();s=s[s.index('struct StoryPageArt:'):s.index('struct StoryPage:')];(sources/'StoryPageArt.swift').write_text('import Foundation\n'+s)
shutil.copy2(templates/'AppFacade.swift.template',sources/'AppFacade.swift')
s=(templates/'V4ArtVerificationTests.swift.template').read_text().replace('__REPOSITORY_ROOT__',str(root)).replace('__HARNESS_ROOT__',str(out));(tests/'V4ArtVerificationTests.swift').write_text(s)
engine=json.dumps(str(root/'StoryEngine'))
(out/'Package.swift').write_text('// swift-tools-version: 5.9\nimport PackageDescription\nlet package = Package(name: "V4ArtVerification", platforms: [.macOS(.v13)], dependencies: [.package(path: '+engine+')], targets: [.target(name: "MagicPaper", dependencies: [.product(name: "StoryEngine", package: "StoryEngine")]), .testTarget(name: "MagicPaperTests", dependencies: ["MagicPaper", .product(name: "StoryEngine", package: "StoryEngine")])])\n')
(out/'PRODUCTION_SOURCES.json').write_text(json.dumps(records,indent=2)+'\n')
print('Prepared:',out);print('DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path '+str(out))
