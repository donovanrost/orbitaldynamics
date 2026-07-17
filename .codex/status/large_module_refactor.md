# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Capability-catalog fixture mapping.

Status:
Publishing.

Selected slice:
Move the sole remaining `capability_catalog.v1` fixture together with its
private candidate-refresh source-report ordering attribute into a new
`Validation.ReferenceFixtures.CapabilityCatalogArtifacts` leaf. Preserve the
alias block, `@all_fixtures` merge chain, and complete 194-fixture remainder
exactly.

Why this slice:
`ReferenceFixtures` is now a 235-line facade with one remaining fixture and one
private attribute used only by that fixture. Moving both completes the
facade-state extraction and leaves registry composition plus `all/0` and
`fetch/1` as its only responsibilities.

Current coupling/problem:
Public capability-catalog counts and candidate-refresh source-report ordering
remain embedded in the registry facade. They form one self-contained artifact
contract and do not belong in the environment- or subsystem-specific
capability leaves.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CapabilityCatalogArtifacts`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/capability_catalog_artifacts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused quality-gate and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The capability-catalog fixture and its private ordering attribute exist only in
the new cohesive leaf, all 48 leaf maps remain disjoint, the facade contains no
fixture literals or private fixture data, `all/0` and `fetch/1` return exactly
the same 195-entry map and deterministic term bytes, the complete 194-fixture
remainder stays exact, focused and full validation tests pass, and bounded
review finds no blocker.

Verification gaps:
None.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected one-fixture map: deterministic digest
  `6a6a01be9d672d9a9850cc95fede2df801a68852affeb122d0fd1c516978e1d2`.
- Exact 194-entry remainder: deterministic digest
  `121e19ea8bc9fab732527e90d98ccbc284632a3f9ed609ced6532d91e1ad1759`.
- Source boundary confirmed across facade lines 52-181, after the complete
  alias block and before `@all_fixtures`. The private
  `@candidate_refresh_source_report_input_order` attribute has exactly two
  source occurrences: its definition and its use inside the selected fixture.
- Focused capability-catalog/facade selection baseline: 5 tests passed with
  warnings as errors.
- Normalized-AST proof against selection commit `a3b2e2a1`: the fixture map and
  private ordering attribute are exact in the new leaf; the facade owns neither
  attribute, contains no fixture literal, and its merge-module order is exact
  after replacing the final `@fixtures` merge with
  `CapabilityCatalogArtifacts.all/0`.
- Post-move exact proof: the 195-entry map, sorted-key digest, selected
  one-fixture digest, and exact 194-entry remainder digest all match their
  selection baselines.
- Source partition proof: 48 leaf maps total 195 entries, the new leaf owns one,
  all 1,128 pairwise intersections are empty, and the 195 unique source keys
  exactly match the runtime map.
- Facade proof: all 195 successful `fetch/1` results, missing-key `:error`, and
  nonbinary `FunctionClauseError` behavior remain unchanged; no fixture literal,
  `@fixtures`, or private ordering attribute remains in the facade.
- Focused capability-catalog/facade validation: 5 tests passed with warnings as
  errors.
- Full validation family: 181 tests passed with warnings as errors.
- Strict test compile, `mix format --check-formatted`, `git diff --check`, and
  xref caller checks passed.
- Initial bounded review found that the new leaf merge had been inserted
  alphabetically instead of at the former final `@fixtures` position. The
  merge was moved to the exact former position; merge-order proof, all four
  digests, focused 5-test validation, full 181-test validation, xref,
  formatting, and diff hygiene passed again.
- Independent re-review against selection commit `a3b2e2a1` was clean: the
  corrected merge order, normalized fixture and attribute AST, facade-state
  removal, all deterministic digests, 48-map source partition, facade behavior,
  one-way xref dependency, sizes, rerun tests, and hygiene all matched the
  recorded evidence.

Behavior/schema changes:
None.

Outcome:
The exact capability-catalog fixture and its private ordering attribute now
live in a dedicated cohesive leaf behind the unchanged facade. The facade
shrunk from 235 to 105 lines and contains only aliases, registry composition,
`all/0`, and `fetch/1`; the new leaf is 136 lines and owns exactly one fixture.

Last completed slice:
Station-reservation extraction published as `7e53ba2c`: the exact 12-fixture
workflow moved into a new 822-line leaf, the facade shrank from 1,047 to 235
lines, the 195-entry map and all deterministic digests stayed exact, 11 focused
and 181 full validation tests passed, and bounded review was clean.

Next candidate:
Select the capability-catalog extraction described above, preserve the exact
alias and merge-chain boundaries, then remove the final fixture state from the
facade.

Blocked:
No.
