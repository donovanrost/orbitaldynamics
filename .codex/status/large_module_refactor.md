# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation owner routing extraction.

Status:
Completed and pushed.

Selected boundary:
Add registry-backed owner-default entry points to `ContactAllocationValidation`
for the allocation report, base summary, reservation-conflict summary,
station-pressure summary, capacity-pack summary, and provider-reservation
request summary. Derive requirements from their six registry modules, route all
six direct `Schema` clauses, and preserve every existing owner API.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,795 lines; the other
  targeted public facades are now 164 to 524 lines.
- The six adjacent clauses repeat required-field setup and already delegate
  artifact-specific validation to `ContactAllocationValidation`.
- Their six registry modules own every required field.
- The owner already owns allocation model limits and every nested report,
  row, capacity-pack, calendar, filter, and contention callback.
- No route needs recursive `Schema` lookup.

Implementation:
Added a registry-backed `ContactAllocationValidation.validate_artifact/4`
entry point plus six compact owner-default wrappers and routed all selected
direct `Schema` clauses through the existing owner. `schema.ex` moved from
4,795 to 4,787 lines.

Verification:
- Strict focused baseline: 100 tests passed.
- Focused plus adjacent allocation, validation, operator-review, Cadence import,
  candidate-refresh replay, campaign-planner source-report, contract, and
  export coverage after extraction: 126 tests passed.
- Full schema export completed with no checked-in artifact changes.
- Static routing review found exactly the six intended direct facade routes.
- `mix xref trace` confirmed all six runtime calls originate in `schema.ex`.
- Formatting and `git diff --check` passed.
- Strict forced compile passed across 4,086 files with warnings as errors.
- Bounded diff review confirmed all six registry-owned requirements,
  owner-default model limits and callbacks, contract routing, validation
  ordering, and paths remain unchanged.
- Implementation committed and pushed as `6cc22c0b`.

Behavior/schema changes:
None. Required fields, validation ordering and paths, public `Schema` and
existing `ContactAllocationValidation` APIs, validation results, and checked-in
exports remain unchanged.

Last completed slice:
Schema contact-allocation owner routing extraction, selected in `efc25373` and
implemented in `6cc22c0b`.
`schema.ex` moved from 4,795 to 4,787 lines.

Next candidate:
Re-rank the remaining Schema responsibility clusters and select the next
facade-preserving extraction.

Blocked:
No.
