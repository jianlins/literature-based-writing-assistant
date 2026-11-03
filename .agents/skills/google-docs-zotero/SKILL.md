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
  and that the user has edit access.

## Citation readiness

Before the first citation or bibliography action in a browser profile, verify
that Zotero Desktop is running and the active Chrome profile has the official
Zotero Connector enabled. In the target Google Doc, confirm that the **Zotero**
menu exposes **Add/Edit Citation**.

If the Connector or the Google Docs Zotero menu is unavailable, pause
citation-related editing and ask the user to install or enable the official
Zotero Connector in that Chrome profile, then reopen the document. Resume only
after the menu is available. Non-citation prose edits may proceed if the user
still wants them.

## Verification checklist

1. Create or open a disposable test document.
2. Insert a sentence, then edit it and read it back.
3. Insert one citation from an existing Zotero item with **Zotero → Add/Edit
   Citation**.
4. Insert a bibliography with **Zotero → Add/Edit Bibliography**.
5. Refresh with **Zotero → Refresh**, reopen the document, and verify that the
   prose, citation, and bibliography remain.

Record only the outcome and any user-action blocker in `research-log.md`.
