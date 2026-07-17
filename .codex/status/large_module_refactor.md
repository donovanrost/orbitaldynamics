# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-intent fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
`contact_intent.v1` and `contact_intent_summary.v1` into a new
`Validation.ReferenceFixtures.ContactIntentArtifacts` leaf. Stop before
`link_capacity_summary.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,199 lines. The
next two contiguous fixtures form the 128-line contact-intent pair and have
dedicated assertions in `contact_window_fixture_test.exs`.

Current coupling/problem:
Contact intent and its summary remain embedded in the general facade between
activity artifacts and link-capacity evidence. Their shared contact-intent
responsibility and focused tests justify a dedicated leaf.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ContactIntentArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/contact_intent_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused contact-window and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The two contact-intent fixtures exist only in the new cohesive leaf, all 24
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, `link_capacity_summary.v1` and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected three-fixture map: deterministic digest
  `1af1f0f404a98d28b03dc3a04aada31c961f858d6935f3e63d47040737baace1`.
- Exact 192-entry remainder: deterministic digest
  `24c35264b2280806309dba8d5df496165c16598524ae2166fd1c253df8fc98ce`.
- Existing two-fixture activity leaf: deterministic digest
  `0495cd340d8bd8260c35eddc146e74669a8cddb34800983a92787db202338760`.
- Source boundary confirmed at facade lines 156-314, with
  `contact_intent.v1` beginning at line 315 and no facade helper-attribute
  dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  three-fixture digest, prior two-fixture activity-leaf digest, and exact
  192-entry remainder digest all match their selection baselines. The resulting
  five-fixture leaf digest is
  `ced869955c4b50090dfc2354f8728d326385d035cf8713c77d6e57d2f977aa18`.
- Source partition proof: 23 maps total 195 entries, the activity leaf owns
  five, the facade owns 113, and all 253 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused activity-artifact/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed the outcome/change trio moved
  unchanged, the prior two activity definitions and complete facade remainder
  are normalized-AST exact, the leaf owns only its five intended activity keys,
  all 23 maps are unique and pairwise disjoint, all six digests and facade edge
  behaviors are unchanged, dependencies remain one-way, subsystem/contact
  fixtures remain distinct, and it reproduced 18 focused and 181 full
  validation tests.

Behavior/schema changes:
None.

Outcome:
No contact-intent implementation has started.

Last completed slice:
Activity-family ownership completed as `c694c2ac`: the exact
realized/delta/candidate trio moved into the existing five-fixture leaf, the
facade shrank from 8,358 to 8,199 lines, the 195-entry map and all deterministic
digests stayed exact, 18 focused and 181 full validation tests passed, and
bounded review was clean.

Next candidate:
Select the contact-intent extraction described above, capture the exact
baseline and source partition, then stop before `link_capacity_summary.v1`.

Blocked:
No.
