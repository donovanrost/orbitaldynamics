# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation candidate-refresh contact replay test-family extraction.

Status:
Ready to publish.

Selected slice:
Move the two contiguous candidate-refresh contact-contention and contact-intent
replay tests into a focused module with one shared replay builder owner.

Why this slice:
After the candidate-refresh base split, `validation_test.exs` is 8,367 lines.
Tests 1,608-1,777 form a coherent contact replay family and end before
resource-projection replay. Their six family-specific helpers plus the generic
`result_set/1` builder form the ownership boundary; the parent retains
`result_set/1` and two observation imports for remaining replay builders and the
deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact candidate-refresh
contact-contention/contact-intent replay schema checks, stale replay coverage,
and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/candidate_refresh_contact_replay_fixture_test.exs`
- `test/support/validation/candidate_refresh_contact_replay_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted candidate-refresh contact replay fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Two byte-identical candidate-refresh contact replay tests moved into a 183-line
focused module. Their six family helpers and the generic `result_set/1` builder
now have one 151-line shared support owner; the parent imports only
`result_set/1` and the two aggregate observation builders, and no longer owns
`ResultSet` or the raw contention fixture dependency. The parent fell from
8,367 to 8,057 lines. Total test/support/loader LOC grew by 25 lines for
explicit ownership without helper duplication. All 181 Validation test names
remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation candidate-refresh base fixture extraction published as `a37bc4ae`:
the focused module passed 2/2, the parent passed 64/64, and all twenty-seven
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, exact-source and dependency-closure checks, and bounded
review were clean.

Next candidate:
Map the candidate-refresh resource-projection, quality-gate, and operational
readiness replay sequence following the contact pair. Preserve report-family
boundaries and reuse the shared replay result-set builder; stop before timeline
activity replay.

Blocked:
No.
