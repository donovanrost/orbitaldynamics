# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign planning reference-fixture family extraction.

Status:
Completed and published as `fde8c3ac`.

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
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 3 campaign-planning, 10 campaign-artifact, 3
  accepted-state, 6 orbital, and 173 facade keys with no duplicate anchors;
  facade `fetch/1` matched all three moved values.
- Strict test compile passed with warnings as errors.
- Focused campaign-artifact, planning-input, core-policy, and facade validation
  tests: 20 passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: the exact first three normalized AST
  values moved, the remaining facade stayed exact, all five maps are pairwise
  disjoint, their union equals `03ca698a`, fetch edge behavior matches, and
  compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The three campaign repair/lint/strategy fixtures now live in
`Validation.ReferenceFixtures.CampaignPlanning`; the facade merges that family
with four existing fixture maps plus 173 remaining fixtures. The facade fell
from 12,410 to 12,147 lines, while the extracted family is 273 lines.

Last completed slice:
Campaign planning reference-fixture extraction published as `fde8c3ac`: the
three exact repair/lint/strategy fixtures moved behind the unchanged facade,
the 195-entry map and deterministic bytes stayed exact, 181 validation tests
passed, and bounded review was clean.

Next candidate:
Extract the two candidate-refresh base fixtures (`candidate_refresh.v1` and
`resource_provenance_v1`) into one family. They are noncontiguous but share one
contract and dedicated `candidate_refresh_base_fixture_test.exs` ownership,
reference no facade helper attributes, and can move without touching replay
families; re-baseline before selecting.

Blocked:
No.
