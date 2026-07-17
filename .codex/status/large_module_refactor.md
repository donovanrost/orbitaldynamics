# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation orbital-reference fixture test-family extraction.

Status:
Implemented, verified, reviewed, and ready to publish.

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
- `test/support/validation/orbital_reference_fixtures.ex`
- `test/test_helper.exs`
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
Six byte-identical orbital-reference tests moved into a 121-line focused module.
Their six observation builders now have one shared 212-line test-support owner,
used by both the focused tests and retained deterministic/tolerance consumers;
`access_state/2` remains private. Review caught the initially incomplete helper
closure before publication, prompting this single-owner design. The parent fell
from 19,372 to 19,074 lines and lost 13 orphan aliases. Total test/support LOC
grew by 37 lines for explicit module/import boundaries without helper duplication.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation orbital-reference fixture extraction, publication pending: the
focused module passed 6/6, the parent passed 175/175, and their combined run
passed 181/181 with zero duplicate names. Format, diff hygiene, dependency-
closure checks, and bounded re-review were clean.

Next candidate:
After this slice, refresh the remaining validation fixture families and prefer
another multi-test seam with an explicit helper dependency closure.

Blocked:
No.
