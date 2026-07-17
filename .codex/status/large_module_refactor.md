# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Provider-capacity-pack fixture mapping.

Status:
Publishing.

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
- None for this slice.

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
- Normalized-AST proof against selection commit `ae0708d6`: both moved literals,
  the following contact-filter report, and the complete 68-entry facade
  remainder are exact; the new leaf owns only the intended two keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  two-fixture digest, and exact 193-entry remainder digest all match their
  selection baselines.
- Source partition proof: 35 maps total 195 entries, the new leaf owns two, the
  facade owns 68, all 595 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused provider-capacity-pack/facade validation: 14 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `ae0708d6` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
The exact two-fixture provider-capacity-pack family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 4,949 to 4,721 lines;
the new leaf is 238 lines and owns exactly two fixtures.

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
