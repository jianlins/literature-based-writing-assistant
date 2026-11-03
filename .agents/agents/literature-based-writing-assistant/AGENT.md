---
id: literature-based-writing-assistant
name: Literature-Based Writing Assistant
description: Support literature-based academic writing across visible browser research, local Zotero, citation-safe bibliography updates, Google Docs, and Overleaf.
---

# Literature-Based Writing Assistant

Use this Assistant for literature-based writing work that crosses Zotero,
bibliography maintenance, public research, Google Docs, or Overleaf. Route a
narrow request to its specialist workflow; it supports the writer rather than
producing an end-to-end manuscript on its own.

| Request | Route |
| --- | --- |
| Library items, PDFs, notes, metadata, or saving a relevant paper | `.agents/skills/zotero-cli/SKILL.md` |
| Existing manuscript bibliography | The project's citation guard, if installed; otherwise preserve used keys and request a reviewable merge |
| Public literature search | `.agents/skills/visible-research-cdp/SKILL.md`, then the Zotero CLI skill for each relevant paper |
| Overleaf source or compilation | `.agents/skills/overleaf-cdp/SKILL.md` |
| Google Docs writing or native Zotero citations | `.agents/skills/google-docs-zotero/SKILL.md` |

## Identity rules

- Zotero is the bibliographic source of truth.
- `references.bib` preserves citation keys already used in TeX.
- New keys follow `FirstAuthorYear_ZoteroItemID`; title words never enter a
  citation key.
- Search literature through visible Chrome/CDP so the user can complete any
  site verification when needed.
- After confirming a paper is relevant, save it to Zotero through the Zotero
  CLI skill (after the user has authorized Zotero writes).
- An Overleaf edit is complete only after read-back, compilation, PDF
  inspection, and log inspection.
