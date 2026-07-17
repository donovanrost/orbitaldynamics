# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle authority fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move only
`policy_bundle.operator_review_queue_authority` and
`policy_bundle.command_contact_authority` into the existing
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`policy_bundle.conservative_ops`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,216 lines. The
next two contiguous fixtures are the operator-review and command/contact
authority variants, totaling 148 facade lines. Both have dedicated assertions
in `policy_bundle_fixture_test.exs`.

Current coupling/problem:
Two authority-focused policy-bundle expectations remain in the general facade
even though the policy-bundle family now has a dedicated leaf. Moving this
pair extends that ownership without conflating the later operational-policy or
domain-authority groups.

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
The two selected authority fixtures exist only in the cohesive policy leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `conservative_ops` and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `bdb6bbadc2eac861823a5789fd1e7c924629f832db664b88e7a0642e2d65f71b`.
- Exact 193-entry remainder: deterministic digest
  `a6a77486ed81152ecf20ff48d07a6e00161d093c7cbd9dc7ca2c062f206239ed`.
- Existing two-fixture policy leaf: deterministic digest
  `922b0b6e144d06303a9d45cc972d40754be0c36989f499e305fbf13a10fd3a2a`.
- Source boundary confirmed at facade lines 154-301, with
  `policy_bundle.conservative_ops` beginning at line 302 and no facade
  helper-attribute dependency in the selected literals.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No authority-fixture implementation has started.

Last completed slice:
Base policy-bundle fixture extraction published as `c66cedc3`: the two exact
base/ground-network fixtures moved into a new 147-line leaf, the facade shrank
from 9,353 to 9,216 lines, the 195-entry map and all deterministic digests
stayed exact, 18 focused and 181 full validation tests passed, and bounded
review was clean.

Next candidate:
Select the two-fixture authority extraction described above, capture the exact
baseline and source partition, then stop before `policy_bundle.conservative_ops`.

Blocked:
No.
