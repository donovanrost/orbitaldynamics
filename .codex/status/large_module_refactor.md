# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Link-capacity fixture mapping.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
`link_capacity_summary.v1` and `link_capacity_report.v1` from their two facade
ranges into a new `Validation.ReferenceFixtures.LinkCapacityArtifacts` leaf.
Stop before `refreshed_window.v1` and `relay_data_path_summary.v1`,
respectively.

Why this slice:
`ReferenceFixtures` remains the largest production module at 8,073 lines. The
two link-capacity fixtures total 171 lines and are jointly owned by dedicated
assertions in `link_capacity_fixture_test.exs`.

Current coupling/problem:
The capacity report and its summary are separated by unrelated fixture families
inside the general facade despite sharing one contract responsibility and
focused test module. Extracting both avoids a one-fixture leaf and reunifies
their ownership.

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
The report/summary fixtures exist only in the new cohesive leaf, all 25 fixture
maps remain disjoint, `all/0` and `fetch/1` return exactly the same 195-entry
map and deterministic term bytes, both following boundary fixtures and the
complete facade remainder stay exact, focused and full validation tests pass,
and bounded review finds no blocker.

Verification gaps:
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected two-fixture map: deterministic digest
  `37ba67b3227aaa447d940e862eb89ddbfeef9a71a960735218ad65b53f0f3e6f`.
- Exact 193-entry remainder: deterministic digest
  `b80744cdcd1814ada66ef0f1a902d18d668c28064a924cdca1f14bdc394f8f3d`.
- Source boundary confirmed at facade lines 156-283, with
  `link_capacity_summary.v1` beginning at line 284 and no facade
  helper-attribute dependency in the selected literals.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  two-fixture digest, and exact 193-entry remainder digest all match their
  selection baselines.
- Source partition proof: 24 maps total 195 entries, the new leaf owns two, the
  facade owns 111, and all 276 pairwise intersections are empty.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused contact-window/facade validation: 16 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review: CLEAN. It confirmed both contact-intent fixtures
  moved unchanged, the link-capacity summary and complete facade remainder are
  normalized-AST exact, the new leaf owns only its two intended keys, all 24
  maps are unique and pairwise disjoint, all digests and facade edge behaviors
  are unchanged, dependencies remain one-way, link-capacity ownership remains
  distinct, and it reproduced 16 focused and 181 full validation tests.

Behavior/schema changes:
None.

Outcome:
No link-capacity implementation has started.

Last completed slice:
Contact-intent extraction published as `2a189f06`: the exact intent/summary
pair moved into a new 136-line leaf, the facade shrank from 8,199 to 8,073
lines, the 195-entry map and all deterministic digests stayed exact, 16 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the link-capacity extraction described above, capture the exact baseline
and both source boundaries, then move the two test-owned fixtures together.

Blocked:
No.
