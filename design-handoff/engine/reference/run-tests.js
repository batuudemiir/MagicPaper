const E = require('./engine.js');
(async () => {
  const cases = E.buildCases(['A','B','C','D','E','F'], false); let fail = 0;
  for (const cs of cases) {
    const c = await E.engine({...cs.form}, {decide: async () => cs.decision});
    const why = E.judge(E.expected(cs.form, cs.decision), E.outcomeOf(c));
    if (why.length) { fail++; console.log('FAIL', cs.id, cs.title, why.join(' | ')); }
  }
  console.log(`${cases.length - fail} / ${cases.length} geçti`); process.exit(fail ? 1 : 0);
})();
