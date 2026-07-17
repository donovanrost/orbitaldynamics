# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle organization-adapter ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Move the
remaining `policy_bundle.organization_adapter` fixture into the existing
`Validation.ReferenceFixtures.PolicyBundleArtifacts` leaf. Stop before
`planned_activity.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,668 lines. The
48-line organization-adapter fixture is the only policy-bundle expectation
still in the facade and already participates in focused policy-bundle tests.

Current coupling/problem:
One policy-bundle fixture remains separated from the eleven related fixtures in
the dedicated leaf. Moving it completes family ownership without creating a
one-fixture module or touching the following planned-activity family.

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
The organization-adapter fixture exists only in the policy leaf,
all 21 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `planned_activity.v1` and the
complete facade remainder stay exact, the prior eleven leaf fixtures remain
exact, focused and full validation tests pass, and bounded review finds no
blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected organization-adapter map: deterministic digest
  `fed3fb648997d115c74c7eb849051a282520d26f5a7dca489df6d08c5c1652e1`.
- Exact 194-entry remainder: deterministic digest
  `97509859c9320c714fdb42424e5d372774b38c0f41fd02a75729e2aae3d2a732`.
- Existing eleven-fixture policy leaf: deterministic digest
  `ba5aa4182753941be877a6973bc2e5162ef43604e6ecda753d7904a0a9f1769a`.
- Source boundary confirmed at facade lines 154-201, with
  `planned_activity.v1` beginning at line 202 and no facade helper-attribute
  dependency in the selected literal.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No organization-adapter implementation has started.

Last completed slice:
Policy-bundle domain-authority extraction published as `d2752ec5`: the exact
three-fixture group moved into the existing leaf, the facade shrank from 8,860
to 8,668 lines, the leaf grew to eleven fixtures, the 195-entry map and all
deterministic digests stayed exact, 18 focused and 181 full validation tests
passed, and bounded review was clean.

Next candidate:
Select the organization-adapter ownership cleanup described above, capture the
exact baseline and source partition, then stop before `planned_activity.v1`.

Blocked:
No.
