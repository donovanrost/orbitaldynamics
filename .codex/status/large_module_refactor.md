# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Activity outcome/change fixture mapping.

Status:
Ready for implementation.

Selected slice:
Move
`realized_activity.v1`, `plan_delta.v1`, and `candidate_activity.v1` into the
existing `Validation.ReferenceFixtures.ActivityArtifacts` leaf. Stop before
`contact_intent.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,358 lines. The
next three contiguous fixtures form a 159-line activity outcome/change group,
each with dedicated assertions in `activity_artifact_fixture_test.exs`.

Current coupling/problem:
Realized activity, plan delta, and candidate activity remain in the facade even
though activity definitions now have a dedicated leaf. Appending this trio
completes local activity-artifact ownership while keeping subsystem
capabilities separate.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ActivityArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/activity_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused activity-artifact and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three outcome/change fixtures exist only in the cohesive activity leaf, all
23 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, `contact_intent.v1` and the complete
facade remainder stay exact, the prior two activity fixtures remain exact,
focused and full validation tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

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
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No activity outcome/change implementation has started.

Last completed slice:
Subsystem-capability extraction published as `3fa1485d`: the exact
battery/storage pair moved into a new 133-line leaf, the facade shrank from
8,481 to 8,358 lines, the 195-entry map and all deterministic digests stayed
exact, 18 focused and 181 full validation tests passed, and bounded review was
clean.

Next candidate:
Select the activity outcome/change extraction described above, capture the
exact baseline and source partition, then stop before `contact_intent.v1`.

Blocked:
No.
