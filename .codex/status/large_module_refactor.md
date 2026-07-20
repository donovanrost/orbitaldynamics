# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema command-window report owner extraction.

Status:
Complete and pushed.

Selected boundary:
Add a focused `CommandWindowValidation` owner for registry-backed required
fields, capability-backed model limits, and the existing report contract.
Route the direct `command_window_report.v1` `Schema` clause through that owner
without moving JSON-schema property dispatch or changing public APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,737 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause owns required-field setup, capability-derived model limits,
  and report-contract orchestration.
- Existing registry, capability-context, and report-contract modules already
  provide every input the focused validation owner needs.
- No route needs recursive `Schema` lookup.

Implementation:
Added a 28-line `CommandWindowValidation` owner for registry-backed required
fields, capability-backed model limits, and the existing report contract.
Routed the direct `command_window_report.v1` `Schema` clause through that owner
while retaining facade-owned JSON-schema property dispatch. `schema.ex` moved
from 4,737 to 4,732 lines.

Verification:
- Strict focused baseline: 30 tests passed.
- Command-window producer, consumer, replay, planner, export, and fixture
  adjacency: 51 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,087 files successfully.

Behavior/schema changes:
None. Required fields, model-limit source, validation ordering and paths, public
`Schema`, validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema command-window report owner extraction, selected in `402d1b0e` and
implemented in `5ce5df9f`. `schema.ex` moved from 4,737 to 4,732 lines.

Next candidate:
Re-rank the remaining direct `Schema` validation clauses, prioritizing a
cohesive owner or owner completion without recursive `Schema` lookup or public
API changes.

Blocked:
No.
