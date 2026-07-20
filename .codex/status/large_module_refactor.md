# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema provider-counteroffer validation context extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
APIs, validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema study-result metadata validation context extraction, selected in
`8b7f0687` and implemented in `045ca428`.
`schema.ex` moved from 4,851 to 4,842 lines.

Next candidate:
Implement and verify the selected provider-counteroffer context, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.
