# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema shared activity callback ownership mapping.

Status:
Ready for publication.

Selected slice:
Point both callback-bag captures of `validate_activity/3` directly at
`Schema.ActivityContracts.validate/3`: the campaign-plan and campaign-repair
bags. Remove the pure facade delegate while preserving keys and ordering.

Why this slice:
`Schema` remains a named 7,918-line production hotspot. Live inspection
corrected the prior shorthand: there are two runtime captures plus the wrapper
definition. The established owner exposes the exact `/3` implementation.

Current coupling/problem:
Both campaign validators route nested activity rows through a pure facade
wrapper even though their callback contract matches the established owner.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, callback keys and list ordering,
exact validation issue ordering, paths and messages, JSON Schema output,
checked-in export bytes, and campaign activity behavior.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The campaign-plan bag retains `validate_activity` between `validate_rows` and
`validate_proposed_contact`; the campaign-repair bag retains it between
`validate_optional_rows` and `validate_contact_intent`; both capture
`ActivityContracts.validate/3`; the wrapper is gone; tests, schema bytes, and
review remain clean.

Verification gaps:
None.

Tests run:
- Source baseline: two callback captures and one pure wrapper definition.
- Campaign-plan consumes the callback for both `activities` and
  `candidate_activities`; campaign-repair consumes it for `activities`.
- Focused communications plus campaign-repair/strategy baseline: 10 tests
  passed with warnings as errors.
- Generated 121-schema bundle: 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Source proof against `70e93873`: both callback keys retain their exact
  neighboring positions, capture `ActivityContracts.validate/3`, and the
  facade wrapper is absent.
- Focused communications and repair/strategy tests: 10 passed; complete
  schema/export tests: 182 passed, all with warnings as errors.
- Generated bundle remains 121 schemas, 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Full export regeneration produced no schema diff; checked digest remains
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.
- Strict compile, format, xref, and diff hygiene passed.
- Independent review against `70e93873` was clean: callback positions, owner
  and wrapper state, focused 10, complete 182, all 122 export bytes, digests,
  strict compile, xref, formatting, sizes, ledger, and hygiene passed.

Behavior/schema changes:
None.

Outcome:
Both callback bags reference the established owner directly and the pure
wrapper is gone. `schema.ex` decreased from 7,918 to 7,910 lines.

Last completed slice:
Candidate-activity cleanup published as `07c7cf82`: `schema.ex` shrank from
7,926 to 7,918 lines, 10 focused and 182 complete tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
After review and publication, map the next pure facade delegate by exact caller
count, owner signature, and issue-order sensitivity.

Blocked:
No.
