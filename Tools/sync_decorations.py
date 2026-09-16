"""Onaylı dekorasyonları uygulama hedefine taşır ve katalogu Swift'e üretir.

İki sebep:

1. `Assets/Storybook/` Xcode hedefinin dışında. `Assets.xcassets` ise zaten
   hedefte tek bir kaynak olarak duruyor, dolayısıyla içine imageset eklemek
   `project.pbxproj` düzenlemesi gerektirmiyor.
2. `assets.json` çalışma anında okunsaydı da pakete eklenmesi gerekirdi.
   Onun yerine Swift'e üretiliyor: derleme zamanı güvenliği, sıfır paket işi,
   ve JSON yazım kaynağı olarak kalıyor.
"""
import json, os, shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAT = json.load(open(os.path.join(ROOT, "AssetCatalog/assets.json")))
XC = os.path.join(ROOT, "MagicPaper/Assets.xcassets/Storybook")
SWIFT = os.path.join(ROOT, "MagicPaper/Screens/StoryReader/StoryDecorationCatalog+Generated.swift")

approved = [a for a in CAT["assets"] if a["status"] == "approved"]

if os.path.isdir(XC): shutil.rmtree(XC)
os.makedirs(XC, exist_ok=True)
json.dump({"info":{"author":"xcode","version":1},
           "properties":{"provides-namespace":True}},
          open(os.path.join(XC, "Contents.json"), "w"), indent=2)

for a in approved:
    src = os.path.join(ROOT, a["imagePath"])
    d = os.path.join(XC, a["id"] + ".imageset")
    os.makedirs(d, exist_ok=True)
    shutil.copy2(src, os.path.join(d, a["id"] + ".png"))
    json.dump({
      "images":[{"filename": a["id"]+".png", "idiom":"universal", "scale":"2x"}],
      "info":{"author":"xcode","version":1},
      "properties":{"template-rendering-intent":"template"},
    }, open(os.path.join(d, "Contents.json"), "w"), indent=2)

def swift_set(vals, typ):
    if not vals: return "[]"
    return "[" + ", ".join(f".{v}" for v in vals) + "]"

lines = [
 "// ÜRETİLMİŞ DOSYA — elle düzenlemeyin.",
 "// Kaynak: AssetCatalog/assets.json · Üretici: Tools/sync_decorations.py",
 "//",
 "// Yalnızca `status: approved` varlıklar buraya girer. Elenen ve incelemede",
 "// olanlar katalogda kalır ama uygulamaya geçmez.",
 "",
 "import Foundation",
 "",
 "extension StoryDecorationCatalog {",
 "",
 "    /// Üretime onaylanmış dekorasyonlar.",
 "    static let generated: [StoryDecorationAsset] = [",
]
for a in approved:
    lines += [
     "        StoryDecorationAsset(",
     f'            id: "{a["id"]}",',
     f'            imageName: "Storybook/{a["id"]}",',
     f'            category: .{a["category"]},',
     f'            type: .{a["type"]},',
     f'            environments: {swift_set(a["environments"], "StoryEnvironment")},',
     f'            moods: {swift_set(a["moods"], "StoryMood")},',
     f'            preferredZones: {swift_set(a["preferredZones"], "DecorationZone")},',
     f'            visualWeight: {a["visualWeight"]}',
     "        ),",
    ]
lines += ["    ]", ""]

# Galeri için: elenen ve incelemede olanlar dâhil bütün katalog.
# Üretime girmezler ama kürasyon ekranında görünmeleri gerekiyor —
# eksikliği gizlemek sessizce yanlış dekorasyona yol açar.
lines += [
 "    /// Bütün katalog — kürasyon ekranı için. Üretim yalnızca `generated`.",
 "    static let catalogEntries: [StoryDecorationCatalogEntry] = [",
]
for a in CAT["assets"]:
    reason = a.get("rejectionReason", "").replace('"', "'")
    in_app = a["status"] == "approved"
    image_ref = '"Storybook/' + a["id"] + '"' if in_app else "nil"
    lines += [
     "        StoryDecorationCatalogEntry(",
     f'            id: "{a["id"]}",',
     f'            imageName: {image_ref},',
     f'            category: .{a["category"]},',
     f'            type: .{a["type"]},',
     f'            environments: {swift_set(a["environments"], "StoryEnvironment")},',
     f'            status: .{ {"approved":"approved","review":"reviewRequired","rejected":"rejected"}[a["status"]] },',
     f'            license: "{a["license"]}",',
     f'            note: "{reason}"',
     "        ),",
    ]
lines += ["    ]", "}", ""]
open(SWIFT, "w").write("\n".join(lines))

print(f"imageset: {len(approved)} -> MagicPaper/Assets.xcassets/Storybook/")
print(f"swift   : {SWIFT.split('MagicPaper/')[-1]}")
for a in approved: print("   ", a["id"], "·", a["type"], "·", a["category"])
