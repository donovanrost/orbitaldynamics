# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema realized-activity callback ownership mapping.

Status:
Ready for implementation.

Selected slice:
Point the standalone `realized_activity.v1` pipe directly at
`Schema.RealizedActivityContracts.validate/3`. Remove the pure facade delegate
while preserving its final position and issue ordering.

Why this slice:
`Schema` remains a 7,910-line production hotspot. The established owner exposes
the exact `/3` implementation and the delegate has exactly one caller.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact issue ordering, paths and
messages, JSON Schema output, checked-in export bytes, and realized-activity
behavior.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The pipe retains `require_fields`, calls the established owner in the same final
position, the delegate is gone, behavior and schema bytes remain exact, focused
and complete tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and post-change verification pending.

Tests run:
- Source baseline: one final pipe call and one pure delegate definition.
- Focused `contact_feedback_contracts_test.exs`: 5 tests passed with warnings as
  errors.
- Generated 121-schema bundle: 15,506,740 bytes, digest
  `543dbe11bc75f1397dd15dbd10cabd219ae2e46ac1e16d38b810a99befb8cec3`.
- Checked bundle digest:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`.

Behavior/schema changes:
None.

Outcome:
No realized-activity callback implementation has started.

Last completed slice:
Shared activity cleanup published as `3184d18f`: `schema.ex` shrank from 7,918
to 7,910 lines, 10 focused and 182 complete tests passed, all 122 exports
byte-matched, and bounded review was clean.

Next candidate:
Implement the direct owner substitution and remove the unused delegate.

Blocked:
No.
