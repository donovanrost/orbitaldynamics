# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation fixture mapping.

Status:
Publishing.

Selected slice:
Move
`contact_allocation_report.v1`,
`contact_allocation_reservation_conflict_summary.v1`,
`contact_allocation_station_pressure_summary.v1`,
`contact_allocation_capacity_pack_summary.v1`, and
`contact_allocation_summary.v1` from their contiguous facade range into a new
`Validation.ReferenceFixtures.ContactAllocationArtifacts` leaf. Preserve the
following provider-reservation request summary exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 5,426 lines. The
five fixtures occupy 479 facade lines and exactly own
`contact_allocation_fixture_test.exs`.

Current coupling/problem:
Allocation, reservation-conflict, station-pressure, capacity-pack, and summary
expectations form one contiguous facade family but remain embedded in the
general registry. Moving exactly the focused-test family keeps the following
provider-capacity-pack responsibility separate.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ContactAllocationArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/contact_allocation_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused contact-allocation and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The five contact-allocation fixtures exist only in the new cohesive leaf, all
34 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected five-fixture map: deterministic digest
  `2f611fbc83c9e69f1f23ab0cbf8d7b96c21ab04af96353920b39d485de6e5935`.
- Exact 190-entry remainder: deterministic digest
  `812a662f89b83e08348b88a9e208a4c0d44a4d0271ecb040fe310245f7f94843`.
- Contiguous source boundary confirmed at facade lines 215-693, followed by
  `contact_allocation_provider_reservation_request_summary.v1`, with no facade
  helper-attribute dependency in the selected literals.
- Normalized-AST proof against selection commit `31f3948a`: all five moved
  literals, the following provider-reservation summary, and the complete
  70-entry facade remainder are exact; the new leaf owns only the intended five
  keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  five-fixture digest, and exact 190-entry remainder digest all match their
  selection baselines.
- Source partition proof: 34 maps total 195 entries, the new leaf owns five, the
  facade owns 70, all 561 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused contact-allocation/facade validation: 17 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `31f3948a` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
The exact five-fixture contact-allocation family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 5,426 to 4,949 lines;
the new leaf is 487 lines and owns exactly five fixtures.

Last completed slice:
Timeline-transition extraction published as `f1f8f552`: the exact four-fixture
family moved into a new 411-line leaf, the facade shrank from 5,827 to 5,426
lines, the 195-entry map and all deterministic digests stayed exact, 16 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the contact-allocation extraction described above, capture the exact
combined map and contiguous source boundary, then move the complete test-owned
family together.

Blocked:
No.
