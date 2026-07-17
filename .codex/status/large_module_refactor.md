# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Model-acceptance fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move `model_acceptance_report.operational_import` and
`validation_safety_case_summary.v1` from the final contiguous facade range into
a new `Validation.ReferenceFixtures.ModelAcceptanceArtifacts` leaf. Preserve
the preceding provider-counteroffer review fixture and complete facade
remainder exactly.

Why this slice:
`ReferenceFixtures` remains a 1,240-line production module. The two fixtures
occupy 195 facade lines, form the complete final literal range, and exactly own
`model_acceptance_fixture_test.exs`.

Current coupling/problem:
Model acceptance and its validation safety-case handoff form one contiguous,
test-owned workflow but remain embedded in the general registry. Moving both
fixtures preserves the complete responsibility without splitting the larger
station reservation/calendar family.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ModelAcceptanceArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/model_acceptance_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused quality-gate and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
Both model-acceptance fixtures exist only in the new cohesive leaf, all 47
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, the preceding boundary fixture and
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and post-move verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `6156df8e2fa588a5a2ac4cb315acc92f3955df019092b9ff0ae2fe9241f494d4`.
- Exact 193-entry remainder: deterministic digest
  `06b73c281338a65814ef98ee5ddbb5dac42c21a81d1e7c437845be241ee70d8e`.
- Contiguous source boundary confirmed at facade lines 993-1187, immediately
  after `provider_counteroffer_review_summary.v1` and before the literal map
  closes, with no facade helper-attribute dependency in the selected literals.
- Focused model-acceptance/facade selection baseline: 4 tests passed with
  warnings as errors.

Behavior/schema changes:
None.

Outcome:
No model-acceptance implementation has started.

Last completed slice:
Quality-gate extraction published as `287ee9f1`: the exact seven-fixture family
moved into a new 631-line leaf, the facade shrank from 1,861 to 1,240 lines, the
195-entry map and all deterministic digests stayed exact, 20 focused and 181
full validation tests passed, and bounded review was clean.

Next candidate:
Select the model-acceptance extraction described above, preserve the exact
preceding fixture and complete remainder, then move the complete test-owned
pair.

Blocked:
No.
