# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema plan-delta callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point both facade uses of `validate_plan_delta/3` directly at
`Schema.PlanDeltaContracts.validate/3`: the standalone final pipe and the
campaign-repair callback capture. Remove the pure wrapper.

Why this slice:
`Schema` remains a 7,887-line hotspot. Broad bare-name mapping confirms one
standalone use, one callback capture, and one pure exact-signature wrapper.

Public facade to preserve:
All Schema APIs, callback key/order, exact issue ordering/messages, JSON Schema
and checked export bytes, and standalone/nested plan-delta behavior.

Definition of done:
The standalone pipe retains `require_fields`; the repair callback key remains
between optional station-calendar report and approval requirement; both
reference `PlanDeltaContracts.validate/3`; the wrapper is absent; all proof and
review remain clean.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: one standalone pipe, one campaign-repair callback capture,
  and one pure wrapper.
- Focused campaign repair/strategy baseline: 2 tests passed with warnings as
  errors and covers standalone plus nested plan deltas.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No plan-delta callback implementation has started.

Last completed slice:
Resource-summary cleanup published as `405b94cd`: `schema.ex` shrank from 7,895
to 7,887 lines, corrected focused 8 and complete 182 tests passed, all 122
exports byte-matched, and bounded review was clean.

Next candidate:
Implement both direct owner substitutions and remove the wrapper.

Blocked:
No.
