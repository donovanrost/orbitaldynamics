# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-planning fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
`command_window_report.v1`, `constraint_report.v1`, and
`operational_timeline_report.v1` from their two facade ranges into a new
`Validation.ReferenceFixtures.OperationalPlanningArtifacts` leaf. Preserve the
following timeline lifecycle and timeline transition-application fixtures
exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 7,122 lines. The
three fixtures occupy 279 facade lines and exactly own
`operational_planning_fixture_test.exs`.

Current coupling/problem:
Command-window and constraint expectations are adjacent near the facade start,
while the operational-timeline report is separated by timeline lifecycle
families. Moving all three preserves the complete focused-test responsibility
rather than extracting only the convenient adjacent pair.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.OperationalPlanningArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/operational_planning_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused operational-planning and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three operational-planning fixtures exist only in the new cohesive leaf,
all 30 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected three-fixture map: deterministic digest
  `8e44976106d5c32da69a6f017448fa9a635e069f348b82a5880548ee0039631e`.
- Exact 192-entry remainder: deterministic digest
  `ca8dadbc94fd2f07030dac7ba394ed9dcd089d42eebf60f81c0b0fec7f9c633e`.
- Source boundaries confirmed at facade lines 161-373 and 2127-2230, followed
  by the resource-handoff manifest and contact-allocation report, respectively,
  with no facade helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  three-fixture digest, and exact 192-entry remainder digest all match their
  selection baselines.
- Source partition proof: 29 maps total 195 entries, the new leaf owns three,
  the facade owns 94, and all 406 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused timeline-handoff/facade validation: 15 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `46717eeb` was clean:
  both source ranges and the complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
No operational-planning implementation has started.

Last completed slice:
Timeline-handoff extraction published as `09fcb24c`: the exact three-fixture
family moved into a new 325-line leaf, the facade shrank from 7,437 to 7,122
lines, the 195-entry map and all deterministic digests stayed exact, 15 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the operational-planning extraction described above, capture the exact
combined map and both source-range boundaries, then move the complete
test-owned family together.

Blocked:
No.
