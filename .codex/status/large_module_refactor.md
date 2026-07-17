# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh objective/constraint replay test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous candidate-refresh objective-gap and constraint replay
tests into a focused module with one shared planning-feedback builder owner.

Why this slice:
After the timeline replay split, `validation_test.exs` is 7,108 lines. Tests
1,627-1,796 form a coherent planning-feedback replay family and end before
link-capacity replay. Their six helpers form a complete closure and only depend
on the shared replay `result_set/1` owner.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
objective-gap and constraint replay schema checks, stale planning-feedback
coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_planning_feedback_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_planning_feedback_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh planning-feedback replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation candidate-refresh timeline replay extraction published as
`dd568d9c`: the focused module passed 4/4, the parent passed 55/55, and all
thirty Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, exact-source and dependency-closure checks, and
bounded review were clean.

Next candidate:
Map the candidate-refresh link-capacity and resource-filter replay families
following the planning-feedback pair. Preserve source-report family boundaries
and reuse the shared replay result-set builder; stop before contact-filter replay.

Blocked:
No.
