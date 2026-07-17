# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation planning-input capability fixture test-family extraction.

Status:
Selected.

Selected slice:
Move the three contiguous campaign-request lint, capability-catalog, and
environment-capability fixture tests into a focused module with one shared
planning-input fixture owner.

Why this slice:
After the candidate-state split, `validation_test.exs` is 5,145 lines. Tests
1,664-1,946 form a coherent planning-input capability family and end before
proposed-contact fixtures. Their eleven helpers form a complete JSON/runtime
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
Pending.

Verification gaps:
- Pending.

Last completed slice:
Validation candidate-state artifact extraction published as `386d94aa`: the
focused module passed 5/5, the parent passed 40/40, and all thirty-six Validation
modules preserved the 181-test aggregate with no duplicate names. Format, diff
hygiene, exact-source and dependency-closure checks, and bounded review were
clean.

Next candidate:
Map the proposed-contact and branch-comparison fixture families following
planning inputs. Split only a coherent artifact family with complete helper
closure.

Blocked:
No.
