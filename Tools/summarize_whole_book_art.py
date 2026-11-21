#!/usr/bin/env python3
"""Summarize the fixed XCTest observation; annotations never authorize art."""
import argparse
import collections
import json
from pathlib import Path


def summarize(report):
    attempts = report['attempts']
    if len(attempts) != 600:
        raise ValueError('Expected all 600 fixed attempts, including errors')
    lines = ['# Kitap boyunca görsel anlatım: başlangıç ölçümü', '',
             'Altı kurgu × 100 sabit seed. Bu, üretim sıklığı veya tüm katalog garantisi değildir.',
             'Kaynak etiketleri inceleme adayıdır; çizimle uyumluluk onayı değildir.', '',
             '| Kurgu | Başarılı | Hata | Temiz olmayan | Pinli sayfa | Açılış | Orta | Son |',
             '|---|---:|---:|---:|---:|---:|---:|---:|']
    for blueprint in report['blueprintIDs']:
        cohort = [a for a in attempts if a['blueprintID'] == blueprint]
        if len(cohort) != 100 or len({a['seed'] for a in cohort}) != 100:
            raise ValueError('Incomplete or repeated seed stratum: ' + blueprint)
        success = [a for a in cohort if 'error' not in a]
        pinned = [p for a in success for p in a['pages'] if p.get('art')]
        counts = collections.Counter(p['position'] for p in pinned)
        values = [blueprint, len(success), 100-len(success),
                  sum(a.get('isClean') is False for a in success), len(pinned),
                  counts['opening'], counts['middle'], counts['closing']]
        lines.append('| ' + ' | '.join(map(str, values)) + ' |')
    lines += ['', '## Ham özet', '', '```json',
              json.dumps(report['summary'], ensure_ascii=False, indent=2, sort_keys=True),
              '```', '', '## Sınırlar', '',
              '- Açılış sayfa1–2, orta3–6, sonuç7–8 olarak sayıldı.',
              '- Seçim geçmişi ve hatırlama olmadan, sabit sentetik Deniz profili kullanıldı.',
              '- Metin, sayfa başına pin ve provenance kaydet/aç eşitliği XCTest ile sınanır.',
              '- Pin, dosya/yerleşim cihazda görüldü anlamına gelmez.',
              '- Eksik pin nedeni politika içinde ayrıntılı açılmıyorsa rapor bunu açıkça belirtir.',
              '- Tam uygulama paketi, telefon ve yeni UI matrisi bu ölçümün parçası değildir.', '']
    return '\n'.join(lines)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    args.output.write_text(summarize(json.loads(args.report.read_text())), encoding='utf-8')
