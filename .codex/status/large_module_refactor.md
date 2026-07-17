# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh station-allocation replay fixture extraction.

Status:
Ready for implementation.

Selected slice:
Move the contiguous `station_calendar_replay` and
`contact_allocation_contradiction_replay` fixtures into
`Validation.ReferenceFixtures.CandidateRefreshStationAllocation`. Leave the
following contact-contention replay in the facade and merge the new family
behind unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 11,932 lines.
These two fixtures form one contiguous 205-line station-allocation replay
family and have one
dedicated focused owner in
`validation/candidate_refresh_station_allocation_replay_fixture_test.exs`.

Current coupling/problem:
Two related generated replay fixtures remain embedded in the facade despite
shared station allocation responsibility and test ownership. Neither
references a facade helper attribute, so the pair can move without coupling
the adjacent contact replay family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshStationAllocation`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/candidate_refresh_station_allocation.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused station-allocation replay and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two replay fixtures exist only in the station-allocation family module, all
eight fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly
the same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Candidate-refresh freshness/budget fixture extraction published as `df1f8ef6`:
the two exact replay fixtures moved behind the unchanged facade, their
neighbors and remainder stayed exact, the 195-entry map and deterministic
bytes stayed exact, 181 validation tests passed, and bounded review was clean.

Next candidate:
After this boundary, map the contact-contention/contact-intent pair against
`candidate_refresh_contact_replay_fixture_test.exs` and verify helper-attribute
coupling before selecting.

Blocked:
No.
