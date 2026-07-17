# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Link-capacity ownership cleanup.

Status:
Publishing.

Selected slice:
Move
`relay_data_path_summary.v1` from the facade into the existing
`Validation.ReferenceFixtures.LinkCapacityArtifacts` leaf beside
`link_capacity_summary.v1` and `link_capacity_report.v1`. Preserve the
following maneuver-review report exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 4,405 lines. The
98-line relay fixture is the only fixture owned by
`link_capacity_fixture_test.exs` that remains outside the existing
link-capacity leaf.

Current coupling/problem:
Relay data-path expectations remain in the general facade while the matching
link-capacity summary and report already live together. Moving the final member
completes established family ownership without creating another module.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.LinkCapacityArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/link_capacity_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused link-capacity and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All three link-capacity fixtures exist only in the established cohesive leaf,
all 36 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both following boundary fixtures
and the complete facade remainder stay exact, focused and full validation tests
pass, and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected relay fixture map: deterministic digest
  `97e28bc97fe67e55c49ce4bdfdfe23b0dde4f9bc26b7470ab56533fd2f3fac16`.
- Existing two-fixture link-capacity leaf: deterministic digest
  `7817e0c1af0ec3b38d0c9ea5768aa301c34dce167c369342ffd5c38af2ae7c2d`;
  expected combined three-fixture digest
  `4219e88a9ccd588496edd156e2c839c1c1e876159590b2d1eab8348198148a8a`.
- Exact 194-entry remainder: deterministic digest
  `6bd87aeff9ffe9f98af1aab104a646697dbe92b75ca04b19e6011c700988f055`.
- Source boundary confirmed at facade lines 218-315, followed by
  `maneuver_review_report.v1`, with no facade helper-attribute dependency in
  the selected literal.
- Normalized-AST proof against selection commit `6365d042`: the moved relay
  literal, both existing link-capacity literals, the combined three-entry leaf,
  the following maneuver report, and the complete 62-entry facade remainder
  are exact.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected relay
  digest, combined three-fixture leaf digest, and exact 194-entry remainder
  digest all match their selection baselines.
- Source partition proof: 36 maps total 195 entries, the completed
  link-capacity leaf owns three, the facade owns 62, all 630 pairwise
  intersections are empty, and the source key union exactly matches the runtime
  map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused link-capacity/facade validation: 15 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `6365d042` was clean:
  the moved and existing target literals, completed leaf, facade remainder, and
  boundary fixture are normalized-AST exact; all runtime, partition, focused,
  full-test, dependency, and hygiene checks reproduced.

Behavior/schema changes:
None.

Outcome:
The relay-data-path fixture now lives beside the existing link-capacity summary
and report in the established leaf behind the unchanged facade. The facade
shrank from 4,405 to 4,307 lines; the leaf grew from 179 to 277 lines and owns
exactly the three fixtures exercised together.

Last completed slice:
Contact-contention extraction published as `935df70f`: the exact five-fixture
family moved into a new 326-line leaf, the facade shrank from 4,721 to 4,405
lines, the 195-entry map and all deterministic digests stayed exact, 17 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the relay-data-path ownership cleanup described above, capture the exact
fixture and facade remainder baselines, then complete the existing test-owned
family.

Blocked:
No.
