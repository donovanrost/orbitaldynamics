# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-activity callback ownership mapping.

Status:
Ready for publication.

Selected slice:
Point the standalone `candidate_activity.v1` pipe directly at
`Schema.CandidateActivityContracts.validate/3`. Remove the pure facade delegate
while preserving its final pipeline position and issue ordering.

Why this slice:
`Schema` remains a named 7,926-line production hotspot. The established owner
exposes the exact `/3` implementation, and the delegate has exactly one caller.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and
candidate-activity behavior.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The candidate-activity pipe retains `require_fields` and calls the established
owner in the same final position, the delegate is gone, issue ordering and
messages remain exact, schema bytes do not change, focused and complete tests
pass, and bounded review finds no blocker.

Verification gaps:
None.

Tests run:
- Source baseline: `validate_candidate_activity/3` appears exactly once as the
  final standalone pipe call after `require_fields` and once as its pure facade
  definition; `CandidateActivityContracts` exposes exact `validate/3`.
- Focused `candidate_refresh_contracts_test.exs` baseline: 10 tests passed with
  warnings as errors.
- Generated 121-schema bundle: 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked-in bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `7a0c3ac6`: the pipe retains `require_fields`, ends at
  `CandidateActivityContracts.validate/3`, and the delegate is absent.
- Focused candidate-refresh tests: 10 passed; complete schema/export tests: 182
  passed, all with warnings as errors.
- Generated bundle remains 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full export regeneration produced no schema diff; checked digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `7a0c3ac6` was clean after correcting one stale
  next-candidate ledger sentence; 122 exports byte-matched and all proof passed.

Behavior/schema changes:
None.

Outcome:
The pipe references its established owner directly and the delegate is gone.
`schema.ex` decreased from 7,926 to 7,918 lines.

Last completed slice:
Station-calendar-provider cleanup published as `40c2471f`: `schema.ex` shrank
from 7,934 to 7,926 lines, 6 focused and 182 complete tests passed, all 122
exports byte-matched, and bounded review was clean.

Next candidate:
After review and publication, map the next pure facade delegate by exact caller
count, owner signature, and issue-order sensitivity.

Blocked:
No.
