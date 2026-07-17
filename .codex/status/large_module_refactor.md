# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign artifact reference-fixture family extraction.

Status:
Completed and published as `1c728168`.

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
- None for this bounded slice.

Tests run:
- Exact post-split proof matched the 195-entry selection baseline,
  deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Source-boundary proof found 10 campaign, 3 accepted-state, 6 orbital, and
  176 facade keys with no duplicate anchors; facade `fetch/1` matched all 10
  moved values.
- Strict test compile passed with warnings as errors.
- Focused campaign-artifact, core-policy, and facade validation tests: 17
  passed.
- Full validation test family: 181 passed.
- Format, tracked/untracked diff hygiene, and xref caller checks passed.
- Bounded read-only review was clean: the exact first 10 normalized AST values
  moved, the remaining facade stayed exact, all four key sets are pairwise
  disjoint, the four-way union equals `77ead96a`, fetch edge behavior matches,
  and compile dependencies are one-way.

Behavior/schema changes:
None.

Outcome:
The 10 campaign plan/result fixtures now live in
`Validation.ReferenceFixtures.CampaignArtifacts`; the facade merges that
family with the accepted-state and orbital families plus 176 remaining
fixtures. The facade fell from 13,008 to 12,410 lines, while the extracted
family is 608 lines.

Last completed slice:
Campaign artifact reference-fixture extraction published as `1c728168`: the 10
exact campaign plan/result fixtures moved behind the unchanged facade, the
195-entry map and deterministic bytes stayed exact, 181 validation tests
passed, and bounded review was clean.

Next candidate:
Extract the next three contiguous campaign planning fixtures—repair, request
lint, and strategy—into one family. The 265-line block has no helper-attribute
coupling, is covered by campaign-artifact, planning-input, and facade tests,
and stops before `capability_catalog`; re-baseline before selecting.

Blocked:
No.
