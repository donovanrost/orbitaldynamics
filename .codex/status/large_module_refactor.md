# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation provider capacity-pack fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the two contiguous provider-reservation request summary and
reduced-capacity contact-allocation pack fixture tests into a focused module
with one shared builder owner.

Why this slice:
After the operational planning split, `validation_test.exs` is 12,943 lines.
Tests 7,103-7,429 form a coherent provider-request-to-capacity-pack family and
end before contact-filter fixtures. Their four observation/raw builders form
one closure; only observation builders remain needed by the deterministic
aggregate. The preceding summary tests are excluded because they load JSON
directly while separate aggregate-only observation helpers remain in the
parent.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact provider request,
reduced-capacity pack, stale-data coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/provider_capacity_pack_fixture_test.exs`
- `test/support/validation/provider_capacity_pack_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted provider capacity-pack fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
Both tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation operational planning fixture extraction published as `4c26b4e7`:
the focused module passed 3/3, the parent passed 105/105, and all fifteen
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent contact-allocation, reservation-conflict, station-pressure,
and capacity-summary fixture cluster in the 12,943-line parent. Select only a
coherent multi-test boundary and move shared builders to one support owner
rather than copying them.

Blocked:
No.
