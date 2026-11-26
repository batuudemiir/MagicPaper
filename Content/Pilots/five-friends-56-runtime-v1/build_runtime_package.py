#!/usr/bin/env python3
"""Explicit, reproducible authored -> internal runtime derivative. No bundle activation."""
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
AUTHORED = HERE.parent / 'five-friends-56-v1'
def digest(data): return hashlib.sha256(data).hexdigest()
def read(name): return json.loads((AUTHORED / name).read_bytes())
def write(name, obj):
    data = (json.dumps(obj, ensure_ascii=False, indent=2) + '\n').encode()
    (HERE / name).write_bytes(data)
    return data

# These are exact authored proper-name tokens, not a global rendered-text replacement.
# The renderer interprets the suffix spelling as a case request, then inflects the actual name.
NAME = re.compile(r'(?<![\w])Deniz(?:[’\'](in|e|i|de|den))?(?![\w’\'])')
def template(text):
    result = NAME.sub(lambda m: '{{child.name}}' + ("'" + m[1] if m[1] else ''), text)
    if 'Deniz' in result:
        raise ValueError('Unmapped synthetic proper-name form: ' + text)
    return result

CHILD_ROLES = set('ritual_chosen child_names_sound attention_released child_prepares child_yields_space one_memory_selected child_limits_telling story_released child_predicts observe_contact child_infers recheck child_repositions compare_views child_combines child_observation_plan visible_change child_compares child_step_choice first_step child_crosses child_orders first_piece child_completes last_seen_recalled child_selects_route retrace child_recognizes object_recovered'.split())
FRIEND_ROLES = set('friend_listens friend_preference friend_receives_memory friend_one_observation friend_second_view friend_waits friend_support friend_contribution'.split())
def main():
    manifest, sources = read('manifest.json'), read('sources.json')['sources']
    index = {s['id']: (i, s) for i, s in enumerate(sources)}
    structures = read('structures.json')['structures']
    evidence_records = json.loads((HERE/'causal-evidence.json').read_text())['records']
    evidence = {(e['bookID'], e['pageNumber']): e for e in evidence_records}
    books = []
    for item in manifest['books']:
        raw = (AUTHORED / item['file']).read_bytes()
        if digest(raw) != item['sha256FileBytes']: raise ValueError('Authored book digest mismatch')
        book = json.loads(raw)
        pages = []
        for page in book['pages']:
            part = page['provenance']['parts'][0]
            source_index, parent = index[part['sourceID']]
            if parent['text'] != page['text'] or digest(parent['text'].encode()) != parent['sha256UTF8']:
                raise ValueError('Authored source mismatch')
            if part['sourceTextDigest'] != parent['sha256UTF8'] or part['sourcePointer'] != f'sources.json#/sources/{source_index}':
                raise ValueError('Authored pointer mismatch')
            text = template(parent['text'])
            role = page['role']
            actors = ['child'] if role in CHILD_ROLES else ([book['context']['companionID']] if role in FRIEND_ROLES else ['child', book['context']['companionID']])
            causal = dict(evidence[(book['id'], page['pageNumber'])])
            if causal['parentSourceID'] != parent['id'] or causal['quote'] not in parent['text'] or causal['attributionQuote'] not in index[causal['attributionSourceID']][1]['text']:
                raise ValueError('Stale causal quote evidence')
            causal['quoteSHA256'] = digest(causal['quote'].encode())
            pages.append(dict(number=page['pageNumber'], beat=role, actorIDs=actors, causalEvidence=causal,
                templateID='p56_runtime_' + parent['id'], templateText=text,
                templateSHA256=digest(text.encode()), parentSourceID=parent['id'],
                parentSHA256=parent['sha256UTF8'], parentText=parent['text'],
                parentPointer=part['sourcePointer'], parentSourceIndex=source_index,
                semantics=page['semantics'], artHandoff=page['artHandoff'],
                intensity=page['editorialIntensity'], settingID=page['context']['settingID']))
        books.append(dict(id=book['id'], titleTemplate=template(book['title']), structureID=book['planLabel'],
            mechanism=book['mechanismKey'], mode=book['context']['mode'], companionID=book['context']['companionID'],
            worldID=book['context']['worldID'], discoveryID=book['context']['discoveryID'],
            authoredBookSHA256=digest(raw), authoredBookJSON=raw.decode(), pages=pages))
    payload = dict(schemaVersion=1, packageVersion=HERE.name, engineBehaviorID='offline-p56-v1',
        productionEnabled=False, companions=manifest['companions'], settings=manifest['settings'],
        worldID=manifest['worldID'], structures=structures, books=books,
        artApproved=False, causalEvidenceJSON=(HERE/'causal-evidence.json').read_text(), causalEvidenceSHA256=digest((HERE/'causal-evidence.json').read_bytes()), authoredSourcesJSON=(AUTHORED/'sources.json').read_text(), authoredSourcePayloadSHA256=digest((AUTHORED/'sources.json').read_bytes()))
    data = write('payload.json', payload)
    write('manifest.json', dict(schemaVersion=1, packageVersion=HERE.name, engineBehaviorID='offline-p56-v1',
        payloadSHA256=digest(data), productionEnabled=False, artApproved=False))

if __name__ == '__main__': main()
