# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planning reference-fixture family extraction.

Status:
Ready for implementation.

Selected slice:
Move the first three remaining fixtures—campaign repair, campaign request lint,
and campaign strategy—into
`Validation.ReferenceFixtures.CampaignPlanning`. Stop before
`fixture.artifact.capability_catalog.v1` and merge the new family behind
unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 12,410 lines.
These three fixtures form one contiguous 265-line campaign planning block and
have focused coverage in campaign-artifact, planning-input, and facade tests.

Current coupling/problem:
Three independent literal fixture values remain embedded in the facade despite
forming one campaign-planning family. The block references no facade helper
attributes and can move without pulling capability or candidate-refresh
fixtures with it.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CampaignPlanning`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/campaign_planning.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused campaign-artifact, planning-input, and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The three fixtures exist only in the campaign-planning family module, all five
fixture maps have disjoint key sets, `all/0` and `fetch/1` return exactly the
same 195-entry map and deterministic term bytes, focused and full validation
tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Campaign artifact reference-fixture extraction published as `1c728168`: the 10
exact campaign plan/result fixtures moved behind the unchanged facade, the
195-entry map and deterministic bytes stayed exact, 181 validation tests
passed, and bounded review was clean.

Next candidate:
After this boundary, remap `capability_catalog` and the candidate-refresh
fixture prefix. Keep any candidate-refresh extraction bounded by a focused
replay/source family rather than moving the entire range.

Blocked:
No.
