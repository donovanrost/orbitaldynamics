# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation core registry/policy test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

Selected slice:
Move the ten leading validation registry, public-facade, model-acceptance,
dependency, result-set selection, tolerance, adapter-boundary, and backend-tier
tests into a focused core policy module.

Why this slice:
After the safety-case split, `validation_test.exs` is 18,144 lines. Tests 33-463
form the complete remaining leading core-policy section and end before curated
artifact fixtures. The small `result_set/1` helper has later consumers, so its
exact body will remain in the parent and be copied locally.

Public facade to preserve:
Public `OrbitalDynamics` validation facades, `OrbitalDynamics.Validation`
registry/policy/report functions, schema validation, result-set record selection,
adapter boundaries, and exact deterministic policies.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/core_policy_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted core-policy test module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All ten tests move mechanically with order and assertion strength unchanged; the
local `result_set/1` copy stays exact, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Exactly ten contiguous core registry/policy tests moved byte-for-byte into
`OrbitalDynamics.Validation.CorePolicyTest`; order, assertions, public-facade
coverage, result-set selection, and policy semantics are unchanged. Its local
`result_set/1` helper is an exact copy retained in the parent for later fixture
consumers. The parent fell from 18,144 to 17,710 lines and lost four orphan
aliases; the focused module is 449 lines, a 15-line total increase for explicit
module/alias/helper boundaries. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a mechanical test-only extraction.

Last completed slice:
Validation core registry/policy extraction, publication pending: the focused
module passed 10/10, the parent passed 157/157, and all four Validation modules
preserved the 181-test aggregate with no duplicate names. Format, diff hygiene,
helper-copy verification, and bounded review were clean.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.
