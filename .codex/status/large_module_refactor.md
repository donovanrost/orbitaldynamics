# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation core registry/policy test-family extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Validation safety-case evidence extraction published as `f2bce53a`: eight
byte-identical tests moved into a 935-line focused module, shrinking the parent
from 19,074 to 18,144 lines. The focused module passed 8/8, the parent 167/167,
and all three Validation modules preserved the 181-test aggregate.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.
