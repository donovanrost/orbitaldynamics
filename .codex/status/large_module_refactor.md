# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema command-window report owner extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, model-limit source, validation ordering and
paths, public `Schema`, validation results, and checked-in exports must remain
unchanged.

Last completed slice:
Schema cadence-import manifest owner completion, selected in `4111306d` and
implemented in `62b6341a`. `schema.ex` moved from 4,739 to 4,737 lines.

Next candidate:
Implement and verify the selected command-window validation owner, then re-rank
the remaining Schema responsibility clusters.

Blocked:
No.
