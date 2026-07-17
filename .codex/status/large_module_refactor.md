# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-bundle organization-adapter ownership cleanup.

Status:
Publishing.

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
- None for this bounded slice.

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
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  organization-adapter digest, prior eleven-fixture leaf digest, and exact
  194-entry remainder digest all match their selection baselines. The complete
  twelve-fixture policy leaf digest is
  `47681942905bc4d921a89f40ef5f62b2f8c77ac088efecb801c0cbeba86b7c6f`.
- Source partition proof: 21 maps total 195 entries, the policy leaf owns
  twelve, the facade owns 120, and all 210 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused policy-bundle/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the organization adapter
  moved unchanged, the prior eleven leaf fixtures and complete facade remainder
  are normalized-AST exact, the leaf owns all and only twelve global
  policy-bundle keys, all 21 maps are unique and pairwise disjoint, all six
  digests and facade edge behaviors are unchanged, dependencies remain one-way,
  and it reproduced 18 focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
The final policy-bundle fixture now lives in the existing leaf behind the
unchanged facade. The facade shrank from 8,668 to 8,620 lines; the leaf grew
from eleven to twelve fixtures and from 695 to 743 lines, completing
policy-bundle family ownership.

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
