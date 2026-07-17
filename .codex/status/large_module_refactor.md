# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation provider capacity-pack fixture test-family extraction.

Status:
Published as `94b5578b`.

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
Two byte-identical provider capacity-pack family tests moved into a 340-line
focused module. Four observation/raw builders now have one 31-line shared
support owner; the parent imports only the two aggregate observation builders,
with no private residue. The direct-JSON contact summary tests and their
aggregate helpers remain in the parent. The parent fell from 12,943 to 12,602
lines. Total test/support/loader LOC grew by 31 lines for explicit ownership
without helper duplication. All 181 Validation test names remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation provider capacity-pack fixture extraction published as `94b5578b`:
the focused module passed 2/2, the parent passed 103/103, and all sixteen
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, dependency-closure checks, and bounded review were clean.

Next candidate:
Refresh the adjacent contact-filter, contention, and contention-resolution
fixture cluster in the 12,602-line parent. Select only a coherent multi-test
boundary and move shared builders to one support owner rather than copying
them.

Blocked:
No.
