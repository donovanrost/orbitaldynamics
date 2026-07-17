# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema refreshed-window callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the standalone `refreshed_window.v1` contract pipe directly at
`Schema.CandidateRefreshWindowContracts.validate_refreshed_window/3`. Remove
the pure facade delegate while preserving the pipe position and issue ordering.

Why this slice:
`Schema` remains a named 7,993-line production hotspot. The established
CandidateRefreshWindow owner already exposes the exact `/3` implementation,
and the facade delegate has exactly one caller, so this is a bounded ownership
cleanup after completing the CandidateDiff cluster.

Current coupling/problem:
The standalone refreshed-window validator still routes through a private facade
callback even though `CandidateRefreshWindowContracts` owns the full
implementation and already calls it internally.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and
candidate-refresh window artifact behavior.

Likely extraction target:
Existing
`OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_refreshed_window/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact source call-site, pipe position, and delegate-removal proof
- focused candidate-refresh contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The standalone refreshed-window pipe calls the established owner in the same
final pipeline position, the pure facade delegate is gone, issue order and
messages remain exact, generated and checked-in schema bytes do not change,
focused and complete schema/export tests pass, and bounded review finds no
blocker.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: `validate_refreshed_window/3` appears exactly once as the
  final standalone contract-pipe call and once as its pure facade definition;
  the established CandidateRefreshWindow owner exposes the exact `/3`
  implementation.
- Focused `candidate_refresh_contracts_test.exs` baseline: 10 tests passed with
  warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No refreshed-window callback implementation has started.

Last completed slice:
Optional CandidateDiff report wrapper cleanup published as `4d52f1c4`: both
facade uses now point directly at the established owner, `schema.ex` shrank
from 8,000 to 7,993 lines, 10 focused and 182 complete schema/export tests
passed, all 122 generated schema files byte-matched, and bounded review was
clean.

Next candidate:
Select the direct refreshed-window owner described above, preserve the final
pipeline position exactly, then remove the unused facade delegate.

Blocked:
No.
