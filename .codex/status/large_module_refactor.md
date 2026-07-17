# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Station reservation fixture extraction handoff.

Status:
Published as `7e53ba2c`.

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
None.

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
- Normalized-AST proof against selection commit `f73ca40b`: all 12 moved
  literals, the preceding capability catalog fixture, and the complete
  one-entry facade remainder are exact; the new leaf owns only the intended
  test-owned keys and the selected family was the final literal range.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  12-fixture digest, and exact 183-entry remainder digest all match their
  selection baselines.
- Source partition proof: 48 maps total 195 entries, the new leaf owns 12, the
  facade owns one, all 1,128 pairwise intersections are empty, and the 195
  unique source keys exactly match the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused station-reservation/facade validation: 11 tests passed with warnings
  as errors.
- Full validation family: 181 tests passed with warnings as errors.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `f73ca40b` was clean:
  exact 12-key test ownership, normalized AST and capability boundary, all four
  deterministic digests, the 48-map disjoint source partition, facade behavior,
  one-way xref dependency, focused 11-test gate, full 181-test gate, sizes,
  formatting, and diff hygiene all matched the recorded evidence.

Behavior/schema changes:
None.

Outcome:
The exact 12-fixture station reservation workflow now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 1,047 to 235 lines;
the new leaf is 822 lines and owns exactly 12 fixtures.

Last completed slice:
Station-reservation extraction published as `7e53ba2c`: the exact 12-fixture
workflow moved into a new 822-line leaf, the facade shrank from 1,047 to 235
lines, the 195-entry map and all deterministic digests stayed exact, 11 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Map the sole remaining `capability_catalog.v1` facade fixture together with its
private candidate-refresh source-report ordering attribute. Confirm the
attribute is used only by that fixture, capture exact selected/remainder
digests, and move the complete public capability-catalog responsibility into a
dedicated leaf rather than mixing it into environment- or subsystem-specific
capability leaves.

Blocked:
No.
