# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer validation context extraction.

Status:
Completed and pushed.

Selected boundary:
Add a `ProviderCounterofferValidation` owner-default entry point for the report,
review summary, import-readiness summary, and plan-impact summary artifacts.
Derive requirements from `ProviderCounterofferRegistryContracts`, route all
four direct `Schema` clauses, and keep both artifact-specific contract modules'
APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,842 lines; the other
  targeted public facades are now 164 to 524 lines.
- The four adjacent clauses repeat required-field setup and form the exact
  family owned by `ProviderCounterofferRegistryContracts`.
- `ProviderCounterofferReportContracts` and
  `ProviderCounterofferSummaryContracts` own all artifact-specific validation.
- No selected route needs callbacks, recursive `Schema` lookup, model limits,
  or facade-local context.

Implementation:
Added `ProviderCounterofferValidation` as the registry-backed family owner for
the four selected artifacts and routed their direct `Schema` validation clauses
through it. `schema.ex` moved from 4,842 to 4,829 lines.

Verification:
- Strict focused baseline: 20 tests passed.
- Focused plus adjacent validation, station-provider, operator-review,
  candidate-refresh replay, campaign-planner source-report, and export coverage
  after extraction: 35 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the four intended direct facade routes.
- `mix xref trace` confirmed all four runtime calls originate in `schema.ex`; a
  bounded production search found no other owner callers.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,084 files with warnings as errors.
- Bounded diff review confirmed registry-owned requirements, contract routing,
  validation ordering, and validation paths remain unchanged.
- Implementation committed and pushed as `45176e44`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` APIs,
validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema provider-counteroffer validation context extraction, selected in
`ab187bb8` and implemented in `45176e44`.
`schema.ex` moved from 4,842 to 4,829 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
