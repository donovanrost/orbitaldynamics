# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle fixture family mapping.

Status:
Ready for implementation.

Selected slice:
Move only
`policy_bundle.v1` and `policy_bundle.ground_network_allocation` into a new
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`policy_bundle.operator_review_queue_authority`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,353 lines. The
next two contiguous fixtures are the base policy bundle and its foundational
ground-network allocation specialization, totaling 139 facade lines. Both have
dedicated assertions in `policy_bundle_fixture_test.exs`.

Current coupling/problem:
Policy-bundle artifact expectations remain embedded in the general facade even
though they form a large, cohesive, independently tested family. Moving only
the first two establishes the family leaf without conflating the later
authority and operational-policy subfamilies.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.PolicyBundleArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/policy_bundle_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused policy-bundle and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two selected policy-bundle fixtures exist only in the new cohesive leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, the operator-review fixture
and complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `922b0b6e144d06303a9d45cc972d40754be0c36989f499e305fbf13a10fd3a2a`.
- Exact 193-entry remainder: deterministic digest
  `42ae1315da283c6e56026138ee125a6b55a3a13f469323ac41c0dcf69ca6de89`.
- Source boundary confirmed at facade lines 153-291, with
  `policy_bundle.operator_review_queue_authority` beginning at line 292 and no
  facade helper-attribute dependency in the selected literals.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
Selection recorded; no policy-bundle implementation has started.

Last completed slice:
Proposed-contact ownership cleanup published as `ba7a7779`: the exact fixture
moved into the existing candidate-strategy leaf, the facade shrank from 9,397
to 9,353 lines, the 195-entry map and deterministic bytes stayed exact, 18
focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the two-fixture base/ground-network policy-bundle extraction described
above, capture the exact baseline and source partition, then stop before the
operator-review authority fixture.

Blocked:
No.
