# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy-evidence fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
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
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected four-fixture map: deterministic digest
  `8790ec2500573e3e85950af1f3283e67662c16ffbc09c4aae47cf0033cf70a97`.
- Exact 191-entry remainder: deterministic digest
  `9450be157ec65f56cfdbca6f1c678e0b56074a28b0d61136bb31c3bffb4b53c6`.
- Source boundary confirmed at facade lines 160-308, with
  `timeline_diff_report.v1` beginning at line 309 and no facade
  helper-attribute dependency in the selected literals.
- Selection only; implementation verification pending.

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
