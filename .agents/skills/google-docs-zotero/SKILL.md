---
name: google-docs-zotero
description: Guide writing and citation-safe editing in Google Docs while Zotero remains the source of truth and Overleaf remains a separate TeX surface.
---

# Google Docs + Zotero workflow

Use this workflow when a user asks to write or edit a shared Google Doc,
insert or review citations, or prepare a Google Docs manuscript for delivery.

## Rules

- Zotero is the bibliographic source of truth.
- Use the official Zotero Connector and the native Google Docs Zotero menu for
  live citations and bibliographies. Never synthesize or modify Google Docs
  citation fields programmatically.
- Do not use `references.bib` as an input to Google Docs and do not export
  native Google Docs citations into that file.
- Do not unlink citations in a working document. Only unlink citations in a
  user-approved final copy.
- Before editing a shared document, confirm that it is the intended document
  and that the user has edit access. If citation editing is required, Zotero
  desktop must be running and the Connector must be installed.

## Verification checklist

1. Create or open a disposable test document.
2. Insert a sentence, then edit it and read it back.
3. Insert one citation from an existing Zotero item with **Zotero → Add/Edit
   Citation**.
4. Insert a bibliography with **Zotero → Add/Edit Bibliography**.
5. Refresh with **Zotero → Refresh**, reopen the document, and verify that the
   prose, citation, and bibliography remain.

Record only the outcome and any user-action blocker in `research-log.md`.
