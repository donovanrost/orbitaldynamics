# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-evidence fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
`backend_acceptance_policy.v1`, `validation_tolerance_policy.v1`,
`validation_record.v1`, and `validation_check.v1` into a new
`Validation.ReferenceFixtures.PolicyEvidenceArtifacts` leaf. Stop before
`timeline_diff_report.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 7,584 lines. The
four contiguous fixtures form a 149-line policy-evidence family that exactly
owns `policy_evidence_fixture_test.exs`.

Current coupling/problem:
Policy acceptance, tolerance, record, and check expectations remain embedded in
the general facade despite sharing one focused evidence-policy responsibility.
The preceding cleanup removed the unrelated core-run report from their range.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.PolicyEvidenceArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/policy_evidence_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused policy-evidence and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four policy-evidence fixtures exist only in the new cohesive leaf, all 28
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, `timeline_diff_report.v1` and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected validation-reference map: deterministic digest
  `714d1b43e9fff5efe077a1ee3e801993e01c6dc1a3d1102aa62d0c344963f4c0`.
- Exact 194-entry remainder: deterministic digest
  `356261c8e7c41aba9283fb8a69c5962867c66423b8f203f58d0a80afb16a6e2b`.
- Existing four-fixture core-run leaf: deterministic digest
  `2cef307fc4eb09c6c54536f8a0a8cb78c7613ab5295572862a58931f3b5bca6a`.
- Source boundary confirmed at facade lines 275-310, between
  `validation_record.v1` and `validation_check.v1`, with no facade
  helper-attribute dependency in the selected literal.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected report
  digest, prior four-fixture leaf digest, and exact 194-entry remainder digest
  all match their selection baselines. The resulting five-fixture leaf digest
  is `493ba6c6b32d7a3fa8c1a43ec4dcb4d2202ef044033925208bb42918a4c48b88`.
- Source partition proof: 27 maps total 195 entries, the core-run leaf owns
  five, the facade owns 101, and all 351 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused core-run/policy-evidence/facade validation: 21 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the validation-reference
  report moved unchanged, the prior four core-run fixtures, both neighboring
  policy-evidence fixtures, and complete facade remainder are normalized-AST
  exact, the leaf owns only its five intended keys, all 27 maps are unique and
  pairwise disjoint, all six digests and facade edge behaviors are unchanged,
  dependencies remain one-way, the policy-evidence range is now contiguous,
  and it reproduced 21 focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
No policy-evidence implementation has started.

Last completed slice:
Validation-reference ownership cleanup published as `95bc97fe`: the exact
report moved into the existing five-fixture core-run leaf, the facade shrank
from 7,620 to 7,584 lines, the 195-entry map and all deterministic digests
stayed exact, 21 focused and 181 full validation tests passed, and bounded
review was clean.

Next candidate:
Select the policy-evidence extraction described above, capture the exact
baseline and source boundary, then stop before `timeline_diff_report.v1`.

Blocked:
No.
