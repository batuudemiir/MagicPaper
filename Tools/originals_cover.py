"""MagicPaper Original kapağı (spec 2026-11-12, docs/superpowers/specs).

    python3 Tools/originals_cover.py <slug>

WORLD.md'nin "## Kapak stili" bölümü + drafts/<slug>/review.md'nin
"## Kapak sahnesi" bölümü → Gemini görsel → drafts/<slug>/cover.jpg
(uzun kenar en çok 1500 px, JPEG). Anahtar: GEMINI_API_KEY ortamı ya da
Secrets.xcconfig. İstekte çocuk verisi yok: yalnız dünyanın karakterleri ve
sahne. Model: MP_COVER_MODEL (varsayılan gemini-2.5-flash-image).
"""

import base64
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORIGINALS = ROOT / "Content" / "Originals"
ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def section(text, title):
    """`## <title>` başlığının altındaki metin, bir sonraki `## `'e kadar."""
    out, inside = [], False
    for line in text.splitlines():
        if line.startswith("## "):
            if inside:
                break
            inside = line.strip() == f"## {title}"
            continue
        if inside:
            out.append(line)
    return "\n".join(out).strip()


def api_key(root=ROOT, env=None):
    env = os.environ if env is None else env
    if env.get("GEMINI_API_KEY"):
        return env["GEMINI_API_KEY"]
    path = pathlib.Path(root) / "Secrets.xcconfig"
    if not path.exists():
        return None
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\s*GEMINI_API_KEY\s*=\s*(\S+)", line)
        if match:
            return match.group(1)
    return None


def build_prompt(style, scene):
    if not style.strip():
        raise ValueError("WORLD.md'de '## Kapak stili' bölümü boş ya da yok")
    if not scene.strip():
        raise ValueError("review.md'de '## Kapak sahnesi' bölümü boş ya da yok")
    return (
        "Illustrated cover for a premium children's picture book, portrait.\n\n"
        f"Style:\n{style}\n\n"
        f"Scene:\n{scene}\n\n"
        "Rules: no text, no letters, no logos, no photorealism, no neon, no glossy 3D, "
        "no frightening imagery. Keep the top third calm for a title."
    )


def request_body(prompt):
    return {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": "3:4"}},
    }


def image_bytes(response):
    for candidate in response.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            data = part.get("inlineData") or part.get("inline_data")
            if data and data.get("data"):
                return base64.b64decode(data["data"])
    raise RuntimeError("Yanıtta görsel yok (güvenlik filtresi ya da model hatası)")


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2
    slug = argv[1]
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", slug):
        print(f"HATA: geçersiz slug: {slug}", file=sys.stderr)
        return 2
    draft = ORIGINALS / "drafts" / slug
    world = (ORIGINALS / "WORLD.md").read_text(encoding="utf-8")
    review = (draft / "review.md").read_text(encoding="utf-8")
    prompt = build_prompt(section(world, "Kapak stili"), section(review, "Kapak sahnesi"))
    key = api_key()
    if not key:
        print("HATA: GEMINI_API_KEY yok (ortam ya da Secrets.xcconfig)", file=sys.stderr)
        return 1
    model = os.environ.get("MP_COVER_MODEL", "gemini-2.5-flash-image")
    request = urllib.request.Request(
        ENDPOINT.format(model=model), data=json.dumps(request_body(prompt)).encode("utf-8"),
        headers={"Content-Type": "application/json", "x-goog-api-key": key}, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            image = image_bytes(json.load(response))
    except urllib.error.HTTPError as error:
        # Gövde güvenlik filtresi ya da kota mesajını taşır; anahtar başlıkta, burada yok.
        print(f"HATA: Gemini {error.code}: {error.read()[:300].decode('utf-8', 'replace')}", file=sys.stderr)
        return 1
    except (urllib.error.URLError, RuntimeError) as error:
        print(f"HATA: {error}", file=sys.stderr)
        return 1
    with tempfile.TemporaryDirectory() as temp:
        raw = pathlib.Path(temp) / "raw.png"
        raw.write_bytes(image)
        cover = draft / "cover.jpg"
        subprocess.run(["sips", "-Z", "1500", "-s", "format", "jpeg", "-s", "formatOptions", "80",
                        str(raw), "--out", str(cover)], check=True, capture_output=True)
    print(f"Kapak yazıldı: {cover} ({cover.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
