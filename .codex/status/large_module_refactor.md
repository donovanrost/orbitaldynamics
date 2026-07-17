# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Contact-contention fixture mapping.

Status:
Publishing.

Selected slice:
Move
`contact_filter_report.v1`, `contact_contention_report.v1`,
`contact_contention_report.cross_station_spacecraft`,
`contact_contention_resolution_report.v1`, and
`contact_contention_resolution_summary.v1` from their contiguous facade range
into a new `Validation.ReferenceFixtures.ContactContentionArtifacts` leaf.
Preserve the following relay-data-path summary exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 4,721 lines. The
five fixtures occupy 318 facade lines and exactly own
`contact_contention_fixture_test.exs`.

Current coupling/problem:
Contact filtering, contention detection, cross-station contention, and
resolution expectations form one contiguous test-owned family but remain
embedded in the general registry. Moving all five preserves the complete
contention workflow without absorbing relay-capacity behavior.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.ContactContentionArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/contact_contention_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused contact-contention and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The five contact-contention fixtures exist only in the new cohesive leaf, all
36 fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
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
The exact five-fixture contact-contention family now lives in a new cohesive
leaf behind the unchanged facade. The facade shrank from 4,721 to 4,405 lines;
the new leaf is 326 lines and owns exactly five fixtures.

Last completed slice:
Provider-capacity-pack extraction published as `19180691`: the exact
two-fixture family moved into a new 238-line leaf, the facade shrank from 4,949
to 4,721 lines, the 195-entry map and all deterministic digests stayed exact,
14 focused and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the contact-contention extraction described above, capture the exact
combined map and contiguous source boundary, then move the complete test-owned
family together.

Blocked:
No.
