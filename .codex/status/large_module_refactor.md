# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Link-capacity ownership cleanup.

Status:
Ready for next slice selection.

Selected slice:
No implementation selected yet. The next bounded candidate is to move
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
- Next candidate still requires a selection baseline before implementation.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected five-fixture map: deterministic digest
  `ee14e627521262933776cc726d840ec649662ad80004952c75afd38c133ef879`.
- Exact 190-entry remainder: deterministic digest
  `83a23ef655563659f24a8d59eebe3844414fe1bfbb5969fc308cd24b5b19a29b`.
- Contiguous source boundary confirmed at facade lines 217-534, followed by
  `relay_data_path_summary.v1`, with no facade helper-attribute dependency in
  the selected literals.
- Normalized-AST proof against selection commit `f7d531a0`: all five moved
  literals, the following relay-data-path summary, and the complete 63-entry
  facade remainder are exact; the new leaf owns only the intended five keys.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  five-fixture digest, and exact 190-entry remainder digest all match their
  selection baselines.
- Source partition proof: 36 maps total 195 entries, the new leaf owns five, the
  facade owns 63, all 630 pairwise intersections are empty, and the source key
  union exactly matches the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged.
- Focused contact-contention/facade validation: 17 tests passed.
- Full validation family: 181 tests passed.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Independent bounded review against selection commit `f7d531a0` was clean:
  the contiguous source range and complete facade remainder are normalized-AST
  exact, all runtime and partition invariants reproduced, dependency direction
  remains one-way, and focused/full tests and hygiene gates passed.

Behavior/schema changes:
None.

Outcome:
No link-capacity ownership cleanup has started.

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
