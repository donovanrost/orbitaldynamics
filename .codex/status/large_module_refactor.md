# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation planning-input capability fixture test-family extraction.

Status:
Published as `3aa5fb12`.

Selected slice:
Move the three contiguous campaign-request lint, capability-catalog, and
environment-capability fixture tests into a focused module with one shared
planning-input fixture owner.

Why this slice:
After the candidate-state split, `validation_test.exs` is 5,145 lines. Tests
1,664-1,946 form a coherent planning-input capability family and end before
proposed-contact fixtures. Their twelve helpers form a complete JSON/runtime
capability closure; eight observation helpers remain deterministic aggregate
consumers, and the cluster owns every remaining parent `Environment` call.

Public facade to preserve:
`OrbitalDynamics.Validation.reference_fixture/1`,
`verify_reference_fixture/2`, `artifact_observations/2`, exact campaign lint,
capability catalog, and environment capability schema checks, runtime
capability coverage, and deterministic reports.

Likely files:
- `test/orbital_dynamics/validation_test.exs`
- `test/orbital_dynamics/validation/planning_input_fixture_test.exs`
- `test/support/validation/planning_input_fixtures.ex`
- `test/test_helper.exs`
- `.codex/status/large_module_refactor.md`

Likely verification:
- extracted planning-input capability fixture module directly
- remaining validation test ledger
- format, diff hygiene, and bounded review

Definition of done:
All three tests move mechanically with order and assertion strength unchanged;
shared builders have one exact owner, focused and parent files pass, names remain
unique, and bounded review finds no blocker.

Outcome:
Three byte-identical planning-input capability tests moved into a 298-line
focused module. Their twelve helpers now have one 85-line shared support owner
with an exact private JSON loader; the parent imports only the eight aggregate
observation builders and no longer owns `Environment`. The parent fell from
5,145 to 4,797 lines. Total test/support/loader LOC grew by 36 lines for
explicit ownership without helper duplication. All 181 Validation test names
remain unique.

Verification gaps:
- Full repository suite not run; this is a test-only ownership extraction.

Last completed slice:
Validation planning-input capability extraction published as `3aa5fb12`: the
focused module passed 3/3, the parent passed 37/37, and all thirty-seven
Validation modules preserved the 181-test aggregate with no duplicate names.
Format, diff hygiene, exact-source and dependency-closure checks, and bounded
review were clean.

Next candidate:
Map the proposed-contact, branch-comparison, optimizer-contract,
invalidated-candidate, strategy-branch, and strategy-recommendation fixtures
following planning inputs. The six contiguous tests and twelve raw/observation
helpers form one candidate-strategy artifact family ending before benchmarks.

Blocked:
No.
