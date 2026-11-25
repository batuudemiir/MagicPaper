#!/usr/bin/env python3
"""Serialize immutable authored corpora into a separate runtime derivative."""
import hashlib, importlib.util, json
from pathlib import Path
HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
spec = importlib.util.spec_from_file_location('v1', ROOT/'five-friends-56-runtime-v1/build_runtime_package.py')
v1 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v1)
def digest(data): return hashlib.sha256(data).hexdigest()
def write(name, obj):
    data = (json.dumps(obj, ensure_ascii=False, indent=2)+'\n').encode()
    (HERE/name).write_bytes(data)
    return data

def main():
    old = json.loads((ROOT/'five-friends-56-runtime-v1/payload.json').read_bytes())
    corpora, books, lineages = [], [], []
    for corpus_id, causal_path in [('five-friends-56-v1', ROOT/'five-friends-56-runtime-v1/causal-evidence.json'), ('five-friends-56-expansion-v1', ROOT/'five-friends-56-expansion-v1/causal-evidence.json')]:
        directory = ROOT/corpus_id
        source_bytes = (directory/'sources.json').read_bytes()
        causal_bytes = causal_path.read_bytes()
        corpora.append(dict(id=corpus_id, sourcesJSON=source_bytes.decode(), sourcesSHA256=digest(source_bytes), causalEvidenceJSON=causal_bytes.decode(), causalEvidenceSHA256=digest(causal_bytes)))
        source_index = {source['id']:(i,source) for i,source in enumerate(json.loads(source_bytes)['sources'])}
        evidence = {(r['bookID'],r['pageNumber']):r for r in json.loads(causal_bytes)['records']}
        manifest = json.loads((directory/'manifest.json').read_bytes())
        for entry in manifest['books']:
            raw = (directory/entry['file']).read_bytes()
            if digest(raw) != entry['sha256FileBytes']: raise ValueError('Authored digest mismatch')
            book = json.loads(raw); pages=[]
            for page in book['pages']:
                part=page['provenance']['parts'][0]
                index,parent=source_index[part['sourceID']]
                text=v1.template(parent['text']); role=page['role']
                actors=['child'] if role in v1.CHILD_ROLES else ([book['context']['companionID']] if role in v1.FRIEND_ROLES else ['child',book['context']['companionID']])
                pages.append(dict(number=page['pageNumber'],beat=role,actorIDs=actors,causalEvidence=evidence[(book['id'],page['pageNumber'])], templateID='p56_runtime_'+parent['id'],templateText=text,templateSHA256=digest(text.encode()), parentSourceID=parent['id'],parentSHA256=parent['sha256UTF8'],parentText=parent['text'],parentPointer=f'{corpus_id}/sources.json#/sources/{index}',parentSourceIndex=index,semantics=page['semantics'],artHandoff=page['artHandoff'],intensity=page['editorialIntensity'],settingID=page['context']['settingID']))
            books.append(dict(id=book['id'],titleTemplate=v1.template(book['title']),structureID=book['planLabel'],mechanism=book['mechanismKey'],mode=book['context']['mode'],companionID=book['context']['companionID'],worldID=book['context']['worldID'],discoveryID=book['context']['discoveryID'],authoredBookSHA256=digest(raw),authoredBookJSON=raw.decode(),pages=pages))
            lineages.append(dict(bookID=book['id'],corpusID=corpus_id,eventID=book.get('variantID','event01'),baseBookID=book.get('baseBookID',book['id'])))
    payload={k:old[k] for k in ['engineBehaviorID','productionEnabled','artApproved','companions','settings','worldID','structures']}
    payload.update(schemaVersion=2,packageVersion=HERE.name,corpora=corpora,books=books,bookLineages=lineages)
    review_path = HERE.parents[2]/'docs/research/five-friends-p56-runtime/c3-safety/content-safety-annotations.json'
    payload['safetyReview'] = json.loads(review_path.read_bytes())
    data=write('payload.json',payload)
    write('manifest.json',dict(schemaVersion=2,packageVersion=HERE.name,engineBehaviorID=old['engineBehaviorID'],payloadSHA256=digest(data),productionEnabled=False,artApproved=False))
if __name__=='__main__': main()
