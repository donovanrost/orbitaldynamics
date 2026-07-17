# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema remaining-horizon callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the standalone `remaining_horizon.v1` contract pipe directly at
`Schema.CandidateRefreshWindowContracts.validate_remaining_horizon/3`. Remove
the pure facade delegate while preserving the pipe position and issue ordering.

Why this slice:
`Schema` remains a named 7,988-line production hotspot. The established
CandidateRefreshWindow owner already exposes the exact `/3` implementation,
and the facade delegate has exactly one caller, making this the second bounded
cleanup in the window-contract cluster.

Current coupling/problem:
The standalone remaining-horizon validator still routes through a private
facade callback even though `CandidateRefreshWindowContracts` owns the full
implementation.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and
candidate-refresh horizon artifact behavior.

Likely extraction target:
Existing
`OrbitalDynamics.Schema.CandidateRefreshWindowContracts.validate_remaining_horizon/3`.

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
The standalone remaining-horizon pipe calls the established owner in the same
final position, the pure facade delegate is gone, issue order and messages stay
exact, generated and checked-in schema bytes do not change, focused and
complete schema/export tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: `validate_remaining_horizon/3` appears exactly once as the
  final standalone contract-pipe call after `require_fields` and once as its
  pure facade definition; the established CandidateRefreshWindow owner exposes
  the exact `/3` implementation.
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
No remaining-horizon callback implementation has started.

Last completed slice:
Refreshed-window callback cleanup published as `49dde5ab`: the standalone
contract pipe now calls the established owner directly, `schema.ex` shrank from
7,993 to 7,988 lines, 10 focused and 182 complete schema/export tests passed,
all 122 generated schema files byte-matched, and bounded review was clean.

Next candidate:
Select the direct remaining-horizon owner described above, preserve the final
pipeline position exactly, then remove the unused facade delegate.

Blocked:
No.
