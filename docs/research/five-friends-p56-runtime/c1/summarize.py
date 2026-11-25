"""Summarize actual first-attempt Swift output; never compose, retry or omit failures."""
import collections,json,sys
from pathlib import Path
rows=json.loads(Path(sys.argv[1]).read_text())
assert len(rows)==5400
out={'scope':'5-6 only; two A0 distributions; first attempts; art binder not measured',
     'legacyPinnedRoom':'setting_moon_window_room_001 (not P56 room alias)',
     'filter':'F copies L with companions filtered to canonical five only',
     'pinnedCellCaveat':'Pinned companions can make L/F identical; unselected arm measures real pool filter effect',
     'nHistory':'P56 has no history request input; A0 measures fixed library repetition without adaptive cooldown',
     'totalRequests':len(rows),'retryCount':0,'groups':{}}
for key in sorted(set((r['arm'],r['scenario']) for r in rows)):
 group=[r for r in rows if (r['arm'],r['scenario'])==key]
 failures=[r for r in group if r.get('failure')]
 seen_sources=set();seen_text=set();source_repeat=text_repeat=0
 for r in group:
  if r.get('failure'):continue
  for s in r['sourceIDs']:
   source_repeat+=s in seen_sources;seen_sources.add(s)
  for s in r['pageSHA256']:
   text_repeat+=s in seen_text;seen_text.add(s)
 reading=[]
 if key[1] in ['alternating','bedtime60']:
  for profile in range(3):
   subset=[r for r in group if r['profile']==profile]
   mechanisms=set();texts=set();window=[];first=None;duplicate=0;shares=[]
   for r in subset:
    if r.get('failure'):shares.append(None);continue
    if r['mechanism'] in mechanisms and first is None:first=r['index']+1
    mechanisms.add(r['mechanism'])
    text=tuple(r['pageSHA256']);duplicate+=text in texts;texts.add(text)
    recent=set(s for prev in window for s in prev)
    shares.append(sum(s in recent for s in r['sourceIDs'])/len(r['sourceIDs']) if r['sourceIDs'] else 0)
    window.append(r['sourceIDs']);window=window[-20:]
   reading.append({'profile':profile,'firstMechanismRepeat':first,'exactTextDuplicateBooks':duplicate,
                   'sourceFamiliarShareWindow20':shares})
 out['groups']['/'.join(key)]={'requests':len(group),'successes':len(group)-len(failures),'failures':len(failures),
   'failureReasons':dict(collections.Counter(r['failure'] for r in failures)),
   'mechanismCounts':dict(collections.Counter(r['mechanism'] for r in group if not r.get('failure'))),
   'repeatedSourceOccurrencesGlobalWithinGroup':source_repeat,'repeatedPageOccurrencesGlobalWithinGroup':text_repeat,
   'readingProfiles':reading}
assert sum(g['requests'] for g in out['groups'].values())==len(rows)
Path(sys.argv[2]).write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:{x:g[x] for x in ['requests','successes','failures']} for k,g in out['groups'].items()},ensure_ascii=False))
