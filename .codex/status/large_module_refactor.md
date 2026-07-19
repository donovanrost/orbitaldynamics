# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactIntent provider-result normalization extraction.

Status:
Completed and pushed in `54820d60`.

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
  230, five artifact-value call sites, and a self-contained helper family at
  lines 2,037-2,108.
- Activity/timeline normalization, capacity derivation, station-calendar
  evidence, policy classification, identity construction, summary routing,
  and generic recursive key stringification remain outside the boundary.
- Traversal-key ordering, comma splitting, whitespace behavior, nested
  list/map flattening, scalar conversion, map-key handling, and nil/unsupported
  fallback must remain unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactIntent.ProviderResult` as the
  owner of ordered map traversal keys, recursive scalar/list/map collection,
  blank handling, and artifact-string canonicalization.
- Preserved all ContactIntent and root public APIs while routing capability
  metadata and five internal artifact-value call sites through the new owner.
- Removed the provider-result attribute and helper family from the facade;
  generic recursive key stringification remains facade-owned.
- `communications/contact_intent.ex` moved from 2,112 to 2,038 lines; the new
  owner is 77 lines.

Verification:
- Strict focused baseline passed all 27 ContactIntent tests.
- Exact old/new public parity passed for seven captured cases: ordered
  capability keys, preserved nonblank strings, blank strings, flattened lists,
  ordered nested maps, nested lists, and unsupported values.
- Focused and schema-adjacent verification passed 35 tests across ContactIntent
  behavior and communications contracts.
- Static checks confirm the old attribute and private helper family left the
  facade; xref reports only ContactIntent as a runtime caller of the new owner.
- Strict warning-clean forced compile passed for 3,987 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactIntent provider-result normalization extraction, selected in
`7b01da01` and implemented in `54820d60`.
`communications/contact_intent.ex` moved from 2,112 to 2,038 lines; the
dedicated provider-result owner is 77 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/station_calendar.ex`,
`communications/contact_filter.ex`, and `resource_filter.ex` are now the
largest ordinary eligible facades near 2,060 lines.

Blocked:
No.
