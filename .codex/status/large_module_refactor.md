# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Core-run report reference-fixture extraction.

Status:
Ready for implementation.

Selected slice:
Move the contiguous candidate-diff, refresh-budget, execution, and freshness
report fixtures into `Validation.ReferenceFixtures.CoreRunReports`. Stop before
`manifest_field_reference.v1` and merge the new family behind unchanged
`ReferenceFixtures.all/0` and `fetch/1`.

Why this slice:
`ReferenceFixtures` remains the largest production module at 9,834 lines.
These four fixtures form one contiguous 243-line core-run report family, and
every key has focused coverage in
`validation/core_run_report_fixture_test.exs`.

Current coupling/problem:
Four related run-state report fixtures remain embedded in the facade despite
shared core-run responsibility and focused test ownership. None references a
facade helper attribute; `@` characters in the block occur only inside literal
email-like map keys.

Public facade to preserve:
`OrbitalDynamics.Validation.ReferenceFixtures.all/0` and `fetch/1`, exact
fixture keys and values, map equality and deterministic term bytes, and all
`OrbitalDynamics.Validation` reference-fixture behavior.

Likely extraction target:
`OrbitalDynamics.Validation.ReferenceFixtures.CoreRunReports`.

Likely files:
- `lib/orbital_dynamics/validation/reference_fixtures.ex`
- `lib/orbital_dynamics/validation/reference_fixtures/core_run_reports.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- exact before/after fixture count, keys, values, and deterministic term digest
- focused core-run report and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The four report fixtures exist only in the core-run family, all 18
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
Candidate-strategy fixture extraction published as `6e55724f`: the three exact
branch/optimizer/invalidation fixtures moved behind the unchanged facade,
candidate diff and the remainder stayed exact, the 195-entry map and
deterministic bytes stayed exact, 181 validation tests passed, and bounded
review was clean.

Next candidate:
After this boundary, map manifest-field-reference plus study-manifest-lint
against focused manifest fixture ownership before selecting the next family.

Blocked:
No.
