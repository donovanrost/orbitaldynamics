# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation operational planning fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the three contiguous command-window report, constraint report, and
operational-timeline report fixture tests into a focused module with one shared
builder owner.

Why this slice:
After the timeline handoff split, `validation_test.exs` is 13,343 lines. Tests
6,627-6,962 form a coherent operational planning report family and end before
contact-allocation fixtures. Their six observation/raw builders and one
generated-artifact builder form one closure; only observation builders remain
needed by the deterministic aggregate. The preceding resource-pressure test is
excluded because its cross-artifact raw fixtures retain parent consumers.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact command-window,
constraint, operational-timeline, stale-data coverage, and deterministic
reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/operational_planning_fixture_test.exs`
- `test/support/validation/operational_planning_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted operational planning fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation timeline handoff fixture extraction published as `92467b94`: the
focused module passed 3/3, the parent passed 108/108, and all fourteen
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent resource-pressure, command-window, constraint, and
operational-timeline fixture cluster in the 13,343-line parent. Select only a
coherent multi-test boundary and move shared builders to one support owner
rather than copying them.

Blocked:
No.
