# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation timeline preservation fixture test-family extraction.

Status:
Verified and reviewed; ready to publish.

Selected slice:
Move the six contiguous timeline preservation-report, preservation-status,
integrity-report, dependency-impact-summary, diff-summary, and
publication-summary fixture tests into a focused module with one shared builder
owner.

Why this slice:
After the timeline activity-state split, `validation_test.exs` is 14,716 lines.
Tests 6,550-7,059 form a coherent preservation-to-publication evidence chain
and end before transition-application fixtures. Their twelve observation/raw
builders and two generated-artifact builders form one closure; only observation
builders remain needed by the deterministic aggregate.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact preservation,
integrity, dependency, publication, stale-data coverage, and deterministic
reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/timeline_preservation_fixture_test.exs`
- `test/support/validation/timeline_preservation_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted timeline preservation fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All six tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Six byte-identical timeline preservation family tests moved into a 533-line
focused module. Fourteen observation/raw/generated builders now have one
136-line shared support owner; the parent imports only the six aggregate
observation builders, with no private residue. The parent fell from 14,716 to
14,091 lines. Total test/support/loader LOC grew by 45 lines for explicit
ownership without helper duplication. All 181 Validation test names remain
unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation timeline activity-state fixture extraction published as `f12dc48c`:
the focused module passed 6/6, the parent passed 121/121, and all eleven
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent timeline transition-application fixture cluster in the
14,091-line parent. Select only a coherent multi-test boundary and move shared
builders to one support owner rather than copying them.

Blocked:
No.
