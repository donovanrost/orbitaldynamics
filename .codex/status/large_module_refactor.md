# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema validation-acceptance metadata direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the Schema facade's one-hop safety-case count-fields helper.
Route the candidate-refresh property-dispatch callback directly to
`ValidationAcceptanceReportContracts.safety_case_count_fields/0`.
Keep candidate-refresh property dispatch, validation-acceptance algorithms,
and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,071 lines.
- The helper calls the same-arity ValidationAcceptanceReportContracts owner API
  and adds no guards, defaults, transformation, or caching.
- Its only consumer can capture the owner directly with unchanged lazy
  evaluation.
- Exact count-field values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Removed the one-hop safety-case count-fields helper and routed the
candidate-refresh callback directly to ValidationAcceptanceReportContracts.
`schema.ex` moved from 6,071 to 6,068 lines.

Verification:
- Strict focused candidate-refresh/validation-evidence/export baseline before
  routing: 29 passed.
- The same strict focused suite after routing: 29 passed.
- Strict schema/export-validation tasks plus adjacent fixture-visibility and
  validation coverage: 5 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ValidationAcceptanceReportContracts` reports the
  expected `schema.ex` and CandidateRefreshReportContracts callers.
- Static search confirms the facade helper definition and indirect capture are
  gone.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `5ec36956` pushed to `main`.

Behavior/schema changes:
None. Public facades, lazy callback timing, count-field values and ordering,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema validation-acceptance metadata direct routing, selected in `526b9b0c`
and implemented in `5ec36956`.
`schema.ex` moved from 6,071 to 6,068 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
