"""Validate and bundle a published Original's optional interior-art sequence."""
import json
from pathlib import Path
import shutil


def build_page_illustrations(book, slug, page_count, assets):
    book, assets = Path(book), Path(assets)
    manifest = book / "illustrations.json"
    if not manifest.exists():
        return None
    data = json.loads(manifest.read_text(encoding="utf-8"))
    entries = data.get("pages")
    if not isinstance(entries, list) or len(entries) != page_count:
        raise ValueError(f"{manifest}: her metin sayfası için bir görsel gerekli")

    validated = []
    for number, entry in enumerate(entries, 1):
        filename = f"page-{number:02d}.jpg"
        if not isinstance(entry, dict) or entry.get("page") != number or entry.get("file") != filename:
            raise ValueError(f"{manifest}: sayfa {number} sırası/dosya adı geçersiz")
        alt = entry.get("altText")
        if not isinstance(alt, str) or not alt.strip():
            raise ValueError(f"{manifest}: sayfa {number} görsel açıklaması boş")
        source = book / "illustrations" / filename
        if not source.is_file() or source.is_symlink():
            raise ValueError(f"{manifest}: görsel yok ya da bağlantı: {filename}")
        with source.open("rb") as handle:
            if handle.read(3) != b"\xff\xd8\xff":
                raise ValueError(f"{manifest}: JPEG değil: {filename}")
        validated.append((source, f"original-{slug}-page-{number:02d}", alt.strip()))

    # No asset mutations before the entire sequence has passed validation.
    result = []
    for source, name, alt in validated:
        folder = assets / (name + ".imageset")
        folder.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, folder / (name + ".jpg"))
        contents = {"images": [{"filename": name + ".jpg", "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1}}
        (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
        result.append({"asset": name, "altText": alt})
    return result
