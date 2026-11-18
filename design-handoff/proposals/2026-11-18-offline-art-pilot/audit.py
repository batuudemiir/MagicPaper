"""Reproduce the bounded pilot's art mapping; does not modify app/engine content."""
from pathlib import Path
import json
from collections import Counter

ROOT = Path(__file__).resolve().parent
books = json.loads((ROOT / 'books.json').read_text())
plant_variants = {'na_any_01', 'na_any_02', 'na_any_03', 'na_neutral_01', 'na_neutral_02', 'na_neutral_03', 'na_neutral_04', 'na_neutral_05'}
hedgehog_variants = {'mc_care_02', 'mc_care_03', 'mc_care_06', 'mc_care_07'}
light_variants = {'ex_s_light_02', 'ex_s_light_04'}
rules = {
    'schema': 'pilot-only-1',
    'scope': {'blueprintID': 'bp_charge_tending_001', 'settingID': 'setting_old_orchard_001', 'companionID': 'companion_hedgehog_pilot_001', 'discoveryID': 'object_wilting_seedling_001'},
    'assets': [
        {'id': 'wilting-seedling-v1', 'file': 'wilting-seedling-v1.png', 'page': 1, 'role': 'hook', 'variantAllowlist': sorted(plant_variants), 'depictsChild': False, 'depictsCompanion': False, 'status': 'review'},
        {'id': 'kestane-meeting-v1', 'file': 'kestane-meeting-v1.png', 'page': 3, 'role': 'companion', 'variantAllowlist': sorted(hedgehog_variants), 'depictsChild': False, 'depictsCompanion': True, 'status': 'review'},
    ],
    'fallback': 'text-only',
    'note': 'Review-only proposal, NOT the production SceneLibrary schema. Sample allowlists cover observed variants only. No runtime AI, keyword guess, or random fallback.'
}
assignments = []
issues = []
for book in books:
    assert book['isClean'] and len(book['pages']) == 8
    assert all(book[k] == v for k, v in rules['scope'].items())
    for page in book['pages']:
        allowed = [a for a in rules['assets'] if page['number'] == a['page'] and page['role'] == a['role'] and set(page['variantIDs']).issubset(a['variantAllowlist'])]
        assert len(allowed) <= 1
        assignments.append({'childName': book['childName'], 'seed': book['seed'], 'page': page['number'], 'asset': allowed[0]['id'] if allowed else None})
        if set(page['variantIDs']) & light_variants:
            issues.append({'childName': book['childName'], 'seed': book['seed'], 'page': page['number'], 'kind': 'light-language-for-nonluminous-seedling', 'variantIDs': page['variantIDs'], 'text': page['text']})
summary = {
    'books': len(books), 'pages': len(assignments), 'cleanSlotRendering': sum(b['isClean'] for b in books),
    'illustratedPages': sum(a['asset'] is not None for a in assignments),
    'textOnlyPages': sum(a['asset'] is None for a in assignments),
    'assignmentCounts': dict(Counter(a['asset'] for a in assignments if a['asset'])),
    'observedVariantCountsPerPage': {str(n): len({v for b in books for p in b['pages'] if p['number'] == n for v in p['variantIDs']}) for n in range(1,9)},
    'lightLanguageIssueCount': len(issues),
    'restorationPagesMentioningCompanion': sum('Kestane' in b['pages'][6]['text'] for b in books),
    'sameSeedNamePairsWithDifferentVariantIDs': sum(a['pages'] != b['pages'] and any(x['variantIDs'] != y['variantIDs'] for x,y in zip(a['pages'],b['pages'])) for a,b in zip(books[::2],books[1::2])),
    'scopeLimit': '24 controlled explicit-blueprint samples; not whole-catalog coverage, semantic validator, or production integration.'
}
for name, data in [('art-manifest.json', rules), ('assignments.json', assignments), ('issues.json', issues), ('summary.json', summary)]:
    (ROOT / name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(summary,ensure_ascii=False,indent=2))
