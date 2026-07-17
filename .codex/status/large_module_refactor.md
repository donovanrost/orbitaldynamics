# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh objective/constraint replay test-family extraction.

Status:
Published as `78a7ecbf`.

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
Two byte-identical candidate-refresh planning-feedback replay tests moved into
a 183-line focused module. Their six helpers now have one 203-line shared
support owner that reuses `result_set/1`; the parent imports only the two
aggregate observation builders. The parent fell from 7,108 to 6,747 lines.
Total test/support/loader LOC grew by 30 lines for explicit ownership without
helper duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-refresh planning-feedback replay extraction published as
`78a7ecbf`: the focused module passed 2/2, the parent passed 53/53, and all
thirty-one Validation modules preserved the 181-test aggregate with no duplicate
names. Format, diff hygiene, exact-source and dependency-closure checks, and
bounded review were clean.

Next candidate:
Map the candidate-refresh link-capacity and resource-filter replay families
following the planning-feedback pair. Preserve source-report family boundaries
and reuse the shared replay result-set builder. Their six helpers form a closed
family; stop before contact-filter replay.

Blocked:
No.
