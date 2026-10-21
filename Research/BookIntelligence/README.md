# Children's Book Intelligence

Research tooling for MagicPaper: studies real children's books and turns what it
finds into reviewed guidance for the content line. Not shipped, not part of the
app or the engine.

- How to use it: [`docs/research/BOOK_RESEARCH_AGENT.md`](../../docs/research/BOOK_RESEARCH_AGENT.md)
- Method, rights and confidence rules: [`docs/research/RESEARCH_METHOD.md`](../../docs/research/RESEARCH_METHOD.md)
- Architecture: [`docs/research/BOOK_INTELLIGENCE_ARCHITECTURE.md`](../../docs/research/BOOK_INTELLIGENCE_ARCHITECTURE.md)

```bash
python3 Research/BookIntelligence/book_agent.py status
python3 -m unittest discover -s Research/BookIntelligence/tests -t Research/BookIntelligence/tests
```
