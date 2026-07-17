# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-allocation fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected four-fixture map: deterministic digest
  `c82115f7a3875c01d2dcbaa3ecdc076a3a0f35a55ca9f2683136a138f6e1b3ac`.
- Exact 191-entry remainder: deterministic digest
  `fb9eea036860f5b5b25bfeb52834852c9bc65bde6475bf112eb9647eb2b37228`.
- Contiguous source boundary confirmed at facade lines 214-616, followed by
  `contact_allocation_report.v1`, with no facade helper-attribute dependency in
  the selected literals.
- Normalized-AST proof against selection commit `2ce24b78`: all four moved
  literals, the following contact-allocation report, and the complete 75-entry
  facade remainder are exact; the new leaf owns only the intended four keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  four-fixture digest, and exact 191-entry remainder digest all match their
  selection baselines.
- Source partition proof: 33 maps total 195 entries, the new leaf owns four, the
  facade owns 75, all 528 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused timeline-transition/facade validation: 16 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `2ce24b78` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

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
