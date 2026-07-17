# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation safety-case evidence test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

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
Exactly eight contiguous safety-case evidence tests moved byte-for-byte into
`OrbitalDynamics.Validation.SafetyCaseEvidenceTest`; order, inline fixtures,
paths/messages, row-derived evidence semantics, and async execution are
unchanged. The parent fell from 19,074 to 18,144 lines and the focused module is
935 lines, a five-line total increase for its explicit module/alias boundary.
All 181 Validation test names remain unique across the parent and two extracted
modules.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Validation safety-case evidence extraction, publication pending: the focused
module passed 8/8 and the parent passed 167/167; together they preserve 175/175,
and all three Validation modules preserve the 181-test aggregate. Format, diff
hygiene, helper-independence checks, and bounded review were clean.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.
