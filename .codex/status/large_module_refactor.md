# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactIntent capacity-evidence extraction.

Status:
Completed and pushed in `f01406f6`.

Selected boundary:
Extract station/required capacity path contracts, capability and artifact
assumption metadata, station-capacity evidence aggregation, required-capacity
selection/source classification, nested source-calendar lookup, and unit
normalization into
`OrbitalDynamics.Communications.ContactIntent.CapacityEvidence`. Preserve all
ContactIntent and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `communications/contact_intent.ex` at 2,038 lines,
  the largest ordinary eligible facade.
- ContactIntent's station/required capacity path contracts occupy lines 77-184;
  the corresponding context/source/value helper family remains in the facade
  at lines 1,231-1,357.
- The same owner can supply the capability metadata and summary assumptions
  derived from those contracts, avoiding duplicated path declarations.
- Activity/timeline normalization, contact identity, station availability and
  reservations, policy classification, summary routing, feedback evidence,
  provider results, and cadence handoff remain outside the boundary.
- Exact path ordering, fraction/percent unit metadata, direct-before-nested
  required-capacity precedence, source classification, source-calendar
  traversal, numeric-string parsing, percent conversion, unit-interval
  validation, station min/max aggregation, and sparse output must remain
  unchanged.

Implementation:
- Added `OrbitalDynamics.Communications.ContactIntent.CapacityEvidence` as the
  owner of station/required capacity path contracts, capability metadata,
  summary assumptions, station evidence aggregation, required-capacity source
  classification, nested source-calendar lookup, and unit conversion.
- Preserved all ContactIntent and root public APIs; capability construction,
  contact-intent summary recomputation, and row construction now call the
  dedicated owner.
- Removed all capacity path attributes and the full capacity evidence helper
  family from the facade.
- `communications/contact_intent.ex` moved from 2,038 to 1,785 lines; the new
  owner is 281 lines.

Verification:
- Strict focused baseline passed all 27 ContactIntent tests.
- Exact old/new public parity passed for five captured cases: capability
  metadata, direct capacity evidence, nested source-calendar evidence, invalid
  ranges, and summary recomputation.
- Focused and communications-contract verification passed 35 tests.
- Static checks confirm all capacity path attributes and evidence helpers left
  the facade; remaining similarly named functions are summary aggregators.
- Xref reports only ContactIntent as a runtime caller of the owner.
- Strict warning-clean forced compile passed for 3,991 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ContactIntent capacity-evidence extraction, selected in `85949f03` and
implemented in `f01406f6`.
`communications/contact_intent.ex` moved from 2,038 to 1,785 lines; the
dedicated capacity-evidence owner is 281 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `operational_readiness.ex` is now the largest ordinary eligible
facade at 2,018 lines, closely followed by RecommendationRiskContext and
OrbitData at 2,016 lines.

Blocked:
No.
