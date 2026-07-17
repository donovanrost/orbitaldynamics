# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema CandidateDiff invalidated-candidate callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the standalone `invalidated_candidate.v1` contract pipe directly at
`Schema.CandidateDiffContracts.validate_invalidated_candidate/3`. Remove the
pure facade delegate while preserving the pipe position and issue ordering.

Why this slice:
`Schema` remains a named 8,005-line production hotspot. The established
CandidateDiff owner already exposes the exact `/3` implementation, and the
facade delegate has exactly one caller, so this completes the cluster of
single-call CandidateDiff contract-pipe wrappers without redesigning dispatch.

Current coupling/problem:
The standalone invalidated-candidate validator still routes through a private
facade callback even though `CandidateDiffContracts` owns the full
implementation and already calls it internally.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and
CandidateDiff artifact behavior.

Likely extraction target:
Existing
`OrbitalDynamics.Schema.CandidateDiffContracts.validate_invalidated_candidate/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact source call-site, pipe position, and delegate-removal proof
- focused CandidateDiff contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The standalone invalidated-candidate pipe calls the established CandidateDiff
owner in the same final pipeline position, the pure facade delegate is gone,
issue order and messages remain exact, generated and checked-in schema bytes do
not change, focused and complete schema/export tests pass, and bounded review
finds no blocker.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: `validate_invalidated_candidate/3` appears exactly once as
  the final standalone contract-pipe call and once as its pure facade
  definition; the established CandidateDiff owner exposes the exact `/3`
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
No CandidateDiff invalidated-candidate callback implementation has started.

Last completed slice:
CandidateDiff row callback cleanup published as `e36322fb`: the standalone
contract pipe now calls the established owner directly, `schema.ex` shrank from
8,013 to 8,005 lines, 10 focused and 182 complete schema/export tests passed,
all 122 generated schema files byte-matched, and bounded review was clean.

Next candidate:
Select the direct CandidateDiff invalidated-candidate owner described above,
preserve the final pipeline position exactly, then remove the unused facade
delegate.

Blocked:
No.
