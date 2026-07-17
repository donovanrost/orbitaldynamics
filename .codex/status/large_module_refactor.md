# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation-reference-report ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Move
`validation_reference_report.v1` into the existing
`Validation.ReferenceFixtures.CoreRunReports` leaf. Preserve its
`validation_record.v1` and `validation_check.v1` neighbors exactly.

Why this slice:
`ReferenceFixtures` remains the largest production module at 7,620 lines. The
36-line validation-reference report is tested in
`core_run_report_fixture_test.exs` with the four fixtures already in
`CoreRunReports`.

Current coupling/problem:
One core-run report remains separated from its test-owned family and interrupts
the otherwise cohesive policy-evidence fixture range. Moving it into the
existing leaf fixes ownership without creating a micro-module and unlocks the
next family extraction.

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
- focused core-run-report, policy-evidence, and facade validation tests
- full validation test family
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The validation-reference fixture exists only in the core-run leaf, all 27
fixture maps remain disjoint, `all/0` and `fetch/1` return exactly the same
195-entry map and deterministic term bytes, both neighboring policy-evidence
fixtures and the complete facade remainder stay exact, focused and full
validation tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation, verification, and bounded review pending.

Tests run:
- Selection baseline: 195 entries, deterministic map digest
  `a94507226596cd944ac21994c7889549ec58ecd1fcc0db5c65fa4e55b0f53ef2`,
  and sorted-key digest
  `b0007d04e4154fe879519a4f2b074fe3f9d0d649f3049d5d848264e105d00732`.
- Selected validation-reference map: deterministic digest
  `714d1b43e9fff5efe077a1ee3e801993e01c6dc1a3d1102aa62d0c344963f4c0`.
- Exact 194-entry remainder: deterministic digest
  `356261c8e7c41aba9283fb8a69c5962867c66423b8f203f58d0a80afb16a6e2b`.
- Existing four-fixture core-run leaf: deterministic digest
  `2cef307fc4eb09c6c54536f8a0a8cb78c7613ab5295572862a58931f3b5bca6a`.
- Source boundary confirmed at facade lines 275-310, between
  `validation_record.v1` and `validation_check.v1`, with no facade
  helper-attribute dependency in the selected literal.
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Outcome:
No validation-reference ownership implementation has started.

Last completed slice:
State/maneuver extraction published as `903b1fcd`: the exact five-fixture family
moved into a new 216-line leaf, the facade shrank from 7,826 to 7,620 lines, the
195-entry map and all deterministic digests stayed exact, 17 focused and 181
full validation tests passed, and bounded review was clean.

Next candidate:
Select the validation-reference ownership cleanup described above, capture the
exact baseline and both neighboring boundaries, then move it into
`CoreRunReports`.

Blocked:
No.
