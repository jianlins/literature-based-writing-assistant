# Literature-Based Writing Assistant project policy

For a request involving Zotero, bibliography work, public literature research,
or Overleaf, first read
`.agents/agents/literature-based-writing-assistant/AGENT.md`. It selects the
applicable specialist skill or workflow.

## Repository rules

Keep manuscript source, `references.bib`, notes, and a concise research log in
the repository. Do not commit TeX build output, browser profiles, `.env` files,
credentials, or local CDP port choices. Keep every externally visible claim
traceable to a source.

Before launching Chrome for any browser or CDP workflow, inspect the available
connected CDP sessions and tabs and reuse a suitable one. When a new instance
is needed, read `config/browser-profile.local.json` and use its selected
dedicated profile and CDP port. If the file is missing or its path is
unavailable, ask the user to select a dedicated profile, then save that
absolute path and port there. Never select the user's normal browsing profile
without explicit approval.
Use the platform launcher in `.agents/scripts/` instead of opening Chrome
directly: it first checks the requested CDP port and leaves a responding
browser available for the workflow to attach.

Before creating or placing research artifacts, read `WORKSPACE_LAYOUT.md`.
It is the authoritative directory contract for source PDFs, extracted text,
plans, notes, handoffs, and the research log.

For project PDF-to-Markdown work, use the controlled converter specified in
`WORKSPACE_LAYOUT.md`; do not generate extracted text with a model.
