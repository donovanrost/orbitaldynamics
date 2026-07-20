# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation validation context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Add owner-default entry points across ContactAllocationValidation's optional
report, report, row, capacity-pack group, counts, summary families, and
duplicate evidence. Compose the callback graph entirely from existing schema
owners, route every Schema consumer directly, and remove eleven wrappers plus
the shared callback bag. Keep all callback-based owner APIs.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 5,707 lines; the other
  targeted public facades are now 164 to 524 lines.
- The callback bag contains only ContactAllocationValidation self-callbacks and
  existing station/contact/contention/execution/priority schema owners.
- Exact usage spans six required artifact validations, one optional report,
  nested row/group/count validation, Cadence, and operator-review callbacks.
- No callback requires recursive Schema registry validation or facade
  capability context.
- Owner-default entry points preserve every callback-based API.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema operational-timeline validation context extraction, selected in
`68d32061` and implemented in `9b73959d`.
`schema.ex` moved from 5,734 to 5,707 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters. Preserve
the context-bearing CommonJsonSchema wrappers unless a separate exact
ownership boundary is proven.

Blocked:
No.
