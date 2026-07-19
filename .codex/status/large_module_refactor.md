# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactIntent provider-result normalization extraction.

Status:
Selected; strict focused baseline pending.

Selected boundary:
Extract the provider-result map traversal key contract, recursive scalar/list/
map value collection, blank handling, and artifact-string canonicalization
into `OrbitalDynamics.Communications.ContactIntent.ProviderResult`. Preserve
all ContactIntent and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_intent.ex` at 2,112 lines,
  the largest ordinary eligible facade.
- The summary/routing aggregation region was assessed first but remains coupled
  to capacity derivation, direction normalization, capability limits, and
  facade-owned assumptions, so it is not the selected boundary.
- Provider-result normalization has one explicit traversal key contract at line
  230, four artifact-value call sites, and a self-contained helper family at
  lines 2,037-2,108.
- Activity/timeline normalization, capacity derivation, station-calendar
  evidence, policy classification, identity construction, summary routing,
  and generic recursive key stringification remain outside the boundary.
- Traversal-key ordering, comma splitting, whitespace behavior, nested
  list/map flattening, scalar conversion, map-key handling, and nil/unsupported
  fallback must remain unchanged.

Implementation:
Pending.

Verification:
Pending strict focused baseline, exact old/new public parity, focused and
adjacent tests, static ownership checks, xref, strict warning-clean compile,
formatting, and diff checks.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext contact-allocation extraction, selected in
`8496a10e` and implemented in `567b1b93`.
`recommendation_risk_context.ex` moved from 2,142 to 2,016 lines; the dedicated
contact-allocation context owner is 160 lines.

Next candidate:
Complete the selected ContactIntent provider-result normalization extraction.

Blocked:
No.
