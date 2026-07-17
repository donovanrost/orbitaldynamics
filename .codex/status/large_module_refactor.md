# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation safety-case evidence test-family extraction.

Status:
Selected; implementation not started.

Selected slice:
Move the eight contiguous validation safety-case evidence tests into a focused
module, preserving row-derived model acceptance, readiness, quality-gate,
schema-validation, nested fixture, review, and import-container semantics.

Why this slice:
After the orbital split, `validation_test.exs` is 19,074 lines. Tests 249-1,178
form an eight-test, ~930-line safety-case family with inline fixtures and no
private-helper dependency; the following test begins dependency-policy behavior.

Public facade to preserve:
`OrbitalDynamics.Validation.safety_case_summary/1,2`,
`OrbitalDynamics.Schema.validate_artifact/2`, operator-review and Cadence import
handoffs, exact paths/messages/count derivations, and deterministic summaries.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/safety_case_evidence_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted safety-case test module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All eight tests move mechanically with order, inline fixtures, assertion strength,
and edge coverage unchanged; focused and parent files pass, names remain unique,
and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Validation orbital-reference fixture extraction published as `2ce12b05`: the
parent fell from 19,372 to 19,074 lines; six tests moved into a 121-line focused
module and their observations into a shared 212-line support owner. The focused
module passed 6/6, the parent 175/175, and the combined run 181/181.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.
