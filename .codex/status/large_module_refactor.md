# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optional CandidateDiff report callback ownership handoff.

Status:
Published as `4d52f1c4`.

Selected slice:
Point both facade uses of `validate_optional_candidate_diff_report/3` directly
at `Schema.CandidateDiffContracts.validate_optional_report/3`: the top-level
`candidate_diff_report.v1` contract call and the matching callback-bag capture.
Remove the pure facade wrapper while preserving call arguments, callback key,
bag position, and issue ordering.

Why this slice:
`Schema` remains a named 8,000-line production hotspot. The established
CandidateDiff owner already exposes the exact `/3` implementation. This is the
last CandidateDiff-specific forwarding wrapper in the facade after the three
single-call contract-pipe cleanups.

Current coupling/problem:
Top-level CandidateDiff report validation and a shared contract callback bag
still route through a pure facade wrapper even though both can reference the
established owner without changing the callback contract.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, callback-bag key and order,
exact validation issue ordering, paths and messages, JSON Schema output,
checked-in export bytes, and CandidateDiff artifact behavior.

Likely extraction target:
Existing
`OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_report/3`.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact direct-call arguments, callback key/position, and wrapper-removal proof
- focused CandidateDiff contract tests
- complete schema-contract/export tests and full checked-in export regeneration
- aggregate generated and checked-in schema bundle digests
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The top-level contract calls the established owner with unchanged arguments,
the callback bag captures the same owner `/3` under the same key and between
the same neighboring entries, the wrapper is gone, issue order and messages
remain exact, schema bytes do not change, focused and complete tests pass, and
bounded review finds no blocker.

Verification gaps:
None.

Tests run:
- Source baseline: `validate_optional_candidate_diff_report/3` has exactly two
  facade uses and one pure wrapper definition. The direct call passes
  `[]`, `"$"`, and `artifact`. The callback key is between
  `validate_optional_link_capacity_report` and
  `validate_optional_candidate_rejection_report`.
- Focused `candidate_refresh_contracts_test.exs` baseline: 10 tests passed with
  warnings as errors.
- Generated 121-schema bundle JSON byte digest:
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`
  across 15,506,740 bytes.
- Checked-in `schemas/orbital_dynamics.schema_bundle.v1.json` digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against selection commit `c68fa161`: the top-level contract now
  calls `CandidateDiffContracts.validate_optional_report/3` with unchanged
  `[]`, `"$"`, and `artifact` arguments; the callback bag captures the same
  owner `/3` under the unchanged key and between the same link-capacity and
  candidate-rejection neighbors; the facade wrapper is absent.
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
- Independent bounded review against selection commit `c68fa161` was clean:
  exact direct-call arguments and callback position, unchanged CandidateDiff
  owner, 10 focused and 182 complete tests, generated and checked bundle
  digests, all 122 generated export files byte-matched, strict compile, xref,
  formatting, sizes, ledger, and diff hygiene matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
Both facade uses now reference the established CandidateDiff optional-report
owner directly and the pure wrapper is gone. `schema.ex` decreased from 8,000
to 7,993 lines.

Last completed slice:
Optional CandidateDiff report wrapper cleanup published as `4d52f1c4`: both
facade uses now point directly at the established owner, `schema.ex` shrank
from 8,000 to 7,993 lines, 10 focused and 182 complete schema/export tests
passed, all 122 generated schema files byte-matched, and bounded review was
clean.

Next candidate:
Map the adjacent single-call `validate_refreshed_window/3` facade delegate.
Its established `CandidateRefreshWindowContracts.validate_refreshed_window/3`
owner is unchanged and the standalone `refreshed_window.v1` pipe is its only
caller; capture pipeline order and schema-byte baselines before replacing it.

Blocked:
No.
