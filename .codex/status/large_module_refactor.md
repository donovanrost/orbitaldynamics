# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation fixture mapping.

Status:
Ready for implementation.

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
- Implementation and post-move verification pending.

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
- Focused contact-allocation/facade selection baseline: 17 tests passed.

Behavior/schema changes:
None.

Outcome:
No contact-allocation implementation has started.

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
