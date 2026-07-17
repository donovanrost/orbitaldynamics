# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy-escalation ownership handoff.

Status:
Published as `109c7d4b`.

Selected slice:
Point the `%{}` branch of optional policy-escalation validation directly at
`Schema.PolicyEscalationContracts.validate/3` and remove the pure wrapper.

Why this slice:
`Schema` remains a 7,798-line hotspot. Structural mapping confirms one runtime
call plus one pure exact-signature delegate; a similarly named handoff matcher
is distinct and remains untouched.

Public facade to preserve:
All Schema APIs, nil/map/invalid optional-field branching, exact issues/messages,
JSON Schema and checked exports, and policy-escalation behavior.

Definition of done:
Nil still returns existing issues, `%{}` calls the owner with the same computed
path, invalid values retain the same error, wrapper is absent, and all proof and
review remains exact.

Verification gaps:
None.

Tests run:
- Source baseline: one `%{}` branch call and one pure delegate.
- Focused `policy_contracts_test.exs`: 1 test passed with warnings as errors.
- Generated bundle: 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `7289efcf`: nil and invalid branches are unchanged, the
  `%{}` branch calls `PolicyEscalationContracts.validate/3` with the same path,
  and wrapper is absent.
- Focused policy test: 1 passed; complete schema/export suite: 182 passed, all
  with warnings as errors.
- Generated bundle remains exact; export regeneration produced no schema diff
  and checked digest is unchanged.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `7289efcf` was clean across all optional branches,
  distinct handoff state, focused 1, complete 182, all 122 exports, digests,
  strict compile, xref, formatting, sizes, ledger, and hygiene.

Behavior/schema changes:
None.

Outcome:
The map branch calls the established owner directly and wrapper is gone.
`schema.ex` decreased from 7,798 to 7,794 lines.

Last completed slice:
Station-calendar contact-count cleanup published as `67180b1a`: `schema.ex`
shrank from 7,805 to 7,798 lines, focused 8 and complete 182 tests passed, all
122 exports byte-matched, and review was clean.

Next candidate:
Refresh the live repository hotspot inventory and private/public function counts.
The remaining exact wrappers are multi-consumer boundaries across several
families, so choose the next responsibility-focused extraction from current
module/test sizes rather than continuing wrapper removal solely for line count.

Blocked:
No.
