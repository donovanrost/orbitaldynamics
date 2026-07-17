# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station reservation fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move the 12 station calendar, station reservation, reservation hold, and
provider-counteroffer fixtures from the final contiguous facade range into a
new `Validation.ReferenceFixtures.StationReservationArtifacts` leaf. Preserve
the preceding capability catalog fixture and complete facade remainder exactly.

Why this slice:
`ReferenceFixtures` remains a 1,047-line production module. The 12 fixtures
occupy 814 facade lines, form the complete final literal range, and exactly own
`station_reservation_fixture_test.exs`; the capability catalog remains the sole
unrelated facade fixture.

Current coupling/problem:
Station calendar precedence/provider state, reservation review/holds, and
provider counteroffers form one contiguous, test-owned communications workflow
but remain embedded in the general registry. Moving all 12 preserves that
complete responsibility rather than splitting the workflow by artifact name.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.StationReservationArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/station_reservation_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused quality-gate and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All 12 station workflow fixtures exist only in the new cohesive leaf, all 48
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, the preceding capability fixture
and complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and post-move verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected 12-fixture map: deterministic digest
  `98b5b92ece7a6e39cc26b3e0dd18fffcf9bf5dd94140f6762ea4d554211c6af2`.
- Exact 183-entry remainder: deterministic digest
  `da62ba99a75a6efda9a755338db7d489fed68746cead6f07273e1b0e433556d6`.
- Contiguous source boundary confirmed at facade lines 180-993, immediately
  after `capability_catalog.v1` and before the literal map closes. The only
  facade helper-attribute reference belongs to the retained capability fixture;
  the selected literals have no helper-attribute dependency.
- The 12 unique fixture IDs asserted by
  `station_reservation_fixture_test.exs` exactly equal the selected facade keys.
- Focused station-reservation/facade selection baseline: 11 tests passed with
  warnings as errors.

Behavior/schema changes:
None.

Outcome:
No station-reservation implementation has started.

Last completed slice:
Model-acceptance extraction published as `1d61337d`: the exact two-fixture
family moved into a new 203-line leaf, the facade shrank from 1,240 to 1,047
lines, the 195-entry map and all deterministic digests stayed exact, 4 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the station-reservation extraction described above, preserve the exact
preceding capability fixture and complete remainder, then move the complete
test-owned workflow.

Blocked:
No.
