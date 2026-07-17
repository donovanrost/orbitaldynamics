# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-activity callback ownership mapping.

Status:
Ready for implementation.

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
- Implementation and post-change verification pending.

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

Behavior/schema changes:
None.

Outcome:
No candidate-activity callback implementation has started.

Last completed slice:
Station-calendar-provider cleanup published as `40c2471f`: `schema.ex` shrank
from 7,934 to 7,926 lines, 6 focused and 182 complete tests passed, all 122
exports byte-matched, and bounded review was clean.

Next candidate:
Implement the direct owner substitution and remove the unused delegate.

Blocked:
No.
