# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Subsystem-model capability fixture mapping.

Status:
Publishing.

Selected slice:
Move
`subsystem_model_capability.battery` and
`subsystem_model_capability.storage` into a new
`Validation.ReferenceFixtures.SubsystemModelCapabilities` leaf. Stop before
`realized_activity.v1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,481 lines. The
next two contiguous fixtures form the 125-line subsystem-capability pair and
are asserted together in `activity_artifact_fixture_test.exs`.

Current coupling/problem:
Battery and storage model capability expectations remain embedded in the
general facade between activity definitions and outcome/change artifacts.
Their shared contract and focused test justify a dedicated capability leaf.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.SubsystemModelCapabilities`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/subsystem_model_capabilities.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused activity-artifact and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The battery/storage capability fixtures exist only in the new cohesive leaf,
all 23 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, `realized_activity.v1` and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- None for this bounded slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `f1c363eb0eb770461ee1bdf8210e8191373c1008cd3693e03b53117204c33c7a`.
- Exact 193-entry remainder: deterministic digest
  `784d669e3dd1281781820939357c3ef7927a257013415ddf47b0607db38c2992`.
- Source boundary confirmed at facade lines 155-279, with
  `realized_activity.v1` beginning at line 280 and no facade helper-attribute
  dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  two-fixture digest, and exact 193-entry remainder digest all match their
  selection baselines.
- Source partition proof: 23 maps total 195 entries, the new leaf owns two, the
  facade owns 116, and all 253 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused activity-artifact/facade validation: 18 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed both subsystem capability
  fixtures moved unchanged, realized activity and the complete facade remainder
  are normalized-AST exact, the new leaf owns only its two intended keys, all
  23 maps are unique and pairwise disjoint, all digests and facade edge
  behaviors are unchanged, dependencies remain one-way, the capability boundary
  remains distinct from activity definitions/outcomes, and it reproduced 18
  focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
The exact battery/storage capability pair now lives in a new cohesive leaf
behind the unchanged facade. The facade shrank from 8,481 to 8,358 lines; the
new leaf is 133 lines and owns exactly two fixtures.

Last completed slice:
Activity-definition extraction published as `f975a5d6`: the exact
planned-activity/template pair moved into a new 149-line leaf, the facade
shrank from 8,620 to 8,481 lines, the 195-entry map and all deterministic
digests stayed exact, 18 focused and 181 full validation tests passed, and
bounded review was clean.

Next candidate:
Select the subsystem-capability extraction described above, capture the exact
baseline and source partition, then stop before `realized_activity.v1`.

Blocked:
No.
