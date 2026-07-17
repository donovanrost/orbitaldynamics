# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation orbital-reference fixture test-family extraction.

Status:
Selected; implementation not started.

Selected slice:
Move the six foundational two-body, J2, access-window, eclipse,
target-visibility, and ground-track reference-fixture tests into a focused
orbital-reference module with their cohesive observation helpers.

Why this slice:
Live inventory shows `validation_test.exs` at 19,372 lines. Tests 1,400-1,505
form one foundational orbital-reference family. Five observation helpers plus
`access_state/2` are exclusive; the two-body helper has two later consumers and
will remain in the parent with an exact local copy in the focused module.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1` and
`verify_reference_fixture/2`, propagator/event-detector behavior, exact report
checks, curated fixture semantics, and deterministic observations.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/orbital_reference_fixture_test.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted orbital-reference test module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All six tests and exclusive helpers move mechanically; the shared two-body helper
copy stays exact, assertion strength and observations remain unchanged, focused
and parent files pass, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Not yet verified.

Last completed slice:
Cadence-import comparison-report test-family extraction published as `47e08bb7`:
two byte-identical tests moved into a 713-line focused module, shrinking the
parent from 15,999 to 15,292 lines. The focused module passed 2/2, the parent
96/96, and the complete 113-test family remained unique and green.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.
