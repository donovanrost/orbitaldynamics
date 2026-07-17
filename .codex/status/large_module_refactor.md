# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign artifact reference-fixture family extraction.

Status:
Ready for implementation.

Selected slice:
Move the first remaining 10-fixture campaign artifact run—one campaign plan and
nine result-artifact variants—into
`Validation.ReferenceFixtures.CampaignArtifacts`. Stop before
`fixture.artifact.campaign_repair.leo_constellation_v2` and merge the new family
behind unchanged `ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 13,008 lines.
These fixtures form one contiguous 600-line campaign output block, share
campaign/result-artifact responsibility, and have dedicated high-signal
coverage in `validation/campaign_artifact_fixture_test.exs`.

Current coupling/problem:
Ten independent literal fixture values remain embedded in the facade even
though they form one tested campaign artifact family. The block references no
facade helper attributes, so it can move mechanically without pulling
campaign-repair, strategy, or candidate-refresh fixtures with it.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CampaignArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/campaign_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused campaign-artifact fixture and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The 10 fixtures exist only in the campaign-artifacts family module, all four
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
Accepted-planning-state reference-fixture extraction published as `8fffd57d`:
the three exact fixtures moved behind the unchanged facade, the 195-entry map
and deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, remap the campaign repair/strategy neighbors and their
focused assertions before choosing whether they form one bounded family; do
not cross into the large candidate-refresh fixture range.

Blocked:
No.
