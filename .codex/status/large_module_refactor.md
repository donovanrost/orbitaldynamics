# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema CandidateDiff row callback ownership mapping.

Status:
Publishing.

Selected slice:
Point the standalone `candidate_diff_row.v1` contract pipe directly at
`Schema.CandidateDiffContracts.validate_row/3`. Remove the pure facade delegate
while preserving the pipe position and all issue ordering.

Why this slice:
`Schema` remains a named 8,013-line production hotspot. The established
CandidateDiff owner already exposes the exact `/3` row implementation, and the
facade delegate has exactly one caller, so this is another bounded ownership
cleanup with no contract or dispatch redesign.

Current coupling/problem:
The standalone CandidateDiff row validator still routes through a private
facade callback even though `CandidateDiffContracts` owns the full row
implementation and already calls it internally.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, JSON Schema output, checked-in export bytes, and
CandidateDiff artifact behavior.

Likely extraction target:
Existing `OrbitalDynamics.Schema.CandidateDiffContracts.validate_row/3`.

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
The standalone row contract pipe calls the established CandidateDiff owner in
the same final pipeline position, the pure facade delegate is gone, issue order
and messages remain exact, generated and checked-in schema bytes do not change,
focused and complete schema/export tests pass, and bounded review finds no
blocker.

Verification gaps:
None.

Tests run:
- Source baseline: `validate_candidate_diff_row/3` appears exactly once as the
  final standalone contract-pipe call and once as its pure facade definition;
  the established CandidateDiff owner exposes the exact `validate_row/3`
  implementation.
- Focused `candidate_refresh_contracts_test.exs` baseline: 10 tests passed with
  warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against selection commit `54d993f5`: the standalone row contract
  pipe retains the same `require_fields` and `expect_equal` stages and now ends
  directly at `CandidateDiffContracts.validate_row/3`; the private facade
  delegate is absent and no other facade call site remains.
- Focused `candidate_refresh_contracts_test.exs`: 10 tests passed with warnings
  as errors.
- Complete schema-contract and schema-export suite: 182 tests passed with
  warnings as errors.
- Generated bundle remains exactly 121 schemas, 15,506,740 bytes, and digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full checked-in schema export regeneration completed with no schema diff;
  aggregate bundle digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `54d993f5` was clean:
  exact pipeline and argument equivalence, unchanged CandidateDiff owner, 10
  focused and 182 complete tests, generated and checked bundle digests, all 122
  generated export files byte-matched, strict compile, xref, formatting, sizes,
  ledger, and diff hygiene all matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
The standalone CandidateDiff row contract pipe now calls the established owner
directly and the pure facade delegate is gone. `schema.ex` decreased from 8,013
to 8,005 lines.

Last completed slice:
CandidateDiff source-window-lineage callback cleanup published as `b99f4314`:
the standalone contract pipe now calls the established owner directly,
`schema.ex` shrank from 8,018 to 8,013 lines, 10 focused and 182 complete
schema/export tests passed, all 122 generated schema files byte-matched, and
bounded review was clean.

Next candidate:
Select the direct CandidateDiff row owner described above, preserve the final
pipeline position exactly, then remove the now-unused facade delegate.

Blocked:
No.
