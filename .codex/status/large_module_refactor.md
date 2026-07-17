# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Provider-capacity-pack fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`contact_allocation_provider_reservation_request_summary.v1` and
`contact_allocation_report.reduced_capacity_pack` from their contiguous facade
range into a new
`Validation.ReferenceFixtures.ProviderCapacityPackArtifacts` leaf. Preserve
the following contact-filter report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 4,949 lines. The
two fixtures occupy 230 facade lines and exactly own
`provider_capacity_pack_fixture_test.exs`.

Current coupling/problem:
Provider reservation-request and reduced-capacity packing expectations form a
small, contiguous test-owned family but remain embedded in the general
registry. Moving both together preserves their provider-capacity responsibility
without absorbing the following contention/filter family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ProviderCapacityPackArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/provider_capacity_pack_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused provider-capacity-pack and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two provider-capacity-pack fixtures exist only in the new cohesive leaf,
all 35 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
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
- Selected two-fixture map: deterministic digest
  `d6e0eb517519cbe6cb0b2a0770231ca48709e9b7c1798b85a55ec235c0e88b5a`.
- Exact 193-entry remainder: deterministic digest
  `b512254e64e877a6cf42b2933a733de83eff74b903369c74b839d0eb887ae458`.
- Contiguous source boundary confirmed at facade lines 216-445, followed by
  `contact_filter_report.v1`, with no facade helper-attribute dependency in the
  selected literals.
- Focused provider-capacity-pack/facade selection baseline: 14 tests passed.

Behavior/schema changes:
None.

Outcome:
No provider-capacity-pack implementation has started.

Last completed slice:
Contact-allocation extraction published as `bbdecf49`: the exact five-fixture
family moved into a new 487-line leaf, the facade shrank from 5,426 to 4,949
lines, the 195-entry map and all deterministic digests stayed exact, 17 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the provider-capacity-pack extraction described above, capture the exact
combined map and contiguous source boundary, then move the complete test-owned
family together.

Blocked:
No.
