"""Compare unfiltered first-attempt measurements without recomposition or retries."""
from pathlib import Path
import collections,json,sys
old_dir,new_dir,out=map(Path,sys.argv[1:4]);out.mkdir(parents=True,exist_ok=True)
old=json.loads((old_dir/'sampling.json').read_text());new=json.loads((new_dir/'sampling.json').read_text())
for report in (old,new):
 assert report['attempts']==1500 and len(report['attemptRecords'])==1500
 assert report['successes']+report['failures']==report['attempts']
 assert report['retries']==0 and len(report['cellAttempts'])==15
 assert set(report['cellAttempts'].values())=={100}
keys=lambda r:[(x['cell'],x['seed']) for x in r['attemptRecords']]
assert keys(old)==keys(new)
fields=['attempts','successes','failures','retries','uniqueBooks','fixedBooksPerCell','repeatedSourcePageOccurrences','repeatedRenderedPageOccurrences','firstRepeatAttemptByCell']
summary={'scope':'N1500 unfiltered same-cell/seed first attempts; repeated page/source counts global',
         'before':{k:old[k] for k in fields},'after':{k:new[k] for k in fields},
         'artAccepted':False,'productionEnabled':False,'a0':{}}
rows=json.loads((new_dir/'a0-before-after.json').read_text());assert len(rows)==1200
for arm in ['N-v1','N-v2']:
 for scenario in ['alternating','bedtime60']:
  group=[r for r in rows if r['arm']==arm and r['scenario']==scenario]
  assert len(group)==300
  profiles=[]
  for profile in range(3):
   seen=set();seen_books=set();window=[];duplicate=0;first=None;familiar=[]
   subset=[r for r in group if r['profile']==profile]
   assert [r['index'] for r in subset]==list(range(100))
   for r in subset:
    if r.get('failure'):familiar.append(None);continue
    text=tuple(r['pageSHA256']);duplicate+=text in seen;seen.add(text)
    if r['bookID'] in seen_books and first is None:first=r['index']+1
    seen_books.add(r['bookID'])
    recent=set(s for book in window for s in book)
    familiar.append(sum(s in recent for s in r['sourceIDs'])/len(r['sourceIDs']))
    window.append(r['sourceIDs']);window=window[-20:]
   profiles.append({'profile':profile,'exactTextDuplicateBooks':duplicate,'firstBookRepeat':first,'sourceFamiliarShareWindow20':familiar})
  summary['a0'][arm+'/'+scenario]={'requests':300,'successes':sum(not r.get('failure') for r in group),
     'failures':sum(bool(r.get('failure')) for r in group),'profiles':profiles}
for name,report in [('before-sampling.json',old),('sampling.json',new)]:
 (out/name).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
(out/'a0-before-after.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
(out/'comparison.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:{x:v[x] for x in ['attempts','successes','failures','uniqueBooks','fixedBooksPerCell']} for k,v in [('before',summary['before']),('after',summary['after'])]},ensure_ascii=False))
print(json.dumps({k:[p['exactTextDuplicateBooks'] for p in v['profiles']] for k,v in summary['a0'].items()},ensure_ascii=False))
