# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema spacecraft-state-estimate callback ownership mapping.

Status:
Publishing.

Selected slice:
Point the standalone `spacecraft_state_estimate.v1` contract pipe directly at
`Schema.AcceptedStateContracts.validate_spacecraft_state_estimate/3`. Remove
the pure facade delegate while preserving the pipe position and issue ordering.

Why this slice:
`Schema` remains a named 7,963-line production hotspot. The established
AcceptedState owner already exposes the exact `/3` implementation, and the
facade delegate has exactly one caller, so this completes the adjacent
accepted-state standalone contract pair.

Current coupling/problem:
The standalone spacecraft-state-estimate validator still routes through a
private facade callback even though `AcceptedStateContracts` owns the complete
implementation.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and accepted
state artifact behavior.

Likely extraction target:
Existing
`OrbitalDynamics.Schema.AcceptedStateContracts.validate_spacecraft_state_estimate/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact source call-site, pipe position, and delegate-removal proof
- focused accepted-state contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The standalone spacecraft-state pipe calls the established owner in the same
final position, the pure facade delegate is gone, issue order and messages stay
exact, schema bytes do not change, focused and complete tests pass, and bounded
review finds no blocker.

Verification gaps:
None.

Tests run:
- Source baseline: `validate_spacecraft_state_estimate/3` appears exactly once
  as the final standalone contract-pipe call after `require_fields` and once as
  its pure facade definition; the established AcceptedState owner exposes the
  exact `/3` implementation.
- Focused `accepted_state_contracts_test.exs` baseline: 6 tests passed with
  warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against selection commit `0bda98e9`: the standalone
  spacecraft-state-estimate pipe retains `require_fields` and now ends directly
  at `AcceptedStateContracts.validate_spacecraft_state_estimate/3`; the private
  facade delegate is absent and no other facade call site remains.
- Focused `accepted_state_contracts_test.exs`: 6 tests passed with warnings as
  errors.
- Complete schema-contract and schema-export suite: 182 tests passed with
  warnings as errors.
- Generated bundle remains exactly 121 schemas, 15,506,740 bytes, and digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full checked-in schema export regeneration completed with no schema diff;
  aggregate bundle digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `0bda98e9` was clean:
  exact pipeline and argument equivalence, unchanged accepted-state owner, 6
  focused and 182 complete tests, generated and checked bundle digests, all 122
  generated export files byte-matched, strict compile, xref, formatting, sizes,
  ledger, and diff hygiene matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
The standalone spacecraft-state-estimate contract pipe now calls the
established owner directly and the pure facade delegate is gone. `schema.ex`
decreased from 7,963 to 7,958 lines.

Last completed slice:
Maneuver-execution-delta callback cleanup published as `5bc0e60f`: the
standalone contract pipe now calls the established owner directly, `schema.ex`
shrank from 7,968 to 7,963 lines, 6 focused and 182 complete schema/export
tests passed, all 122 generated schema files byte-matched, and bounded review
was clean.

Next candidate:
Select the direct spacecraft-state-estimate owner described above, preserve the
final pipeline position exactly, then remove the unused facade delegate.

Blocked:
No.
